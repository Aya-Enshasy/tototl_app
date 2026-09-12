import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/storage/user_session_storage.dart';
import '../../../../core/theme/app_colors.dart';
import '../../controllers/company_job_controller.dart';
import '../../models/company_job_application_model.dart';
import '../../services/company_job_service.dart';
import 'company_document_viewer_screen.dart';

class CompanyApplicantDetailScreen extends StatefulWidget {
  const CompanyApplicantDetailScreen({
    super.key,
    required this.jobId,
    required this.application,
  });

  final int jobId;
  final CompanyJobApplicationModel application;

  @override
  State<CompanyApplicantDetailScreen> createState() =>
      _CompanyApplicantDetailScreenState();
}

class _CompanyApplicantDetailScreenState
    extends State<CompanyApplicantDetailScreen> {
  static const FlutterSecureStorage _storage = FlutterSecureStorage();
  static const String _cachePrefix = 'company_applicant_detail_v5_';

  late final CompanyJobController _controller;
  late CompanyJobApplicationModel _application;

  CompanyApplicantPilotModel? _pilot;
  CompanyApplicantDroneModel? _committedDrone;
  List<CompanyPilotCredentialModel> _credentials = const [];

  String? _cacheKey;
  String? _backgroundError;
  int? _openingMediaId;

  bool _changed = false;
  bool _backgroundRefreshing = false;
  bool _cacheReadFinished = false;
  bool _supportLoadedOnce = false;

  bool get _acting =>
      _controller.isAcceptingApplicant ||
          _controller.isRejectingApplicant;

  bool get _supportLoading =>
      _controller.isLoadingApplicantPilotProfile ||
          _controller.isLoadingApplicantCredentials ||
          _controller.isLoadingApplicantDrones;

  @override
  void initState() {
    super.initState();

    _controller = CompanyJobController(
      CompanyJobService(ApiClient()),
    );

    _application = widget.application;
    _pilot = widget.application.pilotProfile;
    _committedDrone = widget.application.drone;

    unawaited(_bootstrap());
  }

  Future<void> _bootstrap() async {
    await _loadCache();
    if (!mounted) return;
    unawaited(_refreshInBackground());
  }

  // ==========================================================================
  // LOCAL-FIRST CACHE
  // ==========================================================================

  Future<void> _loadCache() async {
    try {
      final userId = await UserSessionStorage.getUserId();
      if (userId == null) {
        if (!mounted) return;
        setState(() => _cacheReadFinished = true);
        return;
      }

      _cacheKey =
      '$_cachePrefix${userId}_${widget.jobId}_${widget.application.id}';

      final raw = await _storage.read(key: _cacheKey!);
      if (raw == null || raw.trim().isEmpty) {
        if (!mounted) return;
        setState(() => _cacheReadFinished = true);
        unawaited(_saveCache());
        return;
      }

      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        final map = Map<String, dynamic>.from(decoded);

        final cachedApplication = map['application'];
        final cachedCredentials = map['credentials'];

        CompanyApplicantPilotModel? cachedPilot;
        CompanyApplicantDroneModel? cachedDrone;
        List<CompanyPilotCredentialModel> cachedCredentialModels = const [];

        if (cachedApplication is Map) {
          final cached = CompanyJobApplicationModel.fromJson(
            Map<String, dynamic>.from(cachedApplication),
          );
          cachedPilot = cached.pilotProfile;
          cachedDrone = cached.drone;
        }

        if (cachedCredentials is List) {
          cachedCredentialModels = cachedCredentials
              .whereType<Map>()
              .map(
                (item) => CompanyPilotCredentialModel.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
              .toList(growable: false);
        }

        if (!mounted) return;
        setState(() {
          if (cachedPilot != null) {
            _pilot = _pilot == null
                ? cachedPilot
                : _pilot!.mergeWith(cachedPilot);
          }

          if (cachedDrone != null) {
            _committedDrone = _preferRicherDrone(
              current: _committedDrone,
              incoming: cachedDrone,
            );
          }

          if (cachedCredentialModels.isNotEmpty) {
            _credentials = cachedCredentialModels;
          }

          _cacheReadFinished = true;
        });
        return;
      }
    } catch (_) {
      // Keep the application passed from the previous screen visible.
    }

    if (!mounted) return;
    setState(() => _cacheReadFinished = true);
  }

  Future<void> _saveCache() async {
    final key = _cacheKey;
    if (key == null) return;

    try {
      final enrichedApplication = _application.copyWith(
        pilotProfile: _pilot,
        drone: _committedDrone,
      );

      await _storage.write(
        key: key,
        value: jsonEncode({
          'version': 5,
          'saved_at': DateTime.now().toIso8601String(),
          'application': enrichedApplication.toJson(),
          'credentials': _credentials.map((item) => item.toJson()).toList(),
        }),
      );
    } catch (_) {}
  }

  // ==========================================================================
  // BACKGROUND REFRESH
  // ==========================================================================

  Future<void> _refreshInBackground() async {
    if (_backgroundRefreshing) return;

    _backgroundRefreshing = true;
    if (mounted) {
      setState(() => _backgroundError = null);
    }

    final applicationFuture = _controller.loadApplicants(widget.jobId);
    final pilotFuture = _controller.loadApplicantPilotProfile(
      _application.pilotProfileId,
    );
    final credentialFuture = _controller.loadApplicantCredentials(
      _application.pilotProfileId,
    );
    final droneFuture = _controller.loadApplicantDrones(
      pilotProfileId: _application.pilotProfileId,
      committedDroneId: _application.droneId,
    );

    final results = await Future.wait<bool>([
      applicationFuture,
      pilotFuture,
      credentialFuture,
      droneFuture,
    ]);

    if (!mounted) return;

    final applicationSuccess = results[0];
    final pilotSuccess = results[1];
    final credentialsSuccess = results[2];
    final dronesSuccess = results[3];

    CompanyJobApplicationModel? freshApplication;
    if (applicationSuccess) {
      for (final item in _controller.applicants) {
        if (item.id == _application.id) {
          freshApplication = item;
          break;
        }
      }
    }

    final freshPilot = pilotSuccess
        ? _controller.applicantPilotProfile
        : null;
    final nestedPilot = freshApplication?.pilotProfile;

    CompanyApplicantPilotModel? resolvedPilot = _pilot;
    if (nestedPilot != null) {
      resolvedPilot = resolvedPilot == null
          ? nestedPilot
          : resolvedPilot.mergeWith(nestedPilot);
    }
    if (freshPilot != null) {
      resolvedPilot = resolvedPilot == null
          ? freshPilot
          : resolvedPilot.mergeWith(freshPilot);
    }

    final nestedDrone = freshApplication?.drone;
    final fullCommittedDrone = dronesSuccess
        ? _controller.committedApplicantDrone
        : null;

    var resolvedDrone = _preferRicherDrone(
      current: _committedDrone,
      incoming: nestedDrone,
    );
    resolvedDrone = _preferRicherDrone(
      current: resolvedDrone,
      incoming: fullCommittedDrone,
    );

    final errorParts = <String>[];
    if (!applicationSuccess) {
      final value = _controller.applicantsErrorMessage?.trim() ?? '';
      if (value.isNotEmpty) errorParts.add(value);
    }
    if (!pilotSuccess && resolvedPilot == null) {
      final value =
          _controller.applicantPilotProfileErrorMessage?.trim() ?? '';
      if (value.isNotEmpty) errorParts.add(value);
    }
    if (!credentialsSuccess && _credentials.isEmpty) {
      final value =
          _controller.applicantCredentialsErrorMessage?.trim() ?? '';
      if (value.isNotEmpty) errorParts.add(value);
    }
    if (!dronesSuccess && resolvedDrone == null) {
      final value = _controller.applicantDronesErrorMessage?.trim() ?? '';
      if (value.isNotEmpty) errorParts.add(value);
    }

    setState(() {
      if (freshApplication != null) {
        _application = freshApplication!.copyWith(
          pilotProfile: resolvedPilot,
          drone: resolvedDrone,
        );
      } else {
        _application = _application.copyWith(
          pilotProfile: resolvedPilot,
          drone: resolvedDrone,
        );
      }

      _pilot = resolvedPilot;
      _committedDrone = resolvedDrone;

      if (credentialsSuccess) {
        _credentials = _controller.applicantCredentials;
      }

      _backgroundError = errorParts.isEmpty
          ? null
          : 'Some applicant details could not be refreshed.';
    });

    _backgroundRefreshing = false;
    _supportLoadedOnce = true;
    unawaited(_saveCache());

    if (mounted) setState(() {});
  }

  CompanyApplicantDroneModel? _preferRicherDrone({
    required CompanyApplicantDroneModel? current,
    required CompanyApplicantDroneModel? incoming,
  }) {
    if (incoming == null) return current;
    if (current == null) return incoming;

    final currentScore = _droneRichness(current);
    final incomingScore = _droneRichness(incoming);
    return incomingScore >= currentScore ? incoming : current;
  }

  int _droneRichness(CompanyApplicantDroneModel drone) {
    var score = 0;
    if (drone.imageUrl.isNotEmpty) score += 4;
    if (drone.capabilities.isNotEmpty) score += 2;
    if (drone.flightTimePerBatteryMinutes != null) score++;
    if (drone.chargingTimeMinutes != null) score++;
    if (drone.batteryType.isNotEmpty) score++;
    if (drone.serialNumber.isNotEmpty) score++;
    return score;
  }

  // ==========================================================================
  // APPLICATION ACTIONS
  // ==========================================================================

  Future<void> _accept() async {
    if (!_application.isPending || _acting) return;

    final confirmed = await _confirmDialog(
      title: 'Accept Applicant?',
      message:
      'Accept ${_pilotName()} for this job? The application will move to Accepted.',
      confirmText: 'Accept',
      icon: Icons.check_circle_outline_rounded,
    );

    if (confirmed != true || !mounted) return;

    HapticFeedback.mediumImpact();
    setState(() {});

    final updated = await _controller.acceptApplicant(
      jobId: widget.jobId,
      application: _application.copyWith(
        pilotProfile: _pilot,
        drone: _committedDrone,
      ),
    );

    if (!mounted) return;

    if (updated == null) {
      setState(() {});
      _showSnack(
        _controller.applicantsErrorMessage ??
            'Unable to accept applicant.',
        isError: true,
      );
      return;
    }

    setState(() {
      _application = updated.copyWith(
        pilotProfile: _pilot,
        drone: _committedDrone,
      );
      _changed = true;
    });

    unawaited(_saveCache());
    _showSnack('Applicant accepted successfully.');
  }

  Future<void> _reject() async {
    if (!_application.isPending || _acting) return;

    final reason = await _showRejectDialog();
    if (reason == null || !mounted) return;

    HapticFeedback.mediumImpact();
    setState(() {});

    final updated = await _controller.rejectApplicant(
      jobId: widget.jobId,
      application: _application.copyWith(
        pilotProfile: _pilot,
        drone: _committedDrone,
      ),
      reason: reason.trim().isEmpty ? null : reason.trim(),
    );

    if (!mounted) return;

    if (updated == null) {
      setState(() {});
      _showSnack(
        _controller.applicantsErrorMessage ??
            'Unable to reject applicant.',
        isError: true,
      );
      return;
    }

    setState(() {
      _application = updated.copyWith(
        pilotProfile: _pilot,
        drone: _committedDrone,
      );
      _changed = true;
    });

    unawaited(_saveCache());
    _showSnack('Applicant rejected.');
  }

  Future<bool?> _confirmDialog({
    required String title,
    required String message,
    required String confirmText,
    required IconData icon,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
          contentPadding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
          actionsPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
          title: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.greenBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 19,
                  color: AppColors.green,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.navy,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            message,
            style: const TextStyle(
              color: AppColors.grey,
              fontSize: 12.2,
              height: 1.45,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.green,
              ),
              child: Text(confirmText),
            ),
          ],
        );
      },
    );
  }

  Future<String?> _showRejectDialog() async {
    String draftReason = '';

    return showDialog<String?>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: const Text(
            'Reject Applicant?',
            style: TextStyle(
              color: AppColors.navy,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'You can add a rejection reason or leave it empty.',
                style: TextStyle(
                  color: AppColors.grey,
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 13),
              TextField(
                maxLength: 2000,
                minLines: 3,
                maxLines: 6,
                textCapitalization: TextCapitalization.sentences,
                onChanged: (value) => draftReason = value,
                style: const TextStyle(fontSize: 12.5),
                decoration: InputDecoration(
                  hintText: 'Optional rejection reason...',
                  filled: true,
                  fillColor: AppColors.bg,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                      color: AppColors.cardBorder,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                      color: AppColors.cardBorder,
                    ),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.of(dialogContext).pop(draftReason.trim()),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red.shade700,
              ),
              child: const Text('Reject'),
            ),
          ],
        );
      },
    );
  }

  // ==========================================================================
  // PRIVATE DOCUMENT PREVIEW
  // ==========================================================================

  Future<void> _openDocument(CompanyPilotMediaModel document) async {
    if (_openingMediaId != null) return;

    HapticFeedback.selectionClick();
    setState(() => _openingMediaId = document.id);

    try {
      final path = await _controller.downloadApplicantDocument(
        document: document,
      );

      if (!mounted) return;

      if (path == null || path.trim().isEmpty) {
        _showSnack(
          _controller.applicantDocumentErrorMessage ??
              'Unable to open this document.',
          isError: true,
        );
        return;
      }

      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => CompanyDocumentViewerScreen(
            filePath: path,
            fileName: document.fileName.trim().isEmpty
                ? 'document_${document.id}'
                : document.fileName.trim(),
            mimeType: document.mimeType,
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _openingMediaId = null);
      }
    }
  }

  // ==========================================================================
  // BUILD
  // ==========================================================================

  @override
  Widget build(BuildContext context) {
    final hasImmediateData = _cacheReadFinished ||
        _pilot != null ||
        _committedDrone != null ||
        widget.application.id > 0;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        children: [
          const _ApplicantBackground(),
          SafeArea(
            child: !hasImmediateData
                ? const _ApplicantDetailShimmer()
                : Column(
              children: [
                _topBar(),
                Expanded(
                  child: RefreshIndicator(
                    color: AppColors.blue,
                    backgroundColor: Colors.white,
                    onRefresh: _refreshInBackground,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      padding: const EdgeInsets.fromLTRB(
                        16,
                        8,
                        16,
                        28,
                      ),
                      children: [
                        _hero(),
                        if (_backgroundError != null) ...[
                          const SizedBox(height: 9),
                          _OfflineNotice(
                            message: _backgroundError!,
                            onRetry: _refreshInBackground,
                          ),
                        ],
                        const SizedBox(height: 12),
                        _applicationInfo(),
                        const SizedBox(height: 12),
                        _pilotSection(),
                        const SizedBox(height: 12),
                        _credentialsSection(),
                        const SizedBox(height: 12),
                        _droneSection(),
                        if (_application.coverMessage.trim().isNotEmpty)
                          ...[
                            const SizedBox(height: 12),
                            _section(
                              title: 'Cover Message',
                              icon: Icons.chat_bubble_outline_rounded,
                              child: Text(
                                _application.coverMessage.trim(),
                                style: const TextStyle(
                                  color: AppColors.text,
                                  fontSize: 12.2,
                                  height: 1.55,
                                ),
                              ),
                            ),
                          ],
                        if (_application.rejectionReason.trim().isNotEmpty)
                          ...[
                            const SizedBox(height: 12),
                            _section(
                              title: 'Rejection Reason',
                              icon: Icons.info_outline_rounded,
                              accent: AppColors.red,
                              accentBackground: AppColors.redBg,
                              child: Text(
                                _application.rejectionReason.trim(),
                                style: const TextStyle(
                                  color: AppColors.text,
                                  fontSize: 12.2,
                                  height: 1.55,
                                ),
                              ),
                            ),
                          ],
                        if (_application.isAccepted) ...[
                          const SizedBox(height: 12),
                          _acceptedStateCard(),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar:
      _application.isPending ? _bottomActions() : null,
    );
  }

  Widget _topBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 7, 10, 5),
      child: Row(
        children: [
          Material(
            color: Colors.white,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => Navigator.of(context).pop(_changed),
              child: const SizedBox(
                width: 44,
                height: 44,
                child: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 17,
                  color: AppColors.navy,
                ),
              ),
            ),
          ),
          const Expanded(
            child: Text(
              'Applicant Details',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.navy,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          SizedBox(
            width: 44,
            height: 44,
            child: _backgroundRefreshing || _supportLoading
                ? const Center(child: _TinyPulse())
                : null,
          ),
        ],
      ),
    );
  }

  Widget _hero() {
    final visual = _applicationVisual(_application.status);
    final name = _pilotName();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF102A3A),
            Color(0xFF0D4757),
            Color(0xFF0D8AA5),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withOpacity(0.12),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _StatusBadge(
                label: _application.statusLabel,
                foreground: visual.foreground,
                background: visual.background,
              ),
              const Spacer(),
              Text(
                '#${_application.id}',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.62),
                  fontSize: 11.2,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 17),
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.13),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withOpacity(0.18),
                  ),
                ),
                child: CircleAvatar(
                  backgroundColor: Colors.white.withOpacity(0.10),
                  foregroundImage:
                  _pilot?.profilePhoto.trim().isNotEmpty == true
                      ? NetworkImage(_pilot!.profilePhoto.trim())
                      : null,
                  child: _pilot?.profilePhoto.trim().isNotEmpty == true
                      ? null
                      : Text(
                    _initials(name),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        if (_pilot?.verified == true) ...[
                          const SizedBox(width: 6),
                          const Icon(
                            Icons.verified_rounded,
                            color: Color(0xFF7BE4D8),
                            size: 15,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      _pilotHeroSubtitle(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.70),
                        fontSize: 11.4,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 17),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.09),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.assignment_turned_in_outlined,
                  size: 15,
                  color: Colors.white70,
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    'Application for Job #${_application.jobPostingId}',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 11.2,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (_backgroundRefreshing) const _HeroSyncBadge(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _applicationInfo() {
    return _section(
      title: 'Application',
      icon: Icons.assignment_outlined,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _MiniStat(
                  label: 'Application',
                  value: '#${_application.id}',
                  icon: Icons.tag_rounded,
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: _MiniStat(
                  label: 'Job',
                  value: '#${_application.jobPostingId}',
                  icon: Icons.work_outline_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _infoRow(
            'Submitted',
            _formatDateTime(_application.createdAt),
            Icons.schedule_rounded,
          ),
          if (_application.decidedAt != null)
            _infoRow(
              'Decision',
              _formatDateTime(_application.decidedAt),
              Icons.fact_check_outlined,
            ),
          if (_application.withdrawnAt != null)
            _infoRow(
              'Withdrawn',
              _formatDateTime(_application.withdrawnAt),
              Icons.undo_rounded,
            ),
        ],
      ),
    );
  }

  Widget _pilotSection() {
    final pilot = _pilot;

    if (pilot == null) {
      if (_supportLoading || _backgroundRefreshing) {
        return const _ShimmerAnimator(
          child: _DetailSectionShimmer(rows: 4),
        );
      }

      return _section(
        title: 'Pilot Profile',
        icon: Icons.person_outline_rounded,
        child: Text(
          'Pilot #${_application.pilotProfileId}',
          style: const TextStyle(
            color: AppColors.navy,
            fontSize: 12.3,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    }

    return _section(
      title: 'Pilot Profile',
      icon: Icons.person_outline_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _MiniStat(
                  label: 'Location',
                  value: pilot.location.isEmpty ? '—' : pilot.location,
                  icon: Icons.location_on_outlined,
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: _MiniStat(
                  label: 'Experience',
                  value: pilot.experienceLabel.isEmpty
                      ? '—'
                      : pilot.experienceLabel,
                  icon: Icons.timeline_rounded,
                ),
              ),
            ],
          ),
          if (pilot.nationality.isNotEmpty) ...[
            const SizedBox(height: 10),
            _infoRow(
              'Nationality',
              pilot.nationality,
              Icons.public_rounded,
            ),
          ],
          if (pilot.languages.isNotEmpty) ...[
            const SizedBox(height: 6),
            const _SubLabel('Languages'),
            const SizedBox(height: 7),
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: pilot.languages.map(_chip).toList(),
            ),
          ],
          if (pilot.bio.isNotEmpty) ...[
            const SizedBox(height: 13),
            const _SubLabel('About'),
            const SizedBox(height: 6),
            Text(
              pilot.bio,
              style: const TextStyle(
                color: AppColors.text,
                fontSize: 12.2,
                height: 1.5,
              ),
            ),
          ],
          if (pilot.previousCompany.isNotEmpty) ...[
            const SizedBox(height: 10),
            _infoRow(
              'Previous',
              pilot.previousCompany,
              Icons.business_center_outlined,
            ),
          ],
          if (pilot.linkedinUrl.isNotEmpty) ...[
            _infoRow(
              'LinkedIn',
              pilot.linkedinUrl,
              Icons.link_rounded,
            ),
          ],
          if (pilot.workRegions.isNotEmpty) ...[
            const SizedBox(height: 6),
            const _SubLabel('Available work regions'),
            const SizedBox(height: 7),
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: pilot.workRegions
                  .where((region) => region.label.isNotEmpty)
                  .take(6)
                  .map((region) => _chip(region.label))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _credentialsSection() {
    if (_credentials.isEmpty &&
        (!_supportLoadedOnce || _supportLoading || _backgroundRefreshing)) {
      return const _ShimmerAnimator(
        child: _CredentialSectionShimmer(),
      );
    }

    return _section(
      title: 'Credentials & Documents',
      icon: Icons.workspace_premium_outlined,
      child: _credentials.isEmpty
          ? const _EmptyInlineState(
        icon: Icons.badge_outlined,
        text: 'No pilot credentials were returned.',
      )
          : Column(
        children: List.generate(
          _credentials.length,
              (index) => Padding(
            padding: EdgeInsets.only(
              bottom: index == _credentials.length - 1 ? 0 : 10,
            ),
            child: _credentialCard(_credentials[index]),
          ),
        ),
      ),
    );
  }

  Widget _credentialCard(CompanyPilotCredentialModel credential) {
    final type = credential.licenseType.trim().isEmpty
        ? 'Credential #${credential.id}'
        : _pretty(credential.licenseType);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: credential.isExpired
                      ? AppColors.redBg
                      : AppColors.greenBg,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(
                  Icons.verified_user_outlined,
                  size: 18,
                  color: credential.isExpired
                      ? AppColors.red
                      : AppColors.green,
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      type,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.navy,
                        fontSize: 12.8,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      credential.isExpired
                          ? 'Expired'
                          : credential.expiresAt == null
                          ? 'Expiration not provided'
                          : 'Valid until ${_formatDate(credential.expiresAt)}',
                      style: TextStyle(
                        color: credential.isExpired
                            ? AppColors.red
                            : AppColors.grey,
                        fontSize: 10.6,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (credential.licenseNumber.isNotEmpty) ...[
            const SizedBox(height: 10),
            _compactInfoRow(
              'License number',
              credential.licenseNumber,
            ),
          ],
          if (credential.issuingAuthority.isNotEmpty)
            _compactInfoRow(
              'Authority',
              _pretty(credential.issuingAuthority),
            ),
          if (credential.expiresAt != null)
            _compactInfoRow(
              'Expires',
              _formatDate(credential.expiresAt),
            ),
          if (credential.media.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: credential.media.map(_documentButton).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _documentButton(CompanyPilotMediaModel document) {
    final busy = _openingMediaId == document.id;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(11),
      child: InkWell(
        borderRadius: BorderRadius.circular(11),
        onTap: _openingMediaId != null
            ? null
            : () => _openDocument(document),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(11),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (busy)
                const _TinyPulse()
              else
                Icon(
                  document.isPdf
                      ? Icons.picture_as_pdf_outlined
                      : Icons.image_outlined,
                  color: AppColors.blue,
                  size: 15,
                ),
              const SizedBox(width: 6),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 150),
                child: Text(
                  document.displayLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.navy,
                    fontSize: 10.6,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _droneSection() {
    final drone = _committedDrone;

    if (drone == null) {
      if (_supportLoading || _backgroundRefreshing) {
        return const _ShimmerAnimator(
          child: _DetailSectionShimmer(rows: 5),
        );
      }

      return _section(
        title: 'Committed Drone',
        icon: Icons.flight_outlined,
        child: Text(
          'Drone #${_application.droneId}',
          style: const TextStyle(
            color: AppColors.navy,
            fontSize: 12.3,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    }

    return _section(
      title: 'Committed Drone',
      icon: Icons.flight_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.greenBg,
                  AppColors.greenBg.withOpacity(0.45),
                ],
              ),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(13),
                  child: Container(
                    width: 54,
                    height: 54,
                    color: Colors.white,
                    child: drone.imageUrl.trim().isNotEmpty
                        ? Image.network(
                      drone.imageUrl.trim(),
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.flight_rounded,
                        color: AppColors.green,
                        size: 23,
                      ),
                    )
                        : const Icon(
                      Icons.flight_rounded,
                      color: AppColors.green,
                      size: 23,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        drone.displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.navy,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      if (drone.manufactureYear != null) ...[
                        const SizedBox(height: 3),
                        Text(
                          '${drone.manufactureYear}',
                          style: const TextStyle(
                            color: AppColors.grey,
                            fontSize: 10.8,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '#${drone.id}',
                    style: const TextStyle(
                      color: AppColors.green,
                      fontSize: 10.2,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (drone.capabilities.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: drone.capabilities
                  .map((value) => _chip(_pretty(value)))
                  .toList(),
            ),
          ],
          if (drone.serialNumber.isNotEmpty) ...[
            const SizedBox(height: 10),
            _infoRow(
              'Serial',
              drone.serialNumber,
              Icons.numbers_rounded,
            ),
          ],
          if (drone.weightKg != null)
            _infoRow(
              'Weight',
              '${_cleanNumber(drone.weightKg!)} kg',
              Icons.monitor_weight_outlined,
            ),
          if (drone.flightTimePerBatteryMinutes != null)
            _infoRow(
              'Flight time',
              '${drone.flightTimePerBatteryMinutes} min/battery',
              Icons.timer_outlined,
            ),
          if (drone.chargingTimeMinutes != null)
            _infoRow(
              'Charging',
              '${drone.chargingTimeMinutes} min',
              Icons.battery_charging_full_rounded,
            ),
          if (drone.totalBatteries != null)
            _infoRow(
              'Batteries',
              '${drone.totalBatteries}',
              Icons.battery_6_bar_rounded,
            ),
          if (drone.batteryType.isNotEmpty)
            _infoRow(
              'Battery type',
              drone.batteryType,
              Icons.battery_saver_outlined,
            ),
        ],
      ),
    );
  }

  Widget _acceptedStateCard() {
    return _section(
      title: 'Accepted Application',
      icon: Icons.handshake_outlined,
      accent: AppColors.green,
      accentBackground: AppColors.greenBg,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.greenBg.withOpacity(0.62),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.check_circle_rounded,
              color: AppColors.green,
              size: 18,
            ),
            SizedBox(width: 9),
            Expanded(
              child: Text(
                'This pilot has been selected for the job. Mission setup actions can be added here in the next workflow stage.',
                style: TextStyle(
                  color: AppColors.navy,
                  fontSize: 11.2,
                  height: 1.45,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================================
  // SHARED UI
  // ==========================================================================

  Widget _section({
    required String title,
    required IconData icon,
    required Widget child,
    Color accent = AppColors.blue,
    Color accentBackground = AppColors.blueBg,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withOpacity(0.022),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: accentBackground,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: accent,
                  size: 16,
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.navy,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          child,
        ],
      ),
    );
  }

  Widget _infoRow(
      String label,
      String value,
      IconData icon,
      ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: AppColors.blue,
            size: 15,
          ),
          const SizedBox(width: 7),
          SizedBox(
            width: 78,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.grey,
                fontSize: 11,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: AppColors.navy,
                fontSize: 11.6,
                fontWeight: FontWeight.w700,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _compactInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 92,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.grey,
                fontSize: 10.5,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: AppColors.navy,
                fontSize: 10.8,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String value) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: AppColors.blueBg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        value,
        style: const TextStyle(
          color: AppColors.blue,
          fontSize: 10.6,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _bottomActions() {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: const Border(
            top: BorderSide(color: AppColors.cardBorder),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.navy.withOpacity(0.06),
              blurRadius: 20,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_acting) ...[
              const _ActionLoadingBar(),
              const SizedBox(height: 9),
            ],
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _acting ? null : _reject,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 50),
                      foregroundColor: AppColors.red,
                      side: const BorderSide(color: AppColors.red),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: const Icon(
                      Icons.close_rounded,
                      size: 18,
                    ),
                    label: const Text(
                      'Reject',
                      style: TextStyle(
                        fontSize: 12.3,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _acting ? null : _accept,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 50),
                      backgroundColor: AppColors.green,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: const Icon(
                      Icons.check_rounded,
                      size: 18,
                    ),
                    label: const Text(
                      'Accept',
                      style: TextStyle(
                        fontSize: 12.3,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================================
  // HELPERS
  // ==========================================================================

  String _pilotName() {
    final pilot = _pilot;
    if (pilot != null && pilot.name.trim().isNotEmpty) {
      return pilot.name.trim();
    }
    return 'Pilot #${_application.pilotProfileId}';
  }

  String _pilotHeroSubtitle() {
    final pilot = _pilot;
    if (pilot == null) {
      return 'Pilot profile #${_application.pilotProfileId}';
    }

    final parts = <String>[];
    if (pilot.location.isNotEmpty) parts.add(pilot.location);
    if (pilot.experienceLabel.isNotEmpty) {
      parts.add(pilot.experienceLabel);
    }

    return parts.isEmpty
        ? 'Pilot profile #${pilot.id}'
        : parts.join(' · ');
  }

  String _formatDateTime(DateTime? value) {
    if (value == null) return '—';
    final local = value.toLocal();
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '${local.year}-$month-$day · $hour:$minute';
  }

  String _formatDate(DateTime? value) {
    if (value == null) return '—';
    final local = value.toLocal();
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    return '${local.year}-$month-$day';
  }

  String _cleanNumber(double value) {
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }
    return value.toStringAsFixed(2);
  }

  void _showSnack(
      String message, {
        bool isError = false,
      }) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor:
          isError ? Colors.red.shade700 : AppColors.navy,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          margin: const EdgeInsets.all(16),
          content: Text(
            message,
            style: const TextStyle(fontSize: 11.5),
          ),
        ),
      );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 80),
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: AppColors.blue,
            size: 15,
          ),
          const SizedBox(height: 7),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.grey,
              fontSize: 10.4,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.navy,
              fontSize: 11.7,
              fontWeight: FontWeight.w800,
              height: 1.25,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({
    required this.label,
    required this.foreground,
    required this.background,
  });

  final String label;
  final Color foreground;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: foreground,
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _SubLabel extends StatelessWidget {
  const _SubLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.grey,
        fontSize: 10.8,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _EmptyInlineState extends StatelessWidget {
  const _EmptyInlineState({
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: AppColors.grey,
            size: 17,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AppColors.grey,
                fontSize: 11,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroSyncBadge extends StatelessWidget {
  const _HeroSyncBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        shape: BoxShape.circle,
      ),
      child: const _TinyPulse(),
    );
  }
}

class _OfflineNotice extends StatelessWidget {
  const _OfflineNotice({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: AppColors.orangeBg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.cloud_off_outlined,
            color: AppColors.orange,
            size: 17,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AppColors.navy,
                fontSize: 10.7,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: onRetry,
            child: const Text(
              'Retry',
              style: TextStyle(fontSize: 10.8),
            ),
          ),
        ],
      ),
    );
  }
}

class _ApplicantBackground extends StatelessWidget {
  const _ApplicantBackground();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: -120,
          right: -100,
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.blue.withOpacity(0.09),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: -140,
          left: -130,
          child: Container(
            width: 320,
            height: 320,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.green.withOpacity(0.05),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ApplicantDetailShimmer extends StatelessWidget {
  const _ApplicantDetailShimmer();

  @override
  Widget build(BuildContext context) {
    return const _ShimmerAnimator(
      child: SingleChildScrollView(
        physics: NeverScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(16, 58, 16, 26),
        child: Column(
          children: [
            _ApplicantHeroShimmer(),
            SizedBox(height: 12),
            _DetailSectionShimmer(rows: 3),
            SizedBox(height: 12),
            _DetailSectionShimmer(rows: 5),
            SizedBox(height: 12),
            _CredentialSectionShimmer(),
            SizedBox(height: 12),
            _DetailSectionShimmer(rows: 5),
          ],
        ),
      ),
    );
  }
}

class _ApplicantHeroShimmer extends StatelessWidget {
  const _ApplicantHeroShimmer();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _ShimmerBox(width: 76, height: 25, radius: 20),
              Spacer(),
              _ShimmerBox(width: 30, height: 13, radius: 6),
            ],
          ),
          SizedBox(height: 18),
          Row(
            children: [
              _ShimmerBox(width: 60, height: 60, radius: 30),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ShimmerBox(width: 150, height: 16, radius: 7),
                    SizedBox(height: 8),
                    _ShimmerBox(width: 210, height: 11, radius: 6),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 18),
          _ShimmerBox(width: double.infinity, height: 40, radius: 14),
        ],
      ),
    );
  }
}

class _DetailSectionShimmer extends StatelessWidget {
  const _DetailSectionShimmer({required this.rows});

  final int rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              _ShimmerBox(width: 32, height: 32, radius: 10),
              SizedBox(width: 9),
              _ShimmerBox(width: 126, height: 15, radius: 6),
            ],
          ),
          const SizedBox(height: 16),
          ...List.generate(
            rows,
                (index) => const Padding(
              padding: EdgeInsets.only(bottom: 10),
              child: _ShimmerBox(
                width: double.infinity,
                height: 13,
                radius: 7,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CredentialSectionShimmer extends StatelessWidget {
  const _CredentialSectionShimmer();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _ShimmerBox(width: 32, height: 32, radius: 10),
              SizedBox(width: 9),
              _ShimmerBox(width: 170, height: 15, radius: 6),
            ],
          ),
          SizedBox(height: 14),
          _ShimmerBox(width: double.infinity, height: 122, radius: 15),
          SizedBox(height: 9),
          _ShimmerBox(width: double.infinity, height: 122, radius: 15),
        ],
      ),
    );
  }
}

class _ShimmerAnimator extends StatefulWidget {
  const _ShimmerAnimator({required this.child});

  final Widget child;

  @override
  State<_ShimmerAnimator> createState() => _ShimmerAnimatorState();
}

class _ShimmerAnimatorState extends State<_ShimmerAnimator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1250),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) {
        final value = _controller.value;
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment(-1.4 + (value * 2.8), 0),
              end: Alignment(-0.4 + (value * 2.8), 0),
              colors: const [
                Color(0xFFEAF0F4),
                Color(0xFFF8FBFC),
                Color(0xFFEAF0F4),
              ],
              stops: const [0.2, 0.5, 0.8],
            ).createShader(bounds);
          },
          child: child,
        );
      },
    );
  }
}

