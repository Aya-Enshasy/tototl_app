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
import '../../models/company_job_posting_model.dart';
import '../../services/company_job_service.dart';

import 'company_applicant_detail_screen.dart';
import 'edit_company_job_screen.dart';

class CompanyJobDetailScreen extends StatefulWidget {
  const CompanyJobDetailScreen({
    super.key,
    required this.jobId,
  });

  final int jobId;

  @override
  State<CompanyJobDetailScreen> createState() =>
      _CompanyJobDetailScreenState();
}

class _CompanyJobDetailScreenState extends State<CompanyJobDetailScreen> {
  static const FlutterSecureStorage _storage = FlutterSecureStorage();
  static const String _cachePrefix = 'company_job_detail_v4_';

  late final CompanyJobController _controller;

  _JobDetailSnapshot? _job;
  List<_ApplicantSnapshot> _applicants = const [];

  String? _cacheKey;
  String? _pageError;
  String? _applicantsError;

  bool _cacheReadFinished = false;
  bool _firstNetworkAttemptFinished = false;
  bool _networkRefreshing = false;
  bool _applicantsRefreshing = false;
  bool _actionLoading = false;

  bool get _hasCachedOrLiveData => _job != null;
  bool get _hasLiveJob => _controller.selectedJob != null;

  @override
  void initState() {
    super.initState();

    _controller = CompanyJobController(
      CompanyJobService(ApiClient()),
    );

    unawaited(_bootstrap());
  }

  Future<void> _bootstrap() async {
    await _loadCache();
    if (!mounted) return;
    unawaited(_refreshFromNetwork(initial: true));
  }

  Future<void> _loadCache() async {
    try {
      final userId = await UserSessionStorage.getUserId();
      if (userId == null) {
        if (!mounted) return;
        setState(() => _cacheReadFinished = true);
        return;
      }

      _cacheKey = '$_cachePrefix${userId}_${widget.jobId}';
      final raw = await _storage.read(key: _cacheKey!);

      if (raw == null || raw.trim().isEmpty) {
        if (!mounted) return;
        setState(() => _cacheReadFinished = true);
        return;
      }

      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        if (!mounted) return;
        setState(() => _cacheReadFinished = true);
        return;
      }

      final map = Map<String, dynamic>.from(decoded);
      final rawJob = map['job'];
      final rawApplicants = map['applicants'];

      _JobDetailSnapshot? cachedJob;
      if (rawJob is Map) {
        cachedJob = _JobDetailSnapshot.fromJson(
          Map<String, dynamic>.from(rawJob),
        );
      }

      final cachedApplicants = <_ApplicantSnapshot>[];
      if (rawApplicants is List) {
        for (final value in rawApplicants) {
          if (value is Map) {
            cachedApplicants.add(
              _ApplicantSnapshot.fromJson(
                Map<String, dynamic>.from(value),
              ),
            );
          }
        }
      }

      if (!mounted) return;
      setState(() {
        _job = cachedJob;
        _applicants = cachedApplicants;
        _cacheReadFinished = true;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _cacheReadFinished = true);
    }
  }

  Future<void> _saveCache() async {
    final key = _cacheKey;
    final job = _job;
    if (key == null || job == null) return;

    final payload = <String, dynamic>{
      'version': 4,
      'saved_at': DateTime.now().toIso8601String(),
      'job': job.toJson(),
      'applicants': _applicants.map((item) => item.toJson()).toList(),
    };

    try {
      await _storage.write(
        key: key,
        value: jsonEncode(payload),
      );
    } catch (_) {
      // Cache failure must never block the real screen.
    }
  }

  Future<void> _clearCache() async {
    final key = _cacheKey;
    if (key == null) return;
    try {
      await _storage.delete(key: key);
    } catch (_) {}
  }

  Future<void> _refreshFromNetwork({bool initial = false}) async {
    if (_networkRefreshing) return;
    _networkRefreshing = true;

    if (mounted) {
      setState(() {
        if (!_hasCachedOrLiveData) _pageError = null;
      });
    }

    try {
      final detailSuccess =
      await _controller.loadJobDetails(widget.jobId);

      if (!mounted) return;

      if (!detailSuccess || _controller.selectedJob == null) {
        setState(() {
          if (!_hasCachedOrLiveData) {
            _pageError =
                _controller.errorMessage ?? 'Unable to load job details.';
          }
        });
        return;
      }

      final freshJob =
      _JobDetailSnapshot.fromModel(_controller.selectedJob!);

      setState(() {
        _job = freshJob;
        _pageError = null;
      });
      unawaited(_saveCache());

      await _refreshApplicantsFromNetwork();
    } catch (e) {
      if (!mounted) return;
      if (!_hasCachedOrLiveData) {
        setState(() => _pageError = e.toString());
      }
    } finally {
      _networkRefreshing = false;
      if (mounted) {
        setState(() => _firstNetworkAttemptFinished = true);
      }
    }
  }

  Future<void> _refreshApplicantsFromNetwork() async {
    if (_applicantsRefreshing) return;
    _applicantsRefreshing = true;

    try {
      final success = await _controller.loadApplicants(widget.jobId);
      if (!mounted) return;

      if (success) {
        final fresh = _controller.applicants
            .map(_ApplicantSnapshot.fromModel)
            .toList(growable: false);

        setState(() {
          _applicants = fresh;
          _applicantsError = null;
        });
        unawaited(_saveCache());
      } else {
        setState(() {
          _applicantsError = _controller.applicantsErrorMessage;
        });
      }
    } finally {
      _applicantsRefreshing = false;
      if (mounted) setState(() {});
    }
  }

  Future<void> _manualRefresh() async {
    await _refreshFromNetwork();
  }

  Future<void> _waitForOverlayToSettle() async {
    await Future<void>.delayed(const Duration(milliseconds: 220));
  }

  Future<bool> _ensureLiveJob() async {
    if (_controller.selectedJob != null) return true;

    await _refreshFromNetwork();
    if (!mounted) return false;

    if (_controller.selectedJob == null) {
      _showSnack(
        'Latest job data is not available yet. Try again.',
        isError: true,
      );
      return false;
    }

    return true;
  }

