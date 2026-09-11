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
  static const String _cachePrefix = 'company_applicant_detail_v4_';

  late final CompanyJobController _controller;
  late CompanyJobApplicationModel _application;

  _ApplicantDetailSnapshot? _view;
  String? _cacheKey;
  String? _backgroundError;

  bool _changed = false;
  bool _backgroundRefreshing = false;
  bool _cacheReadFinished = false;

  bool get _acting =>
      _controller.isAcceptingApplicant ||
          _controller.isRejectingApplicant;

  @override
  void initState() {
    super.initState();

    _controller = CompanyJobController(
      CompanyJobService(ApiClient()),
    );

    _application = widget.application;

    // Instant first paint from the application already supplied by Job Details.
    _view = _ApplicantDetailSnapshot.fromModel(_application);

    unawaited(_bootstrap());
  }

  Future<void> _bootstrap() async {
    await _loadCache();
    if (!mounted) return;
    unawaited(_refreshInBackground());
  }

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
        final cached = map['application'];
        if (cached is Map) {
          final snapshot = _ApplicantDetailSnapshot.fromJson(
            Map<String, dynamic>.from(cached),
          );

          if (!mounted) return;
          setState(() {
            final current = _view;
            _view = current == null
                ? snapshot
                : current.mergeCachedDetails(snapshot);
            _cacheReadFinished = true;
          });
          return;
        }
      }
    } catch (_) {
      // Ignore malformed/old cache and keep the passed application visible.
    }

    if (!mounted) return;
    setState(() => _cacheReadFinished = true);
  }

  Future<void> _saveCache() async {
    final key = _cacheKey;
    final view = _view;
    if (key == null || view == null) return;

    try {
      await _storage.write(
        key: key,
        value: jsonEncode({
          'version': 4,
          'saved_at': DateTime.now().toIso8601String(),
          'application': view.toJson(),
        }),
      );
    } catch (_) {}
  }

  Future<void> _refreshInBackground() async {
    if (_backgroundRefreshing) return;
    _backgroundRefreshing = true;

    if (mounted) {
      setState(() => _backgroundError = null);
    }

    try {
      final success = await _controller.loadApplicants(widget.jobId);
      if (!mounted) return;

      if (!success) {
        setState(() {
          _backgroundError = _controller.applicantsErrorMessage;
        });
        return;
      }

      CompanyJobApplicationModel? fresh;
      for (final item in _controller.applicants) {
        if (item.id == _application.id) {
          fresh = item;
          break;
        }
      }

      if (fresh == null) {
        setState(() {
          _backgroundError = 'This application is no longer in the job list.';
        });
        return;
      }

      final freshApplication = fresh;
      setState(() {
        _application = freshApplication;
        _view = _ApplicantDetailSnapshot.fromModel(freshApplication);
        _backgroundError = null;
      });

      unawaited(_saveCache());
    } finally {
      _backgroundRefreshing = false;
      if (mounted) setState(() {});
    }
  }

  Future<void> _accept() async {
    if (!_application.isPending || _acting) return;

    final confirmed = await _confirmDialog(
      title: 'Accept Applicant?',
      message:
      'Accept ${_pilotNameFromView()} for this job? The application will move to Accepted.',
      confirmText: 'Accept',
      icon: Icons.check_circle_outline_rounded,
    );

    if (confirmed != true || !mounted) return;

    setState(() {});
    HapticFeedback.mediumImpact();

    final updated = await _controller.acceptApplicant(
      jobId: widget.jobId,
      application: _application,
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
      _application = updated;
      _view = _ApplicantDetailSnapshot.fromModel(updated);
      _changed = true;
    });
    unawaited(_saveCache());

    _showSnack('Applicant accepted successfully.');
  }

  Future<void> _reject() async {
    if (!_application.isPending || _acting) return;

    final reason = await _showRejectDialog();
    if (reason == null || !mounted) return;

    setState(() {});
    HapticFeedback.mediumImpact();

    final updated = await _controller.rejectApplicant(
      jobId: widget.jobId,
      application: _application,
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
      _application = updated;
      _view = _ApplicantDetailSnapshot.fromModel(updated);
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
                child: Icon(icon, size: 19, color: AppColors.green),
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
              fontSize: 12.5,
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
    final controller = TextEditingController();

    final result = await showDialog<String?>(
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
                  fontSize: 12.3,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 13),
              TextField(
                controller: controller,
                maxLength: 2000,
                minLines: 3,
                maxLines: 6,
                textCapitalization: TextCapitalization.sentences,
                style: const TextStyle(fontSize: 13),
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
                  Navigator.of(dialogContext).pop(controller.text),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red.shade700,
              ),
              child: const Text('Reject'),
            ),
          ],
        );
      },
    );

    controller.dispose();
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final view = _view;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        children: [
          const _ApplicantBackground(),
          SafeArea(
            child: view == null
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
                      padding:
                      const EdgeInsets.fromLTRB(16, 8, 16, 26),
                      children: [
                        _hero(view),
                        if (_backgroundError != null) ...[
                          const SizedBox(height: 9),
                          _OfflineNotice(
                            message: _backgroundError!,
                            onRetry: _refreshInBackground,
                          ),
                        ],
                        const SizedBox(height: 12),
                        _applicationInfo(view),
                        const SizedBox(height: 12),
                        _pilotSection(view),
                        const SizedBox(height: 12),
                        _droneSection(view),
                        if (view.coverMessage.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          _section(
                            title: 'Cover Message',
                            icon: Icons.chat_bubble_outline_rounded,
                            child: Text(
                              view.coverMessage,
                              style: const TextStyle(
                                color: AppColors.text,
                                fontSize: 12.5,
                                height: 1.55,
                              ),
                            ),
                          ),
                        ],
                        if (view.rejectionReason.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          _section(
                            title: 'Rejection Reason',
                            icon: Icons.info_outline_rounded,
                            accent: Colors.red.shade700,
                            accentBackground: Colors.red.shade50,
                            child: Text(
                              view.rejectionReason,
                              style: const TextStyle(
                                color: AppColors.text,
                                fontSize: 12.5,
                                height: 1.55,
                              ),
                            ),
                          ),
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
      view != null && _application.isPending ? _bottomActions() : null,
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
            child: _backgroundRefreshing
                ? const Center(child: _TinyPulse())
                : null,
          ),
        ],
      ),
    );
  }

  Widget _hero(_ApplicantDetailSnapshot view) {
    final visual = _applicationVisual(view.status);
    final pilot = view.pilot;
    final name = pilot?.displayName.trim().isNotEmpty == true
        ? pilot!.displayName.trim()
        : 'Pilot #${view.pilotProfileId}';

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
                label: view.statusLabel.isEmpty
                    ? _pretty(view.status)
                    : view.statusLabel,
                foreground: visual.foreground,
                background: visual.background,
              ),
              const Spacer(),
              Text(
                '#${view.id}',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.62),
                  fontSize: 11.3,
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
                  pilot?.profilePhoto.trim().isNotEmpty == true
                      ? NetworkImage(pilot!.profilePhoto.trim())
                      : null,
                  child: pilot?.profilePhoto.trim().isNotEmpty == true
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
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      _pilotHeroSubtitle(view),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.70),
                        fontSize: 11.5,
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
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                    'Application for Job #${view.jobPostingId}',
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

  Widget _applicationInfo(_ApplicantDetailSnapshot view) {
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
                  value: '#${view.id}',
                  icon: Icons.tag_rounded,
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: _MiniStat(
                  label: 'Job',
                  value: '#${view.jobPostingId}',
                  icon: Icons.work_outline_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _infoRow(
            'Submitted',
            _formatDateTime(view.createdAt),
            Icons.schedule_rounded,
          ),
          if (view.decidedAt != null)
            _infoRow(
              'Decision',
              _formatDateTime(view.decidedAt),
              Icons.fact_check_outlined,
            ),
          if (view.withdrawnAt != null)
            _infoRow(
              'Withdrawn',
              _formatDateTime(view.withdrawnAt),
              Icons.undo_rounded,
            ),
        ],
      ),
    );
  }

  Widget _pilotSection(_ApplicantDetailSnapshot view) {
    final pilot = view.pilot;

    if (pilot == null) {
      if (_backgroundRefreshing) {
        return const _ShimmerAnimator(
          child: _DetailSectionShimmer(rows: 4),
        );
      }

      return _section(
        title: 'Pilot Profile',
        icon: Icons.person_outline_rounded,
        child: Text(
          'Pilot #${view.pilotProfileId}',
          style: const TextStyle(
            color: AppColors.navy,
            fontSize: 12.5,
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
                  value:
                  pilot.experienceLabel.isEmpty ? '—' : pilot.experienceLabel,
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
                fontSize: 12.3,
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
        ],
      ),
    );
  }

  Widget _droneSection(_ApplicantDetailSnapshot view) {
    final drone = view.drone;

    if (drone == null) {
      if (_backgroundRefreshing) {
        return const _ShimmerAnimator(
          child: _DetailSectionShimmer(rows: 4),
        );
      }

      return _section(
        title: 'Committed Drone',
        icon: Icons.flight_outlined,
        child: Text(
          'Drone #${view.droneId}',
          style: const TextStyle(
            color: AppColors.navy,
            fontSize: 12.5,
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
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: const Icon(
                    Icons.flight_rounded,
                    color: AppColors.green,
                    size: 21,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        drone.displayName.isEmpty
                            ? 'Drone #${view.droneId}'
                            : drone.displayName,
                        style: const TextStyle(
                          color: AppColors.navy,
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      if (drone.manufactureYear != null) ...[
                        const SizedBox(height: 3),
                        Text(
                          '${drone.manufactureYear}',
                          style: const TextStyle(
                            color: AppColors.grey,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ],
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
              children: drone.capabilities.map(_chip).toList(),
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
          if (drone.totalBatteries != null)
            _infoRow(
              'Batteries',
              '${drone.totalBatteries}',
              Icons.battery_charging_full_rounded,
            ),
        ],
      ),
    );
  }

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
                child: Icon(icon, color: accent, size: 16),
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

  Widget _infoRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.blue, size: 15),
          const SizedBox(width: 7),
          SizedBox(
            width: 76,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.grey,
                fontSize: 11.2,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: AppColors.navy,
                fontSize: 11.8,
                fontWeight: FontWeight.w700,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.blueBg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        value,
        style: const TextStyle(
          color: AppColors.blue,
          fontSize: 10.8,
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
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: const LinearProgressIndicator(
                  minHeight: 3,
                  color: AppColors.blue,
                  backgroundColor: AppColors.blueBg,
                ),
              ),
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
                    icon: const Icon(Icons.close_rounded, size: 18),
                    label: const Text(
                      'Reject',
                      style: TextStyle(
                        fontSize: 12.5,
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
                    icon: const Icon(Icons.check_rounded, size: 18),
                    label: const Text(
                      'Accept',
                      style: TextStyle(
                        fontSize: 12.5,
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

  String _pilotNameFromView() {
    final pilot = _view?.pilot;
    if (pilot != null && pilot.displayName.trim().isNotEmpty) {
      return pilot.displayName.trim();
    }
    return 'Pilot #${_view?.pilotProfileId ?? _application.pilotProfileId}';
  }

  String _pilotHeroSubtitle(_ApplicantDetailSnapshot view) {
    final pilot = view.pilot;
    if (pilot == null) return 'Pilot profile #${view.pilotProfileId}';

    final parts = <String>[];
    if (pilot.location.isNotEmpty) parts.add(pilot.location);
    if (pilot.experienceLabel.isNotEmpty) parts.add(pilot.experienceLabel);

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

  String _cleanNumber(double value) {
    if (value == value.roundToDouble()) return value.toStringAsFixed(0);
    return value.toStringAsFixed(2);
  }

  void _showSnack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor:
          isError ? Colors.red.shade700 : AppColors.navy,
          content: Text(message),
        ),
      );
  }
}

class _ApplicantDetailSnapshot {
  const _ApplicantDetailSnapshot({
    required this.id,
    required this.jobPostingId,
    required this.pilotProfileId,
    required this.droneId,
    required this.status,
    required this.statusLabel,
    required this.coverMessage,
    required this.rejectionReason,
    required this.createdAt,
    required this.decidedAt,
    required this.withdrawnAt,
    required this.pilot,
    required this.drone,
  });

  final int id;
  final int jobPostingId;
  final int pilotProfileId;
  final int droneId;
  final String status;
  final String statusLabel;
  final String coverMessage;
  final String rejectionReason;
  final DateTime? createdAt;
  final DateTime? decidedAt;
  final DateTime? withdrawnAt;
  final _PilotSnapshot? pilot;
  final _DroneSnapshot? drone;

  factory _ApplicantDetailSnapshot.fromModel(
      CompanyJobApplicationModel application,
      ) {
    return _ApplicantDetailSnapshot(
      id: application.id,
      jobPostingId: application.jobPostingId,
      pilotProfileId: application.pilotProfileId,
      droneId: application.droneId,
      status: application.status.trim().toLowerCase(),
      statusLabel: application.statusLabel,
      coverMessage: application.coverMessage,
      rejectionReason: application.rejectionReason,
      createdAt: application.createdAt,
      decidedAt: application.decidedAt,
      withdrawnAt: application.withdrawnAt,
      pilot: application.pilotProfile == null
          ? null
          : _PilotSnapshot.fromModel(application.pilotProfile!),
      drone: application.drone == null
          ? null
          : _DroneSnapshot.fromModel(application.drone!),
    );
  }

  _ApplicantDetailSnapshot mergeCachedDetails(
      _ApplicantDetailSnapshot cached,
      ) {
    return _ApplicantDetailSnapshot(
      id: id,
      jobPostingId: jobPostingId,
      pilotProfileId: pilotProfileId,
      droneId: droneId,
      status: status,
      statusLabel: statusLabel.isEmpty ? cached.statusLabel : statusLabel,
      coverMessage: coverMessage.isEmpty ? cached.coverMessage : coverMessage,
      rejectionReason:
      rejectionReason.isEmpty ? cached.rejectionReason : rejectionReason,
      createdAt: createdAt ?? cached.createdAt,
      decidedAt: decidedAt ?? cached.decidedAt,
      withdrawnAt: withdrawnAt ?? cached.withdrawnAt,
      pilot: pilot ?? cached.pilot,
      drone: drone ?? cached.drone,
    );
  }

  factory _ApplicantDetailSnapshot.fromJson(Map<String, dynamic> json) {
    _PilotSnapshot? pilot;
    final rawPilot = json['pilot'];
    if (rawPilot is Map) {
      pilot = _PilotSnapshot.fromJson(Map<String, dynamic>.from(rawPilot));
    }

    _DroneSnapshot? drone;
    final rawDrone = json['drone'];
    if (rawDrone is Map) {
      drone = _DroneSnapshot.fromJson(Map<String, dynamic>.from(rawDrone));
    }

    return _ApplicantDetailSnapshot(
      id: _asInt(json['id']),
      jobPostingId: _asInt(json['job_posting_id']),
      pilotProfileId: _asInt(json['pilot_profile_id']),
      droneId: _asInt(json['drone_id']),
      status: _asString(json['status']).toLowerCase(),
      statusLabel: _asString(json['status_label']),
      coverMessage: _asString(json['cover_message']),
      rejectionReason: _asString(json['rejection_reason']),
      createdAt: _asDate(json['created_at']),
      decidedAt: _asDate(json['decided_at']),
      withdrawnAt: _asDate(json['withdrawn_at']),
      pilot: pilot,
      drone: drone,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'job_posting_id': jobPostingId,
    'pilot_profile_id': pilotProfileId,
    'drone_id': droneId,
    'status': status,
    'status_label': statusLabel,
    'cover_message': coverMessage,
    'rejection_reason': rejectionReason,
    'created_at': createdAt?.toIso8601String(),
    'decided_at': decidedAt?.toIso8601String(),
    'withdrawn_at': withdrawnAt?.toIso8601String(),
    'pilot': pilot?.toJson(),
    'drone': drone?.toJson(),
  };
}

class _PilotSnapshot {
  const _PilotSnapshot({
    required this.id,
    required this.displayName,
    required this.profilePhoto,
    required this.location,
    required this.experienceLabel,
    required this.nationality,
    required this.languages,
    required this.bio,
    required this.previousCompany,
  });

  final int id;
  final String displayName;
  final String profilePhoto;
  final String location;
  final String experienceLabel;
  final String nationality;
  final List<String> languages;
  final String bio;
  final String previousCompany;

  factory _PilotSnapshot.fromModel(dynamic pilot) {
    return _PilotSnapshot(
      id: _asInt(pilot.id),
      displayName: pilot.displayName?.toString() ?? '',
      profilePhoto: pilot.profilePhoto?.toString() ?? '',
      location: pilot.location?.toString() ?? '',
      experienceLabel: pilot.experienceLabel?.toString() ?? '',
      nationality: pilot.nationality?.toString() ?? '',
      languages: List<String>.from(pilot.languages ?? const <String>[]),
      bio: pilot.bio?.toString() ?? '',
      previousCompany: pilot.previousCompany?.toString() ?? '',
    );
  }

  factory _PilotSnapshot.fromJson(Map<String, dynamic> json) {
    return _PilotSnapshot(
      id: _asInt(json['id']),
      displayName: _asString(json['display_name']),
      profilePhoto: _asString(json['profile_photo']),
      location: _asString(json['location']),
      experienceLabel: _asString(json['experience_label']),
      nationality: _asString(json['nationality']),
      languages: _stringList(json['languages']),
      bio: _asString(json['bio']),
      previousCompany: _asString(json['previous_company']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'display_name': displayName,
    'profile_photo': profilePhoto,
    'location': location,
    'experience_label': experienceLabel,
    'nationality': nationality,
    'languages': languages,
    'bio': bio,
    'previous_company': previousCompany,
  };
}

class _DroneSnapshot {
  const _DroneSnapshot({
    required this.displayName,
    required this.manufactureYear,
    required this.capabilities,
    required this.serialNumber,
    required this.weightKg,
    required this.flightTimePerBatteryMinutes,
    required this.totalBatteries,
  });

  final String displayName;
  final int? manufactureYear;
  final List<String> capabilities;
  final String serialNumber;
  final double? weightKg;
  final int? flightTimePerBatteryMinutes;
  final int? totalBatteries;

  factory _DroneSnapshot.fromModel(dynamic drone) {
    return _DroneSnapshot(
      displayName: drone.displayName?.toString() ?? '',
      manufactureYear: _asNullableInt(drone.manufactureYear),
      capabilities: List<String>.from(drone.capabilities ?? const <String>[]),
      serialNumber: drone.serialNumber?.toString() ?? '',
      weightKg: _asDouble(drone.weightKg),
      flightTimePerBatteryMinutes:
      _asNullableInt(drone.flightTimePerBatteryMinutes),
      totalBatteries: _asNullableInt(drone.totalBatteries),
    );
  }

  factory _DroneSnapshot.fromJson(Map<String, dynamic> json) {
    return _DroneSnapshot(
      displayName: _asString(json['display_name']),
      manufactureYear: _asNullableInt(json['manufacture_year']),
      capabilities: _stringList(json['capabilities']),
      serialNumber: _asString(json['serial_number']),
      weightKg: _asDouble(json['weight_kg']),
      flightTimePerBatteryMinutes:
      _asNullableInt(json['flight_time_per_battery_minutes']),
      totalBatteries: _asNullableInt(json['total_batteries']),
    );
  }

  Map<String, dynamic> toJson() => {
    'display_name': displayName,
    'manufacture_year': manufactureYear,
    'capabilities': capabilities,
    'serial_number': serialNumber,
    'weight_kg': weightKg,
    'flight_time_per_battery_minutes': flightTimePerBatteryMinutes,
    'total_batteries': totalBatteries,
  };
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
      constraints: const BoxConstraints(minHeight: 82),
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.blue, size: 16),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.grey,
              fontSize: 10.5,
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
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: foreground,
          fontSize: 10.2,
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
        fontSize: 11.2,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _HeroSyncBadge extends StatelessWidget {
  const _HeroSyncBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _TinyPulse(light: true),
          SizedBox(width: 5),
          Text(
            'Updating',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 9.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _OfflineNotice extends StatelessWidget {
  const _OfflineNotice({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 9, 6, 9),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.cloud_off_rounded,
            size: 17,
            color: AppColors.grey,
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              'Saved data is shown. Latest update could not be loaded.',
              style: const TextStyle(
                color: AppColors.grey,
                fontSize: 10.8,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          TextButton(
            onPressed: onRetry,
            child: const Text('Retry'),
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
          top: -160,
          right: -125,
          child: IgnorePointer(
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.blue.withOpacity(0.10),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ),
        Positioned(
          top: 510,
          left: -170,
          child: IgnorePointer(
            child: Container(
              width: 300,
              height: 300,
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
        ),
      ],
    );
  }
}

class _ApplicantDetailShimmer extends StatelessWidget {
  const _ApplicantDetailShimmer();

  @override
  Widget build(BuildContext context) {
    return _ShimmerAnimator(
      child: ListView(
        physics: NeverScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          Row(
            children: [
              _ShimmerBox(width: 44, height: 44, radius: 22),
              Spacer(),
              _ShimmerBox(width: 130, height: 14, radius: 7),
              Spacer(),
              SizedBox(width: 44),
            ],
          ),
          SizedBox(height: 12),
          _ApplicantHeroShimmer(),
          SizedBox(height: 12),
          _DetailSectionShimmer(rows: 3),
          SizedBox(height: 12),
          _DetailSectionShimmer(rows: 5),
          SizedBox(height: 12),
          _DetailSectionShimmer(rows: 4),
        ],
      ),
    );
  }
}

class _ApplicantHeroShimmer extends StatelessWidget {
  const _ApplicantHeroShimmer();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 190,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Column(
        children: [
          Row(
            children: [
              _ShimmerBox(width: 70, height: 24, radius: 12),
              Spacer(),
              _ShimmerBox(width: 32, height: 11, radius: 6),
            ],
          ),
          SizedBox(height: 20),
          Row(
            children: [
              _ShimmerBox(width: 60, height: 60, radius: 30),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ShimmerBox(width: 145, height: 14, radius: 7),
                    SizedBox(height: 8),
                    _ShimmerBox(width: 190, height: 10, radius: 5),
                  ],
                ),
              ),
            ],
          ),
          Spacer(),
          _ShimmerBox(height: 34, radius: 14),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              _ShimmerBox(width: 32, height: 32, radius: 10),
              SizedBox(width: 9),
              _ShimmerBox(width: 128, height: 14, radius: 7),
            ],
          ),
          const SizedBox(height: 14),
          ...List.generate(
            rows,
                (index) => const Padding(
              padding: EdgeInsets.only(bottom: 9),
              child: _ShimmerBox(height: 32, radius: 10),
            ),
          ),
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
      duration: const Duration(milliseconds: 1350),
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
        final x = -1.5 + (_controller.value * 3.0);
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) => LinearGradient(
            begin: Alignment(x - 1, 0),
            end: Alignment(x + 1, 0),
            colors: [
              Colors.grey.shade200,
              Colors.grey.shade100,
              Colors.white,
              Colors.grey.shade100,
              Colors.grey.shade200,
            ],
            stops: const [0, 0.30, 0.50, 0.70, 1],
          ).createShader(bounds),
          child: child,
        );
      },
    );
  }
}

class _ShimmerBox extends StatelessWidget {
  const _ShimmerBox({
    this.width,
    required this.height,
    this.radius = 8,
  });

  final double? width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width ?? double.infinity,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

class _TinyPulse extends StatefulWidget {
  const _TinyPulse({this.light = false});

  final bool light;

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
      duration: const Duration(milliseconds: 700),
      lowerBound: 0.45,
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
        width: 6,
        height: 6,
        decoration: BoxDecoration(
          color: widget.light ? Colors.white70 : AppColors.blue,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class _VisualPair {
  const _VisualPair(this.foreground, this.background);

  final Color foreground;
  final Color background;
}

_VisualPair _applicationVisual(String status) {
  switch (status.trim().toLowerCase()) {
    case 'accepted':
      return const _VisualPair(AppColors.green, AppColors.greenBg);
    case 'rejected':
      return _VisualPair(Colors.red.shade700, Colors.red.shade50);
    case 'withdrawn':
      return _VisualPair(AppColors.grey, Colors.grey.shade100);
    default:
      return const _VisualPair(AppColors.blue, AppColors.blueBg);
  }
}

String _asString(dynamic value) => value?.toString() ?? '';

int _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

int? _asNullableInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}

double? _asDouble(dynamic value) {
  if (value == null) return null;
  if (value is double) return value;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}

DateTime? _asDate(dynamic value) {
  if (value is DateTime) return value;
  final text = value?.toString().trim() ?? '';
  if (text.isEmpty) return null;
  return DateTime.tryParse(text);
}

List<String> _stringList(dynamic value) {
  if (value is List) {
    return value
        .map((item) => item?.toString().trim() ?? '')
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
  }
  return const [];
}

String _pretty(String value) {
  final clean = value.trim();
  if (clean.isEmpty) return 'Pending';
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
      .where((item) => item.isNotEmpty)
      .toList();

  if (parts.isEmpty) return 'P';
  if (parts.length == 1) return parts.first[0].toUpperCase();
  return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
}