class _ShimmerBox extends StatelessWidget {
  const _ShimmerBox({
    required this.width,
    required this.height,
    required this.radius,
  });

  final double width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFEAF0F4),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

class _TinyPulse extends StatefulWidget {
  const _TinyPulse();

  @override
  State<_TinyPulse> createState() => _TinyPulseState();
}

class _TinyPulseState extends State<_TinyPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
      lowerBound: 0.35,
      upperBound: 1,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(
          color: AppColors.blue,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class _ActionLoadingBar extends StatefulWidget {
  const _ActionLoadingBar();

  @override
  State<_ActionLoadingBar> createState() => _ActionLoadingBarState();
}

class _ActionLoadingBarState extends State<_ActionLoadingBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Container(
          width: double.infinity,
          height: 3,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              stops: [
                0,
                0.25 + (_controller.value * 0.35),
                1,
              ],
              colors: [
                AppColors.blueBg,
                AppColors.blue,
                AppColors.blueBg,
              ],
            ),
          ),
        );
      },
    );
  }
}

class _VisualPair {
  const _VisualPair({
    required this.foreground,
    required this.background,
  });

  final Color foreground;
  final Color background;
}

_VisualPair _applicationVisual(String status) {
  switch (status.trim().toLowerCase()) {
    case 'accepted':
      return const _VisualPair(
        foreground: AppColors.green,
        background: AppColors.greenBg,
      );
    case 'rejected':
      return const _VisualPair(
        foreground: AppColors.red,
        background: AppColors.redBg,
      );
    case 'withdrawn':
      return const _VisualPair(
        foreground: AppColors.orange,
        background: AppColors.orangeBg,
      );
    default:
      return const _VisualPair(
        foreground: AppColors.blue,
        background: AppColors.blueBg,
      );
  }
}

String _pretty(String value) {
  final clean = value.trim();
  if (clean.isEmpty) return '';

  return clean
      .split(RegExp(r'[_\s-]+'))
      .where((part) => part.isNotEmpty)
      .map(
        (part) =>
    '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}',
  )
      .join(' ');
}

String _initials(String value) {
  final parts = value
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .toList();

  if (parts.isEmpty) return 'P#';
  if (parts.length == 1) {
    final text = parts.first;
    return text.length <= 2
        ? text.toUpperCase()
        : text.substring(0, 2).toUpperCase();
  }

  return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
}