  Future<void> _handleMenuAction(String value) async {
    await _waitForOverlayToSettle();
    if (!mounted || _actionLoading) return;

    switch (value) {
      case 'edit':
        await _edit();
        break;
      case 'publish':
        await _publish();
        break;
      case 'delete':
        await _delete();
        break;
      case 'close':
        await _closeJob();
        break;
      case 'cancel':
        await _cancelJob();
        break;
    }
  }

  Future<void> _edit() async {
    if (_actionLoading || !await _ensureLiveJob()) return;

    final job = _controller.selectedJob;
    if (job == null || job.status.toLowerCase() != 'draft') return;

    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => EditCompanyJobScreen(job: job),
      ),
    );

    if (!mounted) return;
    if (changed == true) {
      await _refreshFromNetwork();
    }
  }

  Future<void> _publish() async {
    if (_actionLoading || !await _ensureLiveJob()) return;

    final job = _controller.selectedJob;
    if (job == null || job.status.toLowerCase() != 'draft') return;

    final confirmed = await _confirmDialog(
      title: 'Publish Job?',
      message:
      'Once published, pilots can see this job and submit applications. Editing and deleting are only available while the job is Draft.',
      confirmText: 'Publish',
      icon: Icons.public_rounded,
    );

    if (confirmed != true || !mounted) return;
    await _waitForOverlayToSettle();
    if (!mounted) return;

    setState(() => _actionLoading = true);
    HapticFeedback.mediumImpact();

    final published = await _controller.publishJob(job.id);
    if (!mounted) return;
    setState(() => _actionLoading = false);

    if (published == null) {
      _showSnack(
        _controller.errorMessage ?? 'Unable to publish job.',
        isError: true,
      );
      return;
    }

    _showSnack('Job published successfully.');
    await _refreshFromNetwork();
  }

  Future<void> _delete() async {
    if (_actionLoading || !await _ensureLiveJob()) return;

    final job = _controller.selectedJob;
    if (job == null || job.status.toLowerCase() != 'draft') return;

    final confirmed = await _confirmDialog(
      title: 'Delete Draft?',
      message: 'Delete "${job.title}" permanently? This cannot be undone.',
      confirmText: 'Delete',
      danger: true,
      icon: Icons.delete_outline_rounded,
    );

    if (confirmed != true || !mounted) return;
    await _waitForOverlayToSettle();
    if (!mounted) return;

    setState(() => _actionLoading = true);
    HapticFeedback.mediumImpact();

    final success = await _controller.deleteJob(job.id);
    if (!mounted) return;
    setState(() => _actionLoading = false);

    if (!success) {
      _showSnack(
        _controller.errorMessage ?? 'Unable to delete job.',
        isError: true,
      );
      return;
    }

    await _clearCache();
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  Future<void> _closeJob() async {
    if (_actionLoading || !await _ensureLiveJob()) return;

    final job = _controller.selectedJob;
    if (job == null || job.status.toLowerCase() != 'published') return;

    final confirmed = await _confirmDialog(
      title: 'Close Applications?',
      message:
      'Close "${job.title}" to new applications? Existing applications will stay available for review.',
      confirmText: 'Close Job',
      icon: Icons.lock_clock_outlined,
    );

    if (confirmed != true || !mounted) return;
    await _waitForOverlayToSettle();
    if (!mounted) return;

    setState(() => _actionLoading = true);
    HapticFeedback.mediumImpact();

    final closed = await _controller.closeJob(job.id);
    if (!mounted) return;
    setState(() => _actionLoading = false);

    if (closed == null) {
      _showSnack(
        _controller.errorMessage ?? 'Unable to close job.',
        isError: true,
      );
      return;
    }

    _showSnack('Job closed successfully.');
    await _refreshFromNetwork();
  }

  Future<void> _cancelJob() async {
    if (_actionLoading || !await _ensureLiveJob()) return;

    final job = _controller.selectedJob;
    if (job == null || job.status.toLowerCase() != 'published') return;

    String draftReason = '';
    final reason = await showDialog<String?>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: const Text(
            'Cancel Job?',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.navy,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Cancel "${job.title}" permanently? This keeps the job in history as Cancelled.',
                style: const TextStyle(
                  fontSize: 12.5,
                  height: 1.45,
                  color: AppColors.grey,
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                onChanged: (value) => draftReason = value,
                maxLength: 2000,
                minLines: 3,
                maxLines: 5,
                style: const TextStyle(fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Reason (optional)',
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
              child: const Text('Keep Job'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(
                draftReason.trim(),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red.shade700,
              ),
              child: const Text('Cancel Job'),
            ),
          ],
        );
      },
    );

    if (reason == null || !mounted) return;
    await _waitForOverlayToSettle();
    if (!mounted) return;

    setState(() => _actionLoading = true);
    HapticFeedback.mediumImpact();

    final cancelled = await _controller.cancelJob(
      job.id,
      reason: reason,
    );

    if (!mounted) return;
    setState(() => _actionLoading = false);

    if (cancelled == null) {
      _showSnack(
        _controller.errorMessage ?? 'Unable to cancel job.',
        isError: true,
      );
      return;
    }

    _showSnack('Job cancelled successfully.');
    await _refreshFromNetwork();
  }

  Future<bool?> _confirmDialog({
    required String title,
    required String message,
    required String confirmText,
    required IconData icon,
    bool danger = false,
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
                  color: danger ? Colors.red.shade50 : AppColors.blueBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 19,
                  color: danger ? Colors.red.shade700 : AppColors.blue,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppColors.navy,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            message,
            style: const TextStyle(
              fontSize: 12.5,
              height: 1.45,
              color: AppColors.grey,
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
                backgroundColor:
                danger ? Colors.red.shade700 : AppColors.blue,
              ),
              child: Text(confirmText),
            ),
          ],
        );
      },
    );
  }

  Future<void> _openApplicant(_ApplicantSnapshot snapshot) async {
    CompanyJobApplicationModel? application;

    for (final item in _controller.applicants) {
      if (item.id == snapshot.id) {
        application = item;
        break;
      }
    }

    if (application == null) {
      final success = await _controller.loadApplicants(widget.jobId);
      if (!mounted) return;

      if (success) {
        for (final item in _controller.applicants) {
          if (item.id == snapshot.id) {
            application = item;
            break;
          }
        }

        final fresh = _controller.applicants
            .map(_ApplicantSnapshot.fromModel)
            .toList(growable: false);
        setState(() {
          _applicants = fresh;
          _applicantsError = null;
        });
        unawaited(_saveCache());
      }
    }

    if (application == null) {
      _showSnack(
        'Latest applicant data is still syncing. Try again.',
        isError: true,
      );
      return;
    }

    HapticFeedback.selectionClick();
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => CompanyApplicantDetailScreen(
          jobId: widget.jobId,
          application: application!,
        ),
      ),
    );

    if (!mounted) return;
    unawaited(_refreshApplicantsFromNetwork());

    if (changed == true) {
      _showSnack('Applications updated.');
    }
  }

  bool get _showInitialShimmer =>
      !_cacheReadFinished ||
          (_job == null && !_firstNetworkAttemptFinished && _pageError == null);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        children: [
          const _BackgroundGlow(),
          SafeArea(
            child: _showInitialShimmer
                ? const _JobDetailsPageShimmer()
                : _job == null
                ? _ErrorView(
              message: _pageError ?? 'Unable to load job details.',
              onRetry: () => _refreshFromNetwork(),
            )
                : _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final job = _job!;

    return Column(
      children: [
        _topBar(job),
        Expanded(
          child: RefreshIndicator(
            color: AppColors.blue,
            backgroundColor: Colors.white,
            onRefresh: _manualRefresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 36),
              children: [
                _hero(job),
                const SizedBox(height: 12),
                _overview(job),
                const SizedBox(height: 12),
                _managementSection(job),
                const SizedBox(height: 12),
                _section(
                  icon: Icons.notes_rounded,
                  title: 'Description',
                  child: Text(
                    job.description.isEmpty
                        ? 'No description provided.'
                        : job.description,
                    style: const TextStyle(
                      color: AppColors.text,
                      fontSize: 12.8,
                      height: 1.6,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _requirements(job),
                if (job.attachments.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _attachments(job),
                ],
                if (job.company != null) ...[
                  const SizedBox(height: 12),
                  _companyCard(job.company!),
                ],
                const SizedBox(height: 18),
                _applicationsSection(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _topBar(_JobDetailSnapshot job) {
    final status = job.status.toLowerCase();
    final showMenu = _hasLiveJob &&
        !_actionLoading &&
        (status == 'draft' || status == 'published');

    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 7, 10, 5),
      child: Row(
        children: [
          _RoundIconButton(
            icon: Icons.arrow_back_ios_new_rounded,
            onTap: _actionLoading ? null : () => Navigator.of(context).pop(),
          ),
          const Expanded(
            child: Text(
              'Job Details',
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
            child: showMenu
                ? PopupMenuButton<String>(
              tooltip: 'Job actions',
              icon: const Icon(
                Icons.more_horiz_rounded,
                color: AppColors.navy,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              onSelected: _handleMenuAction,
              itemBuilder: (_) {
                if (status == 'draft') {
                  return const [
                    PopupMenuItem(
                      value: 'edit',
                      child: _MenuRow(
                        icon: Icons.edit_outlined,
                        label: 'Edit Draft',
                      ),
                    ),
                    PopupMenuItem(
                      value: 'publish',
                      child: _MenuRow(
                        icon: Icons.public_rounded,
                        label: 'Publish Job',
                      ),
                    ),
                    PopupMenuDivider(),
                    PopupMenuItem(
                      value: 'delete',
                      child: _MenuRow(
                        icon: Icons.delete_outline_rounded,
                        label: 'Delete Draft',
                        danger: true,
                      ),
                    ),
                  ];
                }

                return const [
                  PopupMenuItem(
                    value: 'close',
                    child: _MenuRow(
                      icon: Icons.lock_clock_outlined,
                      label: 'Close Applications',
                    ),
                  ),
                  PopupMenuDivider(),
                  PopupMenuItem(
                    value: 'cancel',
                    child: _MenuRow(
                      icon: Icons.cancel_outlined,
                      label: 'Cancel Job',
                      danger: true,
                    ),
                  ),
                ];
              },
            )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _hero(_JobDetailSnapshot job) {
    final visual = _statusVisual(job.status);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF102A3A),
            Color(0xFF0C4655),
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
                label: _pretty(job.status),
                foreground: visual.foreground,
                background: visual.background,
              ),
              const Spacer(),
              Text(
                '#${job.id}',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.62),
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 17),
          Text(
            job.title.isEmpty ? 'Untitled Job' : job.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w900,
              height: 1.25,
            ),
          ),
          if (job.serviceCategory.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              _pretty(job.serviceCategory),
              style: TextStyle(
                color: Colors.white.withOpacity(0.68),
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  _payment(job),
                  style: const TextStyle(
                    color: Color(0xFF83E2C4),
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              if (_networkRefreshing)
                const _SyncPill(label: 'Updating'),
            ],
          ),
          const SizedBox(height: 15),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _HeroMiniPill(
                icon: Icons.location_on_outlined,
                text: _location(job),
              ),
              _HeroMiniPill(
                icon: Icons.calendar_today_outlined,
                text: _dateRange(job),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _overview(_JobDetailSnapshot job) {
    return _section(
      icon: Icons.dashboard_customize_outlined,
      title: 'Job Overview',
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _OverviewTile(
                  icon: Icons.event_available_outlined,
                  label: 'Start',
                  value: _formatDate(job.startDate),
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: _OverviewTile(
                  icon: Icons.event_busy_outlined,
                  label: 'End',
                  value: _formatDate(job.endDate),
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          Row(
            children: [
              Expanded(
                child: _OverviewTile(
                  icon: Icons.flight_outlined,
                  label: 'Drone',
                  value: job.droneSize.isEmpty
                      ? 'Not specified'
                      : _pretty(job.droneSize),
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: _OverviewTile(
                  icon: Icons.workspace_premium_outlined,
                  label: 'Experience',
                  value: job.requiredExperience.isEmpty
                      ? 'Not specified'
                      : job.requiredExperience,
                ),
              ),
            ],
          ),
          if (job.publishedAt != null || job.createdAt != null) ...[
            const SizedBox(height: 12),
            const Divider(height: 1, color: AppColors.cardBorder),
            const SizedBox(height: 11),
            if (job.publishedAt != null)
              _compactInfoRow(
                Icons.public_rounded,
                'Published',
                _formatDateTime(job.publishedAt),
              ),
            if (job.createdAt != null)
              _compactInfoRow(
                Icons.schedule_rounded,
                'Created',
                _formatDateTime(job.createdAt),
              ),
          ],
        ],
      ),
    );
  }

  Widget _managementSection(_JobDetailSnapshot job) {
    final status = job.status.toLowerCase();

    String title;
    String subtitle;
    IconData icon;

    switch (status) {
      case 'draft':
        title = 'Draft Management';
        subtitle = 'Edit, publish or permanently remove this draft.';
        icon = Icons.edit_note_rounded;
        break;
      case 'published':
        title = 'Published Job';
        subtitle = 'Close new applications or cancel the job.';
        icon = Icons.public_rounded;
        break;
      case 'closed':
        title = 'Job Closed';
        subtitle = 'New applications are closed. Existing applicants remain.';
        icon = Icons.lock_outline_rounded;
        break;
      case 'cancelled':
        title = 'Job Cancelled';
        subtitle = 'This job stays in your history and cannot be reopened.';
        icon = Icons.cancel_outlined;
        break;
      default:
        title = 'Job Management';
        subtitle = 'Management options follow the current job status.';
        icon = Icons.tune_rounded;
    }

    final canAct = _hasLiveJob && !_networkRefreshing && !_actionLoading;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withOpacity(0.025),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: status == 'cancelled'
                      ? Colors.red.shade50
                      : AppColors.blueBg,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  icon,
                  color: status == 'cancelled'
                      ? Colors.red.shade700
                      : AppColors.blue,
                  size: 20,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppColors.navy,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: AppColors.grey,
                        fontSize: 11.5,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_actionLoading || !_hasLiveJob) ...[
            const SizedBox(height: 13),
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: const LinearProgressIndicator(
                minHeight: 3,
                backgroundColor: AppColors.blueBg,
                color: AppColors.blue,
              ),
            ),
            if (!_hasLiveJob) ...[
              const SizedBox(height: 7),
              const Text(
                'Showing saved data while the latest job state syncs.',
                style: TextStyle(
                  color: AppColors.grey,
                  fontSize: 10.8,
                ),
              ),
            ],
          ],
          if (status == 'draft') ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    icon: Icons.edit_outlined,
                    label: 'Edit',
                    onTap: canAct ? _edit : null,
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: _ActionButton(
                    icon: Icons.public_rounded,
                    label: 'Publish',
                    primary: true,
                    onTap: canAct ? _publish : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 9),
            SizedBox(
              width: double.infinity,
              child: _ActionButton(
                icon: Icons.delete_outline_rounded,
                label: 'Delete Draft',
                danger: true,
                onTap: canAct ? _delete : null,
              ),
            ),
          ] else if (status == 'published') ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    icon: Icons.lock_clock_outlined,
                    label: 'Close',
                    onTap: canAct ? _closeJob : null,
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: _ActionButton(
                    icon: Icons.cancel_outlined,
                    label: 'Cancel',
                    danger: true,
                    onTap: canAct ? _cancelJob : null,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _requirements(_JobDetailSnapshot job) {
    final hasAnything =
        job.requiredCapabilities.isNotEmpty ||
            job.requiredCertifications.isNotEmpty ||
            job.trainingSafetyRequired ||
            job.ndaRequired ||
            job.requirementsNotes.isNotEmpty;

    return _section(
      icon: Icons.fact_check_outlined,
      title: 'Requirements',
      child: hasAnything
          ? Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (job.requiredCapabilities.isNotEmpty) ...[
            const _SubLabel('Required capabilities'),
            const SizedBox(height: 8),
            _chipWrap(
              job.requiredCapabilities,
              AppColors.greenBg,
              AppColors.green,
            ),
            const SizedBox(height: 14),
          ],
          if (job.requiredCertifications.isNotEmpty) ...[
            const _SubLabel('Required certifications'),
            const SizedBox(height: 8),
            _chipWrap(
              job.requiredCertifications,
              AppColors.blueBg,
              AppColors.blue,
            ),
            const SizedBox(height: 14),
          ],
          if (job.trainingSafetyRequired)
            _requirementLine(
              Icons.health_and_safety_outlined,
              'Safety training required',
            ),
          if (job.ndaRequired)
            _requirementLine(
              Icons.lock_outline_rounded,
              'NDA required',
            ),
          if (job.requirementsNotes.isNotEmpty) ...[
            const SizedBox(height: 7),
            const _SubLabel('Other requirements'),
            const SizedBox(height: 6),
            Text(
              job.requirementsNotes,
              style: const TextStyle(
                color: AppColors.text,
                fontSize: 12.5,
                height: 1.5,
              ),
            ),
          ],
        ],
      )
          : const Text(
        'No additional requirements.',
        style: TextStyle(
          color: AppColors.grey,
          fontSize: 12.5,
        ),
      ),
    );
  }

  Widget _attachments(_JobDetailSnapshot job) {
    return _section(
      icon: Icons.attach_file_rounded,
      title: 'Attachments (${job.attachments.length})',
      child: Column(
        children: job.attachments.map((attachment) {
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: AppColors.bg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.blueBg,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(
                    attachment.isImage
                        ? Icons.image_outlined
                        : Icons.insert_drive_file_outlined,
                    color: AppColors.blue,
                    size: 19,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        attachment.name.isEmpty
                            ? 'Attachment'
                            : attachment.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.navy,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _fileSize(attachment.size),
                        style: const TextStyle(
                          color: AppColors.grey,
                          fontSize: 10.8,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _companyCard(_CompanySnapshot company) {
    final name = company.companyName.isEmpty
        ? 'Company #${company.id}'
        : company.companyName;

    return _section(
      icon: Icons.business_rounded,
      title: 'Company',
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.blue, Color(0xFF0D8AA5)],
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              _initials(name),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: AppColors.navy,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (company.industryType.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    company.industryType,
                    style: const TextStyle(
                      color: AppColors.grey,
                      fontSize: 11.5,
                    ),
                  ),
                ],
                if (company.address.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        color: AppColors.blue,
                        size: 14,
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          company.address,
                          style: const TextStyle(
                            color: AppColors.text,
                            fontSize: 11.8,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _applicationsSection() {
    final pendingCount =
        _applicants.where((item) => item.status == 'pending').length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Applications',
              style: TextStyle(
                color: AppColors.navy,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(width: 8),
            _CountBadge(
              text: '${_applicants.length}',
              foreground: AppColors.blue,
              background: AppColors.blueBg,
            ),
            if (pendingCount > 0) ...[
              const SizedBox(width: 7),
              _CountBadge(
                text: '$pendingCount pending',
                foreground: AppColors.orange,
                background: AppColors.orangeBg,
              ),
            ],
            const Spacer(),
            if (_applicantsRefreshing) const _SyncPill(label: 'Syncing'),
          ],
        ),
        const SizedBox(height: 5),
        const Text(
          'Review pilot profile, drone and message before deciding.',
          style: TextStyle(
            color: AppColors.grey,
            fontSize: 11.3,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 11),
        if (_applicants.isNotEmpty)
          ..._sortedApplicants(_applicants).map(
                (application) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _ApplicantCardSnapshot(
                application: application,
                onTap: () => _openApplicant(application),
              ),
            ),
          )
        else if (_applicantsRefreshing)
          const _ApplicantsShimmer()
        else if (_applicantsError != null)
            _applicationsError(_applicantsError!)
          else
            const _EmptyApplications(),
      ],
    );
  }

  List<_ApplicantSnapshot> _sortedApplicants(
      List<_ApplicantSnapshot> values,
      ) {
    final result = List<_ApplicantSnapshot>.from(values);

    int rank(_ApplicantSnapshot value) {
      switch (value.status) {
        case 'pending':
          return 0;
        case 'accepted':
          return 1;
        case 'rejected':
          return 2;
        case 'withdrawn':
          return 3;
        default:
          return 4;
      }
    }

    result.sort((a, b) {
      final status = rank(a).compareTo(rank(b));
      if (status != 0) return status;
      final aDate = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bDate = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bDate.compareTo(aDate);
    });

    return result;
  }

  Widget _applicationsError(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.cloud_off_rounded,
            color: AppColors.grey,
            size: 20,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              message,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.grey,
                fontSize: 11.5,
              ),
            ),
          ),
          TextButton(
            onPressed: _refreshApplicantsFromNetwork,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _section({
    required IconData icon,
    required String title,
    required Widget child,
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
                  color: AppColors.blueBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: AppColors.blue,
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

  Widget _compactInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 15, color: AppColors.blue),
          const SizedBox(width: 7),
          SizedBox(
            width: 74,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.grey,
                fontSize: 11.3,
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
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _requirementLine(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AppColors.greenBg,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, color: AppColors.green, size: 14),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AppColors.navy,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chipWrap(
      List<String> items,
      Color background,
      Color foreground,
      ) {
    return Wrap(
      spacing: 7,
      runSpacing: 7,
      children: items
          .map(
            (item) => Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 9,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            item,
            style: TextStyle(
              color: foreground,
              fontSize: 10.8,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      )
          .toList(),
    );
  }

  String _location(_JobDetailSnapshot job) {
    final parts = <String>[
      if (job.region.isNotEmpty) job.region,
      if (job.city.isNotEmpty) job.city,
      if (job.state.isNotEmpty) job.state,
      if (job.country.isNotEmpty) job.country,
    ];

    final unique = <String>[];
    for (final value in parts) {
      if (!unique.contains(value)) unique.add(value);
    }

    return unique.isEmpty ? 'Location not specified' : unique.join(', ');
  }

  String _dateRange(_JobDetailSnapshot job) {
    final start = _formatDate(job.startDate);
    final end = _formatDate(job.endDate);
    if (start == '—' && end == '—') return 'Date not specified';
    if (end == '—' || start == end) return start;
    return '$start → $end';
  }

  String _payment(_JobDetailSnapshot job) {
    if (job.paymentType.toLowerCase() == 'negotiable') {
      return 'Negotiable';
    }

    final type = _pretty(job.paymentType);
    final min = _money(job.paymentMin);
    final max = _money(job.paymentMax);

    if (job.paymentMin == null && job.paymentMax == null) {
      return type.isEmpty ? 'Payment not specified' : type;
    }
    if (job.paymentMax == null || job.paymentMax == job.paymentMin) {
      return type.isEmpty ? '\$$min' : '$type · \$$min';
    }
    return type.isEmpty
        ? '\$$min - \$$max'
        : '$type · \$$min - \$$max';
  }

  String _money(double? value) {
    if (value == null) return '';
    if (value == value.roundToDouble()) return value.toStringAsFixed(0);
    return value.toStringAsFixed(2);
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '—';
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  String _formatDateTime(DateTime? date) {
    if (date == null) return '—';
    final local = date.toLocal();
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '${_formatDate(local)} · $hour:$minute';
  }

  String _fileSize(int bytes) {
    if (bytes <= 0) return 'Size unavailable';
    if (bytes < 1024) return '$bytes B';
    final kb = bytes / 1024;
    if (kb < 1024) {
      return '${kb.toStringAsFixed(kb >= 100 ? 0 : 1)} KB';
    }
    final mb = kb / 1024;
    return '${mb.toStringAsFixed(mb >= 100 ? 0 : 1)} MB';
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

class _JobDetailSnapshot {
  const _JobDetailSnapshot({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.serviceCategory,
    required this.country,
    required this.state,
    required this.city,
    required this.region,
    required this.startDate,
    required this.endDate,
    required this.paymentType,
    required this.paymentMin,
    required this.paymentMax,
    required this.requiredCapabilities,
    required this.requiredCertifications,
    required this.requiredExperience,
    required this.droneSize,
    required this.trainingSafetyRequired,
    required this.ndaRequired,
    required this.requirementsNotes,
    required this.publishedAt,
    required this.createdAt,
    required this.attachments,
    required this.company,
  });

  final int id;
  final String title;
  final String description;
  final String status;
  final String serviceCategory;
  final String country;
  final String state;
  final String city;
  final String region;
  final DateTime? startDate;
  final DateTime? endDate;
  final String paymentType;
  final double? paymentMin;
  final double? paymentMax;
  final List<String> requiredCapabilities;
  final List<String> requiredCertifications;
  final String requiredExperience;
  final String droneSize;
  final bool trainingSafetyRequired;
  final bool ndaRequired;
  final String requirementsNotes;
  final DateTime? publishedAt;
  final DateTime? createdAt;
  final List<_AttachmentSnapshot> attachments;
  final _CompanySnapshot? company;

  factory _JobDetailSnapshot.fromModel(CompanyJobPostingModel job) {
    return _JobDetailSnapshot(
      id: job.id,
      title: job.title,
      description: job.description,
      status: job.status,
      serviceCategory: job.serviceCategory,
      country: job.country,
      state: job.state,
      city: job.city,
      region: job.region,
      startDate: job.startDate,
      endDate: job.endDate,
      paymentType: job.paymentType,
      paymentMin: job.paymentMin,
      paymentMax: job.paymentMax,
      requiredCapabilities: List<String>.from(job.requiredCapabilities),
      requiredCertifications:
      List<String>.from(job.requiredCertifications),
      requiredExperience: job.requiredExperience,
      droneSize: job.droneSize,
      trainingSafetyRequired: job.trainingSafetyRequired,
      ndaRequired: job.ndaRequired,
      requirementsNotes: job.requirementsNotes,
      publishedAt: job.publishedAt,
      createdAt: job.createdAt,
      attachments: job.attachments
          .map(_AttachmentSnapshot.fromModel)
          .toList(growable: false),
      company: job.companyProfile == null
          ? null
          : _CompanySnapshot.fromModel(job.companyProfile!),
    );
  }

  factory _JobDetailSnapshot.fromJson(Map<String, dynamic> json) {
    final capabilities = _stringList(json['required_capabilities']);
    final certifications = _stringList(json['required_certifications']);

    final attachments = <_AttachmentSnapshot>[];
    final rawAttachments = json['attachments'];
    if (rawAttachments is List) {
      for (final raw in rawAttachments) {
        if (raw is Map) {
          attachments.add(
            _AttachmentSnapshot.fromJson(Map<String, dynamic>.from(raw)),
          );
        }
      }
    }

    _CompanySnapshot? company;
    final rawCompany = json['company'];
    if (rawCompany is Map) {
      company = _CompanySnapshot.fromJson(
        Map<String, dynamic>.from(rawCompany),
      );
    }

    return _JobDetailSnapshot(
      id: _asInt(json['id']),
      title: _asString(json['title']),
      description: _asString(json['description']),
      status: _asString(json['status']),
      serviceCategory: _asString(json['service_category']),
      country: _asString(json['country']),
      state: _asString(json['state']),
      city: _asString(json['city']),
      region: _asString(json['region']),
      startDate: _asDate(json['start_date']),
      endDate: _asDate(json['end_date']),
      paymentType: _asString(json['payment_type']),
      paymentMin: _asDouble(json['payment_min']),
      paymentMax: _asDouble(json['payment_max']),
      requiredCapabilities: capabilities,
      requiredCertifications: certifications,
      requiredExperience: _asString(json['required_experience']),
      droneSize: _asString(json['drone_size']),
      trainingSafetyRequired: _asBool(json['training_safety_required']),
      ndaRequired: _asBool(json['nda_required']),
      requirementsNotes: _asString(json['requirements_notes']),
      publishedAt: _asDate(json['published_at']),
      createdAt: _asDate(json['created_at']),
      attachments: attachments,
      company: company,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'status': status,
      'service_category': serviceCategory,
      'country': country,
      'state': state,
      'city': city,
      'region': region,
      'start_date': startDate?.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'payment_type': paymentType,
      'payment_min': paymentMin,
      'payment_max': paymentMax,
      'required_capabilities': requiredCapabilities,
      'required_certifications': requiredCertifications,
      'required_experience': requiredExperience,
      'drone_size': droneSize,
      'training_safety_required': trainingSafetyRequired,
      'nda_required': ndaRequired,
      'requirements_notes': requirementsNotes,
      'published_at': publishedAt?.toIso8601String(),
      'created_at': createdAt?.toIso8601String(),
      'attachments': attachments.map((item) => item.toJson()).toList(),
      'company': company?.toJson(),
    };
  }
}

class _AttachmentSnapshot {
  const _AttachmentSnapshot({
    required this.name,
    required this.size,
    required this.isImage,
  });

  final String name;
  final int size;
  final bool isImage;

  factory _AttachmentSnapshot.fromModel(dynamic attachment) {
    return _AttachmentSnapshot(
      name: attachment.name?.toString() ?? '',
      size: _asInt(attachment.size),
      isImage: attachment.isImage == true,
    );
  }

  factory _AttachmentSnapshot.fromJson(Map<String, dynamic> json) {
    return _AttachmentSnapshot(
      name: _asString(json['name']),
      size: _asInt(json['size']),
      isImage: _asBool(json['is_image']),
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'size': size,
    'is_image': isImage,
  };
}

class _CompanySnapshot {
  const _CompanySnapshot({
    required this.id,
    required this.companyName,
    required this.industryType,
    required this.address,
  });

  final int id;
  final String companyName;
  final String industryType;
  final String address;

  factory _CompanySnapshot.fromModel(CompanyJobCompanyProfileModel company) {
    return _CompanySnapshot(
      id: company.id,
      companyName: company.companyName,
      industryType: company.industryType,
      address: company.address,
    );
  }

  factory _CompanySnapshot.fromJson(Map<String, dynamic> json) {
    return _CompanySnapshot(
      id: _asInt(json['id']),
      companyName: _asString(json['company_name']),
      industryType: _asString(json['industry_type']),
      address: _asString(json['address']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'company_name': companyName,
    'industry_type': industryType,
    'address': address,
  };
}

class _ApplicantSnapshot {
  const _ApplicantSnapshot({
    required this.id,
    required this.pilotProfileId,
    required this.droneId,
    required this.status,
    required this.statusLabel,
    required this.coverMessage,
    required this.pilotName,
    required this.pilotPhoto,
    required this.pilotLocation,
    required this.experienceYears,
    required this.droneName,
    required this.createdAt,
  });

  final int id;
  final int pilotProfileId;
  final int droneId;
  final String status;
  final String statusLabel;
  final String coverMessage;
  final String pilotName;
  final String pilotPhoto;
  final String pilotLocation;
  final int? experienceYears;
  final String droneName;
  final DateTime? createdAt;

  factory _ApplicantSnapshot.fromModel(CompanyJobApplicationModel application) {
    final pilot = application.pilotProfile;
    final drone = application.drone;

    return _ApplicantSnapshot(
      id: application.id,
      pilotProfileId: application.pilotProfileId,
      droneId: application.droneId,
      status: application.status.trim().toLowerCase(),
      statusLabel: application.statusLabel,
      coverMessage: application.coverMessage,
      pilotName: pilot?.displayName ?? '',
      pilotPhoto: pilot?.profilePhoto ?? '',
      pilotLocation: pilot?.location ?? '',
      experienceYears: pilot?.experienceYears,
      droneName: drone?.displayName ?? '',
      createdAt: application.createdAt,
    );
  }

  factory _ApplicantSnapshot.fromJson(Map<String, dynamic> json) {
    return _ApplicantSnapshot(
      id: _asInt(json['id']),
      pilotProfileId: _asInt(json['pilot_profile_id']),
      droneId: _asInt(json['drone_id']),
      status: _asString(json['status']).toLowerCase(),
      statusLabel: _asString(json['status_label']),
      coverMessage: _asString(json['cover_message']),
      pilotName: _asString(json['pilot_name']),
      pilotPhoto: _asString(json['pilot_photo']),
      pilotLocation: _asString(json['pilot_location']),
      experienceYears: _asNullableInt(json['experience_years']),
      droneName: _asString(json['drone_name']),
      createdAt: _asDate(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'pilot_profile_id': pilotProfileId,
    'drone_id': droneId,
    'status': status,
    'status_label': statusLabel,
    'cover_message': coverMessage,
    'pilot_name': pilotName,
    'pilot_photo': pilotPhoto,
    'pilot_location': pilotLocation,
    'experience_years': experienceYears,
    'drone_name': droneName,
    'created_at': createdAt?.toIso8601String(),
  };
}

class _ApplicantCardSnapshot extends StatelessWidget {
  const _ApplicantCardSnapshot({
    required this.application,
    required this.onTap,
  });

  final _ApplicantSnapshot application;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final name = application.pilotName.trim().isEmpty
        ? 'Pilot #${application.pilotProfileId}'
        : application.pilotName.trim();
    final visual = _applicationVisual(application.status);

    final subtitleParts = <String>[];
    if (application.pilotLocation.isNotEmpty) {
      subtitleParts.add(application.pilotLocation);
    }
    if (application.experienceYears != null) {
      subtitleParts.add('${application.experienceYears} yrs exp');
    }

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.cardBorder),
            boxShadow: [
              BoxShadow(
                color: AppColors.navy.withOpacity(0.022),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: AppColors.blueBg,
                    foregroundImage: application.pilotPhoto.trim().isNotEmpty
                        ? NetworkImage(application.pilotPhoto.trim())
                        : null,
                    child: application.pilotPhoto.trim().isEmpty
                        ? Text(
                      _initials(name),
                      style: const TextStyle(
                        color: AppColors.blue,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    )
                        : null,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.navy,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          subtitleParts.isEmpty
                              ? 'Application #${application.id}'
                              : subtitleParts.join(' · '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.grey,
                            fontSize: 11.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _StatusBadge(
                    label: application.statusLabel.isEmpty
                        ? _titleCase(application.status)
                        : application.statusLabel,
                    foreground: visual.foreground,
                    background: visual.background,
                  ),
                ],
              ),
              if (application.coverMessage.isNotEmpty) ...[
                const SizedBox(height: 11),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(11),
                  decoration: BoxDecoration(
                    color: AppColors.bg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    application.coverMessage,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.text,
                      fontSize: 11.7,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(
                    Icons.flight_outlined,
                    size: 14,
                    color: AppColors.grey,
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      application.droneName.isEmpty
                          ? 'Drone #${application.droneId}'
                          : application.droneName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.grey,
                        fontSize: 11.2,
                      ),
                    ),
                  ),
                  const Text(
                    'Open',
                    style: TextStyle(
                      color: AppColors.blue,
                      fontSize: 10.8,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 17,
                    color: AppColors.blue,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OverviewTile extends StatelessWidget {
  const _OverviewTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 86),
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppColors.blue),
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

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.primary = false,
    this.danger = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool primary;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    if (primary) {
      return FilledButton.icon(
        onPressed: onTap,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.blue,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.blue.withOpacity(0.35),
          minimumSize: const Size.fromHeight(44),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(13),
          ),
        ),
        icon: Icon(icon, size: 17),
        label: Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      );
    }

    return OutlinedButton.icon(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: danger ? Colors.red.shade700 : AppColors.navy,
        backgroundColor: Colors.white,
        side: BorderSide(
          color: danger
              ? Colors.red.withOpacity(0.22)
              : AppColors.cardBorder,
        ),
        minimumSize: const Size.fromHeight(44),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(13),
        ),
      ),
      icon: Icon(icon, size: 17),
      label: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({
    required this.icon,
    required this.label,
    this.danger = false,
  });

  final IconData icon;
  final String label;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final color = danger ? Colors.red.shade700 : AppColors.navy;
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 9),
        Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
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

class _CountBadge extends StatelessWidget {
  const _CountBadge({
    required this.text,
    required this.foreground,
    required this.background,
  });

  final String text;
  final Color foreground;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: foreground,
          fontSize: 10.2,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _HeroMiniPill extends StatelessWidget {
  const _HeroMiniPill({
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 245),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.10)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: Colors.white70),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SyncPill extends StatelessWidget {
  const _SyncPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.blueBg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const _TinyPulse(),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.blue,
              fontSize: 9.8,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(
            icon,
            size: 17,
            color: onTap == null ? AppColors.lightGrey : AppColors.navy,
          ),
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

class _EmptyApplications extends StatelessWidget {
  const _EmptyApplications();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.people_outline_rounded,
            color: AppColors.lightGrey,
            size: 32,
          ),
          SizedBox(height: 8),
          Text(
            'No applications yet',
            style: TextStyle(
              color: AppColors.navy,
              fontSize: 13.5,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Pilot applications for this job will appear here.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.grey,
              fontSize: 11.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: AppColors.blueBg,
                borderRadius: BorderRadius.circular(19),
              ),
              child: const Icon(
                Icons.cloud_off_rounded,
                color: AppColors.blue,
                size: 27,
              ),
            ),
            const SizedBox(height: 13),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.grey,
                fontSize: 12.5,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 15),
            FilledButton(
              onPressed: onRetry,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.blue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}

class _BackgroundGlow extends StatelessWidget {
  const _BackgroundGlow();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: -170,
          right: -130,
          child: IgnorePointer(
            child: Container(
              width: 330,
              height: 330,
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
          top: 500,
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

class _JobDetailsPageShimmer extends StatelessWidget {
  const _JobDetailsPageShimmer();

  @override
  Widget build(BuildContext context) {
    return _ShimmerAnimator(
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: const [
          Row(
            children: [
              _ShimmerBox(width: 44, height: 44, radius: 22),
              Spacer(),
              _ShimmerBox(width: 112, height: 15, radius: 8),
              Spacer(),
              _ShimmerBox(width: 44, height: 44, radius: 22),
            ],
          ),
          SizedBox(height: 12),
          _HeroShimmer(),
          SizedBox(height: 12),
          _SectionShimmer(rows: 4),
          SizedBox(height: 12),
          _SectionShimmer(rows: 2),
          SizedBox(height: 12),
          _SectionShimmer(rows: 3),
          SizedBox(height: 18),
          _ShimmerBox(width: 120, height: 14, radius: 7),
          SizedBox(height: 11),
          _ApplicantCardShimmer(),
          SizedBox(height: 10),
          _ApplicantCardShimmer(),
        ],
      ),
    );
  }
}

class _HeroShimmer extends StatelessWidget {
  const _HeroShimmer();

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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _ShimmerBox(width: 76, height: 24, radius: 12),
              Spacer(),
              _ShimmerBox(width: 32, height: 12, radius: 6),
            ],
          ),
          SizedBox(height: 24),
          _ShimmerBox(width: 230, height: 16, radius: 8),
          SizedBox(height: 9),
          _ShimmerBox(width: 125, height: 11, radius: 6),
          Spacer(),
          _ShimmerBox(width: 150, height: 16, radius: 8),
          SizedBox(height: 14),
          Row(
            children: [
              _ShimmerBox(width: 130, height: 28, radius: 12),
              SizedBox(width: 8),
              _ShimmerBox(width: 150, height: 28, radius: 12),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionShimmer extends StatelessWidget {
  const _SectionShimmer({required this.rows});

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
              _ShimmerBox(width: 126, height: 14, radius: 7),
            ],
          ),
          const SizedBox(height: 14),
          ...List.generate(
            rows,
                (index) => const Padding(
              padding: EdgeInsets.only(bottom: 9),
              child: _ShimmerBox(height: 34, radius: 10),
            ),
          ),
        ],
      ),
    );
  }
}

class _ApplicantsShimmer extends StatelessWidget {
  const _ApplicantsShimmer();

  @override
  Widget build(BuildContext context) {
    return const _ShimmerAnimator(
      child: Column(
        children: [
          _ApplicantCardShimmer(),
          SizedBox(height: 10),
          _ApplicantCardShimmer(),
        ],
      ),
    );
  }
}

class _ApplicantCardShimmer extends StatelessWidget {
  const _ApplicantCardShimmer();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _ShimmerBox(width: 44, height: 44, radius: 22),
              SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ShimmerBox(width: 130, height: 12, radius: 6),
                    SizedBox(height: 7),
                    _ShimmerBox(width: 100, height: 9, radius: 5),
                  ],
                ),
              ),
              _ShimmerBox(width: 58, height: 24, radius: 12),
            ],
          ),
          SizedBox(height: 12),
          _ShimmerBox(height: 42, radius: 12),
          SizedBox(height: 10),
          _ShimmerBox(width: 170, height: 10, radius: 5),
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
        decoration: const BoxDecoration(
          color: AppColors.blue,
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

_VisualPair _statusVisual(String status) {
  switch (status.trim().toLowerCase()) {
    case 'published':
      return const _VisualPair(AppColors.green, AppColors.greenBg);
    case 'draft':
      return const _VisualPair(AppColors.orange, AppColors.orangeBg);
    case 'cancelled':
      return _VisualPair(Colors.red.shade700, Colors.red.shade50);
    case 'closed':
      return _VisualPair(AppColors.grey, Colors.grey.shade100);
    default:
      return const _VisualPair(AppColors.grey, AppColors.blueBg);
  }
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

bool _asBool(dynamic value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  final text = value?.toString().trim().toLowerCase() ?? '';
  return text == 'true' || text == '1' || text == 'yes';
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

String _titleCase(String value) {
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

  if (parts.isEmpty) return 'C';
  if (parts.length == 1) return parts.first[0].toUpperCase();
  return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
}
