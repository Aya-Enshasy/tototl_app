import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:tototl_app/core/localization/app_language.dart';

import '../../../../core/navigation/company_shell_screen.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/storage/user_session_storage.dart';
import '../../../../core/theme/app_colors.dart';

import '../../controllers/company_job_controller.dart';
import '../../models/company_job_application_model.dart';
import '../../models/company_job_posting_model.dart';
import '../../services/company_job_service.dart';

import '../applications/company_applicant_detail_screen.dart';
import 'edit_company_job_screen.dart';

class CompanyJobDetailScreen extends StatefulWidget {
  const CompanyJobDetailScreen({super.key, required this.jobId});

  final int jobId;

  @override
  State<CompanyJobDetailScreen> createState() => _CompanyJobDetailScreenState();
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

  String _companyPhotoUrl = '';

  bool get _hasCachedOrLiveData => _job != null;
  bool get _hasLiveJob => _controller.selectedJob != null;

  @override
  void initState() {
    super.initState();

    _controller = CompanyJobController(CompanyJobService(ApiClient()));

    unawaited(_bootstrap());
  }

  Future<void> _bootstrap() async {
    await Future.wait<void>([
      _loadCache(),
      _loadCompanyPhoto(),
    ]);
    if (!mounted) return;
    unawaited(_refreshFromNetwork(initial: true));
  }

  Future<void> _loadCompanyPhoto() async {
    try {
      final profile = await UserSessionStorage.getProfile();
      final storedPhoto = await UserSessionStorage.getProfilePhotoUrl();

      final candidates = <String>[
        profile?['profile_photo']?.toString().trim() ?? '',
        profile?['profile_photo_url']?.toString().trim() ?? '',
        profile?['company_logo']?.toString().trim() ?? '',
        profile?['company_logo_url']?.toString().trim() ?? '',
        storedPhoto?.trim() ?? '',
      ];

      final photo = candidates.firstWhere(
            (value) => value.isNotEmpty,
        orElse: () => '',
      );

      if (!mounted) return;
      setState(() => _companyPhotoUrl = photo);
    } catch (_) {
      // Keep the company initials fallback if no stored image is available.
    }
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
              _ApplicantSnapshot.fromJson(Map<String, dynamic>.from(value)),
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
      await _storage.write(key: key, value: jsonEncode(payload));
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
      final detailSuccess = await _controller.loadJobDetails(widget.jobId);

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

      final freshJob = _JobDetailSnapshot.fromModel(_controller.selectedJob!);

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
      MaterialPageRoute(builder: (_) => EditCompanyJobScreen(job: job)),
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
      title: AppLanguage.text('Publish Job?'),
      message: AppLanguage.text(
        'Once published, pilots can see this job and submit applications. Editing and deleting are only available while the job is Draft.',
      ),
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
      title: AppLanguage.text('Delete Draft?'),
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
      title: AppLanguage.text('Close Applications?'),
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
          title: Text(
            AppLanguage.text('Cancel Job?'),
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
                  hintText: AppLanguage.text('Reason (optional)'),
                  filled: true,
                  fillColor: AppColors.bg,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.cardBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.cardBorder),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(AppLanguage.text('Keep Job')),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.of(dialogContext).pop(draftReason.trim()),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red.shade700,
              ),
              child: Text(AppLanguage.text('Cancel Job')),
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

    final cancelled = await _controller.cancelJob(job.id, reason: reason);

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
              child: Text(AppLanguage.text('Cancel')),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: danger ? Colors.red.shade700 : AppColors.blue,
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
      backgroundColor: const Color(0xFFF9FCFD),
      body: SafeArea(
        bottom: false,
        child: _showInitialShimmer
            ? const _ReferenceJobDetailsShimmer()
            : _job == null
            ? _ErrorView(
          message: _pageError ?? 'Unable to load job details.',
          onRetry: () => _refreshFromNetwork(),
        )
            : _buildReferenceContent(),
      ),
    );
  }

  void _openShellTab(int index) {
    HapticFeedback.selectionClick();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => CompanyShellScreen(initialIndex: index),
      ),
          (route) => false,
    );
  }

  Widget _buildReferenceContent() {
    final job = _job!;

    return Column(
      children: [
        _referenceTopBar(job),
        Expanded(
          child: RefreshIndicator(
            color: const Color(0xFF149FB1),
            backgroundColor: Colors.white,
            onRefresh: _manualRefresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 26),
              children: [
                _referenceJobHeader(job),
                const SizedBox(height: 14),
                _referenceRequirements(job),
                const SizedBox(height: 10),
                _referenceDescription(job),
                const SizedBox(height: 10),
                _referenceApplications(),
                const SizedBox(height: 14),
                _referenceActions(job),
                if (_networkRefreshing) ...[
                  const SizedBox(height: 10),
                  const LinearProgressIndicator(
                    minHeight: 2,
                    color: Color(0xFF19A9B8),
                    backgroundColor: Color(0xFFEAF1F3),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _referenceTopBar(_JobDetailSnapshot job) {
    final status = job.status.toLowerCase();
    final showMenu = _hasLiveJob && !_actionLoading &&
        (status == 'draft' || status == 'published');

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
      child: SizedBox(
        height: 42,
        child: Row(
          children: [
            SizedBox(
              width: 34,
              height: 34,
              child: IconButton(
                padding: EdgeInsets.zero,
                splashRadius: 20,
                onPressed: _actionLoading ? null : () => Navigator.of(context).pop(),
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 18,
                  color: _ReferenceJobPalette.navy,
                ),
              ),
            ),
            Expanded(
              child: Text(
                AppLanguage.text('Job Details'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: _ReferenceJobPalette.navy,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -.15,
                ),
              ),
            ),
            SizedBox(
              width: 34,
              height: 34,
              child: showMenu
                  ? PopupMenuButton<String>(
                padding: EdgeInsets.zero,
                tooltip: 'Job actions',
                icon: const Icon(
                  Icons.more_horiz_rounded,
                  color: _ReferenceJobPalette.navy,
                  size: 22,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                onSelected: _handleMenuAction,
                itemBuilder: (_) {
                  if (status == 'draft') {
                    return [
                      PopupMenuItem(
                        value: 'edit',
                        child: _MenuRow(
                          icon: Icons.edit_outlined,
                          label: AppLanguage.text('Edit Draft'),
                        ),
                      ),
                      PopupMenuItem(
                        value: 'publish',
                        child: _MenuRow(
                          icon: Icons.public_rounded,
                          label: AppLanguage.text('Publish Job'),
                        ),
                      ),
                      const PopupMenuDivider(),
                      PopupMenuItem(
                        value: 'delete',
                        child: _MenuRow(
                          icon: Icons.delete_outline_rounded,
                          label: AppLanguage.text('Delete Draft'),
                          danger: true,
                        ),
                      ),
                    ];
                  }
                  return [
                    PopupMenuItem(
                      value: 'close',
                      child: _MenuRow(
                        icon: Icons.lock_clock_outlined,
                        label: AppLanguage.text('Close Applications'),
                      ),
                    ),
                    const PopupMenuDivider(),
                    PopupMenuItem(
                      value: 'cancel',
                      child: _MenuRow(
                        icon: Icons.cancel_outlined,
                        label: AppLanguage.text('Cancel Job'),
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
      ),
    );
  }

  Widget _referenceJobHeader(_JobDetailSnapshot job) {
    final visual = _statusVisual(job.status);
    final company = job.company;
    final imageUrl = (company?.imageUrl.trim().isNotEmpty ?? false)
        ? company!.imageUrl.trim()
        : _companyPhotoUrl.trim();
    final companyName = (company?.companyName.trim().isNotEmpty ?? false)
        ? company!.companyName.trim()
        : 'Company';
    final companyMeta = (company?.industryType.trim().isNotEmpty ?? false)
        ? company!.industryType.trim()
        : ((company?.address.trim().isNotEmpty ?? false)
        ? company!.address.trim()
        : 'Job owner');

    return _ReferenceSectionCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _ReferenceCompanyAvatar(
                company: company,
                name: companyName,
                fallbackImageUrl: _companyPhotoUrl,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      companyName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _ReferenceJobPalette.navy,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      companyMeta,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _ReferenceJobPalette.warmBrown,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 88,
                  height: 82,
                  color: const Color(0xFFE8F0F3),
                  child: imageUrl.isEmpty
                      ? _ReferenceCompanyImageFallback(name: companyName)
                      : Image.network(
                    imageUrl,
                    width: 88,
                    height: 82,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        _ReferenceCompanyImageFallback(name: companyName),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                job.title.isEmpty ? 'Untitled Job' : job.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: _ReferenceJobPalette.navy,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  height: 1.2,
                                  letterSpacing: -.15,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${job.serviceCategory.isEmpty ? 'Job' : _pretty(job.serviceCategory)} · #${job.id}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: _ReferenceJobPalette.muted,
                                  fontSize: 11.2,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        _ReferenceStatusPill(
                          label: _pretty(job.status),
                          foreground: visual.foreground,
                          background: visual.background,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _ReferenceImportantInfoRow(
                      icon: Icons.location_on_outlined,
                      label: 'Location',
                      value: _location(job),
                    ),
                    const SizedBox(height: 6),
                    _ReferenceImportantInfoRow(
                      icon: Icons.calendar_today_outlined,
                      label: 'Date',
                      value: _referenceDateRange(job),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            decoration: BoxDecoration(
              color: const Color(0xFFEAF9F5),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFD2F1E8)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.payments_outlined,
                  size: 18,
                  color: _ReferenceJobPalette.greenDark,
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    _referencePayment(job),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _ReferenceJobPalette.greenDark,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _referenceRequirements(_JobDetailSnapshot job) {
    final capabilities = job.requiredCapabilities;
    final certification = job.requiredCertifications.isEmpty
        ? 'Not specified'
        : job.requiredCertifications.first;
    final droneSize = job.droneSize.trim().isEmpty
        ? 'Not specified'
        : job.droneSize.trim();
    final experience = job.requiredExperience.trim().isEmpty
        ? 'Not specified'
        : job.requiredExperience.trim();

    return _ReferenceSectionCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ReferenceSectionHeader(
            icon: Icons.qr_code_2_rounded,
            title: 'Requirements',
            action: _isDraft(job) ? 'Edit' : null,
            onActionTap: _isDraft(job) ? () => _referenceEdit(job) : null,
          ),
          const SizedBox(height: 10),
          const Text(
            'Required capabilities',
            style: TextStyle(
              color: _ReferenceJobPalette.muted,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          if (capabilities.isEmpty)
            const Text(
              'No specific capabilities required',
              style: TextStyle(
                color: _ReferenceJobPalette.muted,
                fontSize: 11.2,
              ),
            )
          else
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: capabilities.take(5).map((item) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: _ReferenceJobPalette.mintSoft,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    item,
                    style: const TextStyle(
                      color: _ReferenceJobPalette.greenDark,
                      fontSize: 10.8,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              }).toList(),
            ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _ReferenceRequirementStat(
                  icon: Icons.flight_takeoff_rounded,
                  label: 'Drone size',
                  value: _pretty(droneSize),
                  valueMaxLines: 3,
                  helperText: droneSize.length > 18 ? 'Tap to view' : null,
                  onTap: () => _showValueSheet(
                    title: 'Drone size',
                    subtitle: 'Custom or long drone-size notes can be reviewed here.',
                    value: droneSize,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ReferenceRequirementStat(
                  icon: Icons.workspace_premium_outlined,
                  label: 'Experience',
                  value: experience,
                  valueMaxLines: 3,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ReferenceRequirementStat(
                  icon: Icons.badge_outlined,
                  label: 'Certification',
                  value: certification,
                  valueMaxLines: 3,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _referenceDescription(_JobDetailSnapshot job) {
    return _ReferenceSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ReferenceSectionHeader(
            icon: Icons.notes_rounded,
            title: 'Description',
            action: _isDraft(job) ? 'Edit' : null,
            onActionTap: _isDraft(job) ? () => _referenceEdit(job) : null,
          ),
          const SizedBox(height: 8),
          Text(
            job.description.isEmpty ? 'No description provided.' : job.description,
            style: const TextStyle(
              color: _ReferenceJobPalette.text,
              fontSize: 10.9,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 14),
          const Row(
            children: [
              Icon(
                Icons.attach_file_rounded,
                size: 16,
                color: _ReferenceJobPalette.teal,
              ),
              SizedBox(width: 7),
              Text(
                'Attachments',
                style: TextStyle(
                  color: _ReferenceJobPalette.navy,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          if (job.attachments.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
              decoration: BoxDecoration(
                border: Border.all(color: _ReferenceJobPalette.border),
                borderRadius: BorderRadius.circular(11),
              ),
              child: const Text(
                'No attachments',
                style: TextStyle(
                  color: _ReferenceJobPalette.muted,
                  fontSize: 10.5,
                ),
              ),
            )
          else
            Row(
              children: [
                for (var i = 0; i < job.attachments.take(2).length; i++) ...[
                  if (i > 0) const SizedBox(width: 8),
                  Expanded(
                    child: _ReferenceAttachmentTile(
                      attachment: job.attachments[i],
                      title: _attachmentDisplayName(job.attachments[i]),
                      fileSize: _fileSize(job.attachments[i].size),
                      isImagePreview: _attachmentLooksLikeImage(job.attachments[i]),
                      onTap: () => _openAttachment(job.attachments[i]),
                    ),
                  ),
                ],
              ],
            ),
        ],
      ),
    );
  }

  Widget _referenceApplications() {
    final visible = _sortedApplicants(_applicants).take(2).toList();

    return Column(
      children: [
        Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: _ReferenceJobPalette.cyanSoft,
                borderRadius: BorderRadius.circular(9),
              ),
              child: const Icon(
                Icons.people_alt_outlined,
                size: 16,
                color: _ReferenceJobPalette.teal,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'Applications',
              style: TextStyle(
                color: _ReferenceJobPalette.navy,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: _ReferenceJobPalette.cyanSoft,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${_applicants.length}',
                style: const TextStyle(
                  color: _ReferenceJobPalette.teal,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const Spacer(),
            InkWell(
              onTap: _applicants.isEmpty ? null : _showAllApplicants,
              borderRadius: BorderRadius.circular(8),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 3, vertical: 4),
                child: Text(
                  'View all',
                  style: TextStyle(
                    color: _ReferenceJobPalette.teal,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
        if (_applicantsRefreshing && _applicants.isEmpty) ...[
          const SizedBox(height: 8),
          const LinearProgressIndicator(
            minHeight: 2,
            color: _ReferenceJobPalette.teal,
            backgroundColor: _ReferenceJobPalette.cyanSoft,
          ),
        ] else if (_applicantsError != null && _applicants.isEmpty) ...[
          const SizedBox(height: 8),
          _applicationsError(_applicantsError!),
        ] else if (visible.isEmpty) ...[
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Text(
              'No applications yet',
              style: TextStyle(
                color: _ReferenceJobPalette.muted,
                fontSize: 11,
              ),
            ),
          ),
        ] else ...[
          const SizedBox(height: 8),
          ...visible.map((application) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _ReferenceApplicantCard(
              application: application,
              onTap: () => _openApplicant(application),
            ),
          )),
        ],
      ],
    );
  }

  Widget _referenceActions(_JobDetailSnapshot job) {
    final status = job.status.toLowerCase();
    final enabled = _hasLiveJob && !_actionLoading;

    if (status == 'draft') {
      return Row(
        children: [
          Expanded(
            child: _ReferenceBottomAction(
              icon: Icons.edit_outlined,
              label: 'Edit Draft',
              onTap: enabled ? () => _referenceEdit(job) : null,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _ReferenceBottomAction(
              icon: Icons.public_rounded,
              label: 'Publish Job',
              onTap: enabled ? _publish : null,
              primary: true,
            ),
          ),
        ],
      );
    }

    if (status == 'published') {
      return Row(
        children: [
          Expanded(
            child: _ReferenceBottomAction(
              icon: Icons.lock_clock_outlined,
              label: 'Close Job',
              onTap: enabled ? _closeJob : null,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _ReferenceBottomAction(
              icon: Icons.cancel_outlined,
              label: 'Cancel Job',
              danger: true,
              onTap: enabled ? _cancelJob : null,
            ),
          ),
        ],
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _ReferenceJobPalette.border),
      ),
      child: Text(
        'This job is ${_pretty(job.status)}.',
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: _ReferenceJobPalette.muted,
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  void _referenceEdit(_JobDetailSnapshot job) {
    if (job.status.toLowerCase() == 'draft') {
      unawaited(_edit());
      return;
    }
    _showSnack('Editing is available while the job is Draft.');
  }

  void _showAllApplicants() {
    if (_applicants.isEmpty) return;
    final applicants = _sortedApplicants(_applicants);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          top: false,
          child: DraggableScrollableSheet(
            expand: false,
            initialChildSize: .72,
            minChildSize: .45,
            maxChildSize: .92,
            builder: (_, controller) {
              return ListView.separated(
                controller: controller,
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                itemCount: applicants.length + 1,
                separatorBuilder: (_, index) => index == 0
                    ? const SizedBox(height: 8)
                    : const Divider(height: 1, color: _ReferenceJobPalette.line),
                itemBuilder: (_, index) {
                  if (index == 0) {
                    return const Text(
                      'Applications',
                      style: TextStyle(
                        color: _ReferenceJobPalette.navy,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    );
                  }
                  final application = applicants[index - 1];
                  return _ReferenceApplicantRow(
                    application: application,
                    onTap: () {
                      Navigator.of(sheetContext).pop();
                      unawaited(_openApplicant(application));
                    },
                  );
                },
              );
            },
          ),
        );
      },
    );
  }


  bool _isDraft(_JobDetailSnapshot job) =>
      job.status.trim().toLowerCase() == 'draft';

  Future<void> _showValueSheet({
    required String title,
    required String value,
    String? subtitle,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 46,
                    height: 5,
                    decoration: BoxDecoration(
                      color: _ReferenceJobPalette.line,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  title,
                  style: const TextStyle(
                    color: _ReferenceJobPalette.navy,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (subtitle != null && subtitle.trim().isNotEmpty) ...[
                  const SizedBox(height: 5),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: _ReferenceJobPalette.muted,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FBFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _ReferenceJobPalette.border),
                  ),
                  child: Text(
                    value.trim().isEmpty ? 'Not specified' : value,
                    style: const TextStyle(
                      color: _ReferenceJobPalette.navy,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      height: 1.45,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }


  String _attachmentDisplayName(_AttachmentSnapshot attachment) {
    final raw = attachment.name.trim().isNotEmpty ? attachment.name.trim() : attachment.url.trim();
    if (raw.isEmpty) return 'Attachment';
    if (raw.startsWith('http://') || raw.startsWith('https://')) {
      final uri = Uri.tryParse(raw);
      final last = uri?.pathSegments.isNotEmpty == true ? uri!.pathSegments.last : raw.split('/').last;
      return Uri.decodeComponent(last.isEmpty ? 'Attachment' : last);
    }
    return raw;
  }

  bool _attachmentLooksLikeImage(_AttachmentSnapshot attachment) {
    if (attachment.isImage) return true;
    final source = '${attachment.name} ${attachment.url}'.toLowerCase();
    return source.contains('.png') ||
        source.contains('.jpg') ||
        source.contains('.jpeg') ||
        source.contains('.webp') ||
        source.contains('.gif');
  }

  Future<void> _openAttachment(_AttachmentSnapshot attachment) async {
    final url = attachment.url.trim();
    if (url.isEmpty) {
      _showSnack('Attachment preview is not available yet.', isError: true);
      return;
    }

    if (_attachmentLooksLikeImage(attachment)) {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) {
          return Dialog(
            insetPadding: const EdgeInsets.all(16),
            backgroundColor: Colors.black,
            child: Stack(
              children: [
                Positioned.fill(
                  child: InteractiveViewer(
                    minScale: 0.8,
                    maxScale: 4,
                    child: Center(
                      child: Image.network(
                        url,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const Padding(
                          padding: EdgeInsets.all(24),
                          child: Text(
                            'Unable to preview this image.',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: 8,
                  top: 8,
                  child: IconButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                  ),
                ),
              ],
            ),
          );
        },
      );
      return;
    }

    await _showValueSheet(
      title: _attachmentDisplayName(attachment),
      subtitle: 'Attachment link',
      value: url,
    );
  }

  String _referenceDateRange(_JobDetailSnapshot job) {
    final start = _formatReferenceDate(job.startDate);
    final end = _formatReferenceDate(job.endDate);
    if (start == '—' && end == '—') return 'Date not specified';
    if (end == '—' || start == end) return start;
    return '$start – $end';
  }

  String _referencePayment(_JobDetailSnapshot job) {
    final type = _pretty(job.paymentType);
    if (job.paymentType.toLowerCase() == 'negotiable') return 'Negotiable';
    final min = _money(job.paymentMin);
    final max = _money(job.paymentMax);
    if (job.paymentMin == null && job.paymentMax == null) {
      return type.isEmpty ? 'Payment not specified' : type;
    }
    if (job.paymentMax == null || job.paymentMax == job.paymentMin) {
      return type.isEmpty ? '\$$min' : '$type · \$$min';
    }
    return type.isEmpty ? '\$$min – \$$max' : '$type · \$$min – \$$max';
  }

  String _formatReferenceDate(DateTime? date) {
    if (date == null) return '—';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day.toString().padLeft(2, '0')}, ${date.year}';
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
                  title: AppLanguage.text('Description'),
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
                // if (job.company != null) ...[
                //   const SizedBox(height: 12),
                //   _companyCard(job.company!),
                // ],
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
    final showMenu =
        _hasLiveJob &&
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
          Expanded(
            child: Text(
              AppLanguage.text('Job Details'),
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
                  return [
                    PopupMenuItem(
                      value: 'edit',
                      child: _MenuRow(
                        icon: Icons.edit_outlined,
                        label: AppLanguage.text('Edit Draft'),
                      ),
                    ),
                    PopupMenuItem(
                      value: 'publish',
                      child: _MenuRow(
                        icon: Icons.public_rounded,
                        label: AppLanguage.text('Publish Job'),
                      ),
                    ),
                    PopupMenuDivider(),
                    PopupMenuItem(
                      value: 'delete',
                      child: _MenuRow(
                        icon: Icons.delete_outline_rounded,
                        label: AppLanguage.text('Delete Draft'),
                        danger: true,
                      ),
                    ),
                  ];
                }

                return [
                  PopupMenuItem(
                    value: 'close',
                    child: _MenuRow(
                      icon: Icons.lock_clock_outlined,
                      label: AppLanguage.text('Close Applications'),
                    ),
                  ),
                  const PopupMenuDivider(),
                  PopupMenuItem(
                    value: 'cancel',
                    child: _MenuRow(
                      icon: Icons.cancel_outlined,
                      label: AppLanguage.text('Cancel Job'),
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
          colors: [Color(0xFF102A3A), Color(0xFF0C4655), Color(0xFF0D8AA5)],
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
                _SyncPill(label: AppLanguage.text('Updating')),
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
      title: AppLanguage.text('Job Overview'),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _OverviewTile(
                  icon: Icons.event_available_outlined,
                  label: AppLanguage.text('Start'),
                  value: _formatDate(job.startDate),
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: _OverviewTile(
                  icon: Icons.event_busy_outlined,
                  label: AppLanguage.text('End'),
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
                  label: AppLanguage.text('Drone'),
                  value: job.droneSize.isEmpty
                      ? 'Not specified'
                      : _pretty(job.droneSize),
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: _OverviewTile(
                  icon: Icons.workspace_premium_outlined,
                  label: AppLanguage.text('Experience'),
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
              Text(
                AppLanguage.text(
                  'Showing saved data while the latest job state syncs.',
                ),
                style: TextStyle(color: AppColors.grey, fontSize: 10.8),
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
                    label: AppLanguage.text('Edit'),
                    onTap: canAct ? _edit : null,
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: _ActionButton(
                    icon: Icons.public_rounded,
                    label: AppLanguage.text('Publish'),
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
                label: AppLanguage.text('Delete Draft'),
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
                    label: AppLanguage.text('Close'),
                    onTap: canAct ? _closeJob : null,
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: _ActionButton(
                    icon: Icons.cancel_outlined,
                    label: AppLanguage.text('Cancel'),
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
      title: AppLanguage.text('Requirements'),
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
            _requirementLine(Icons.lock_outline_rounded, 'NDA required'),
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
          : Text(
        AppLanguage.text('No additional requirements.'),
        style: TextStyle(color: AppColors.grey, fontSize: 12.5),
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

  // Widget _companyCard(_CompanySnapshot company) {
  //   final name = company.companyName.isEmpty
  //       ? 'Company #${company.id}'
  //       : company.companyName;
  //
  //   return _section(
  //     icon: Icons.business_rounded,
  //     title: AppLanguage.text('Company'),
  //     child: Row(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         Container(
  //           width: 46,
  //           height: 46,
  //           alignment: Alignment.center,
  //           decoration: BoxDecoration(
  //             gradient: const LinearGradient(
  //               colors: [AppColors.blue, Color(0xFF0D8AA5)],
  //             ),
  //             borderRadius: BorderRadius.circular(14),
  //           ),
  //           child: Text(
  //             _initials(name),
  //             style: const TextStyle(
  //               color: Colors.white,
  //               fontSize: 14,
  //               fontWeight: FontWeight.w900,
  //             ),
  //           ),
  //         ),
  //         const SizedBox(width: 11),
  //         Expanded(
  //           child: Column(
  //             crossAxisAlignment: CrossAxisAlignment.start,
  //             children: [
  //               Text(
  //                 name,
  //                 style: const TextStyle(
  //                   color: AppColors.navy,
  //                   fontSize: 14.5,
  //                   fontWeight: FontWeight.w800,
  //                 ),
  //               ),
  //               if (company.industryType.isNotEmpty) ...[
  //                 const SizedBox(height: 3),
  //                 Text(
  //                   company.industryType,
  //                   style: const TextStyle(
  //                     color: AppColors.grey,
  //                     fontSize: 11.5,
  //                   ),
  //                 ),
  //               ],
  //               if (company.address.isNotEmpty) ...[
  //                 const SizedBox(height: 8),
  //                 Row(
  //                   crossAxisAlignment: CrossAxisAlignment.start,
  //                   children: [
  //                     const Icon(
  //                       Icons.location_on_outlined,
  //                       color: AppColors.blue,
  //                       size: 14,
  //                     ),
  //                     const SizedBox(width: 5),
  //                     Expanded(
  //                       child: Text(
  //                         company.address,
  //                         style: const TextStyle(
  //                           color: AppColors.text,
  //                           fontSize: 11.8,
  //                           height: 1.35,
  //                         ),
  //                       ),
  //                     ),
  //                   ],
  //                 ),
  //               ],
  //             ],
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  Widget _applicationsSection() {
    final pendingCount = _applicants
        .where((item) => item.status == 'pending')
        .length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              AppLanguage.text('Applications'),
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
            if (_applicantsRefreshing)
              _SyncPill(label: AppLanguage.text('Syncing')),
          ],
        ),
        const SizedBox(height: 5),
        Text(
          AppLanguage.text(
            'Review pilot profile, drone and message before deciding.',
          ),
          style: TextStyle(color: AppColors.grey, fontSize: 11.3, height: 1.4),
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

  List<_ApplicantSnapshot> _sortedApplicants(List<_ApplicantSnapshot> values) {
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
          const Icon(Icons.cloud_off_rounded, color: AppColors.grey, size: 20),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              message,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppColors.grey, fontSize: 11.5),
            ),
          ),
          TextButton(
            onPressed: _refreshApplicantsFromNetwork,
            child: Text(AppLanguage.text('Retry')),
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
                child: Icon(icon, color: AppColors.blue, size: 16),
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
              style: const TextStyle(color: AppColors.grey, fontSize: 11.3),
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

  Widget _chipWrap(List<String> items, Color background, Color foreground) {
    return Wrap(
      spacing: 7,
      runSpacing: 7,
      children: items
          .map(
            (item) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
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
    return type.isEmpty ? '\$$min - \$$max' : '$type · \$$min - \$$max';
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
          backgroundColor: isError ? Colors.red.shade700 : AppColors.navy,
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
    required this.imageUrl,
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
  final String imageUrl;

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
      requiredCertifications: List<String>.from(job.requiredCertifications),
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
      imageUrl: _readDynamicJobImage(job),
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
      imageUrl: _asString(json['image_url']),
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
      'image_url': imageUrl,
    };
  }
}

class _AttachmentSnapshot {
  const _AttachmentSnapshot({
    required this.name,
    required this.size,
    required this.isImage,
    required this.url,
  });

  final String name;
  final int size;
  final bool isImage;
  final String url;

  factory _AttachmentSnapshot.fromModel(dynamic attachment) {
    return _AttachmentSnapshot(
      name: attachment.name?.toString() ?? '',
      size: _asInt(attachment.size),
      isImage: attachment.isImage == true,
      url: _readDynamicAttachmentUrl(attachment),
    );
  }

  factory _AttachmentSnapshot.fromJson(Map<String, dynamic> json) {
    return _AttachmentSnapshot(
      name: _asString(json['name']),
      size: _asInt(json['size']),
      isImage: _asBool(json['is_image']),
      url: _asString(json['url']),
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'size': size,
    'is_image': isImage,
    'url': url,
  };
}

class _CompanySnapshot {
  const _CompanySnapshot({
    required this.id,
    required this.companyName,
    required this.industryType,
    required this.address,
    required this.imageUrl,
  });

  final int id;
  final String companyName;
  final String industryType;
  final String address;
  final String imageUrl;

  factory _CompanySnapshot.fromModel(CompanyJobCompanyProfileModel company) {
    return _CompanySnapshot(
      id: company.id,
      companyName: company.companyName,
      industryType: company.industryType,
      address: company.address,
      imageUrl: _readDynamicCompanyImage(company),
    );
  }

  factory _CompanySnapshot.fromJson(Map<String, dynamic> json) {
    return _CompanySnapshot(
      id: _asInt(json['id']),
      companyName: _asString(json['company_name']),
      industryType: _asString(json['industry_type']),
      address: _asString(json['address']),
      imageUrl: _asString(json['image_url']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'company_name': companyName,
    'industry_type': industryType,
    'address': address,
    'image_url': imageUrl,
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
    required this.droneCapabilities,
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
  final List<String> droneCapabilities;
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
      droneCapabilities: List<String>.from(drone?.capabilities ?? const <String>[]),
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
      droneCapabilities: _stringList(json['drone_capabilities']),
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
    'drone_capabilities': droneCapabilities,
    'created_at': createdAt?.toIso8601String(),
  };
}

class _ReferenceJobPalette {
  static const background = Color(0xFFF9FCFD);
  static const navy = Color(0xFF0A2D46);
  static const text = Color(0xFF52677A);
  static const muted = Color(0xFF7C8D9D);
  static const teal = Color(0xFF109CAF);
  static const cyanSoft = Color(0xFFE9F9FB);
  static const green = Color(0xFF079B7D);
  static const greenDark = Color(0xFF087D6E);
  static const mintSoft = Color(0xFFE7FAF6);
  static const border = Color(0xFFE4ECEF);
  static const line = Color(0xFFEDF2F4);
  static const red = Color(0xFFE43333);
  static const warmBrown = Color(0xFF93664D);
}

class _ReferenceSectionCard extends StatelessWidget {
  const _ReferenceSectionCard({
    required this.child,
    this.padding = const EdgeInsets.all(12),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _ReferenceJobPalette.border),
        boxShadow: [
          BoxShadow(
            color: _ReferenceJobPalette.navy.withOpacity(.018),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _ReferenceSectionHeader extends StatelessWidget {
  const _ReferenceSectionHeader({
    required this.icon,
    required this.title,
    this.action,
    this.onActionTap,
  });

  final IconData icon;
  final String title;
  final String? action;
  final VoidCallback? onActionTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: _ReferenceJobPalette.cyanSoft,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, size: 15, color: _ReferenceJobPalette.teal),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: _ReferenceJobPalette.navy,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        if (action != null && onActionTap != null)
          InkWell(
            onTap: onActionTap,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
              child: Text(
                action!,
                style: const TextStyle(
                  color: _ReferenceJobPalette.teal,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _ReferenceCompanyAvatar extends StatelessWidget {
  const _ReferenceCompanyAvatar({
    required this.company,
    required this.name,
    this.fallbackImageUrl = '',
  });

  final _CompanySnapshot? company;
  final String name;
  final String fallbackImageUrl;

  @override
  Widget build(BuildContext context) {
    final companyImage = company?.imageUrl.trim() ?? '';
    final imageUrl = companyImage.isNotEmpty ? companyImage : fallbackImageUrl.trim();
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFFEAF2F4),
        border: Border.all(color: Colors.white, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: _ReferenceJobPalette.navy.withOpacity(.06),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipOval(
        child: imageUrl.isEmpty
            ? Center(
          child: Text(
            _initials(name),
            style: const TextStyle(
              color: _ReferenceJobPalette.teal,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        )
            : Image.network(
          imageUrl,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Center(
            child: Text(
              _initials(name),
              style: const TextStyle(
                color: _ReferenceJobPalette.teal,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ReferenceImportantInfoRow extends StatelessWidget {
  const _ReferenceImportantInfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: _ReferenceJobPalette.teal),
        const SizedBox(width: 6),
        Text(
          '$label:',
          style: const TextStyle(
            color: _ReferenceJobPalette.navy,
            fontSize: 11.2,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _ReferenceJobPalette.text,
              fontSize: 11.4,
              fontWeight: FontWeight.w600,
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }
}

class _ReferenceRequirementStat extends StatelessWidget {
  const _ReferenceRequirementStat({
    required this.icon,
    required this.label,
    required this.value,
    this.onTap,
    this.helperText,
    this.valueMaxLines = 2,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;
  final String? helperText;
  final int valueMaxLines;

  @override
  Widget build(BuildContext context) {
    final tile = Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FCFD),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _ReferenceJobPalette.border),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: _ReferenceJobPalette.teal),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _ReferenceJobPalette.muted,
                    fontSize: 10.2,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            textAlign: TextAlign.center,
            maxLines: valueMaxLines,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _ReferenceJobPalette.navy,
              fontSize: 11.2,
              fontWeight: FontWeight.w700,
              height: 1.24,
            ),
          ),
          if (helperText != null) ...[
            const SizedBox(height: 5),
            Text(
              helperText!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _ReferenceJobPalette.teal,
                fontSize: 9.3,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );

    if (onTap == null) return tile;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: tile,
      ),
    );
  }
}

class _ReferenceVerticalDivider extends StatelessWidget {
  const _ReferenceVerticalDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 48,
      color: _ReferenceJobPalette.line,
    );
  }
}

class _ReferenceStatusPill extends StatelessWidget {
  const _ReferenceStatusPill({
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: foreground,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _ReferenceAttachmentTile extends StatelessWidget {
  const _ReferenceAttachmentTile({
    required this.attachment,
    required this.title,
    required this.fileSize,
    required this.isImagePreview,
    required this.onTap,
  });

  final _AttachmentSnapshot attachment;
  final String title;
  final String fileSize;
  final bool isImagePreview;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(11),
        child: Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: _ReferenceJobPalette.border),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F6F8),
                  borderRadius: BorderRadius.circular(9),
                ),
                clipBehavior: Clip.antiAlias,
                child: isImagePreview && attachment.url.trim().isNotEmpty
                    ? Image.network(
                  attachment.url.trim(),
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.image_outlined,
                    size: 18,
                    color: _ReferenceJobPalette.teal,
                  ),
                )
                    : Icon(
                  isImagePreview
                      ? Icons.image_outlined
                      : Icons.insert_drive_file_outlined,
                  size: 18,
                  color: _ReferenceJobPalette.teal,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _ReferenceJobPalette.navy,
                        fontSize: 10.3,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      fileSize,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _ReferenceJobPalette.muted,
                        fontSize: 9.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                isImagePreview ? Icons.open_in_full_rounded : Icons.chevron_right_rounded,
                size: 16,
                color: _ReferenceJobPalette.navy,
              ),
            ],
          ),
        ),
      ),
    );
  }
}


class _ReferenceApplicantCard extends StatelessWidget {
  const _ReferenceApplicantCard({
    required this.application,
    required this.onTap,
  });

  final _ApplicantSnapshot application;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _ReferenceJobPalette.border),
        boxShadow: [
          BoxShadow(
            color: _ReferenceJobPalette.navy.withOpacity(.016),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: _ReferenceApplicantRow(
          application: application,
          onTap: onTap,
        ),
      ),
    );
  }
}

class _ReferenceApplicantRow extends StatelessWidget {
  const _ReferenceApplicantRow({
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
    final details = <String>[];
    if (application.experienceYears != null) {
      details.add('${application.experienceYears} yrs experience');
    }
    if (application.droneCapabilities.isNotEmpty) {
      details.add(application.droneCapabilities.take(2).join(', '));
    } else if (application.droneName.trim().isNotEmpty) {
      details.add(application.droneName.trim());
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Container(
                width: 43,
                height: 43,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFEAF2F4),
                ),
                child: ClipOval(
                  child: application.pilotPhoto.trim().isEmpty
                      ? Center(
                    child: Text(
                      _initials(name),
                      style: const TextStyle(
                        color: _ReferenceJobPalette.teal,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  )
                      : Image.network(
                    application.pilotPhoto.trim(),
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Center(
                      child: Text(
                        _initials(name),
                        style: const TextStyle(
                          color: _ReferenceJobPalette.teal,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ),
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
                        color: _ReferenceJobPalette.navy,
                        fontSize: 11.8,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      details.isEmpty ? 'Pilot application' : details.join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _ReferenceJobPalette.muted,
                        fontSize: 9.8,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 7),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: visual.background,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  application.statusLabel.isEmpty
                      ? _titleCase(application.status)
                      : application.statusLabel,
                  style: TextStyle(
                    color: visual.foreground,
                    fontSize: 9.4,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 5),
              const Icon(
                Icons.chevron_right_rounded,
                size: 19,
                color: _ReferenceJobPalette.muted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReferenceBottomAction extends StatelessWidget {
  const _ReferenceBottomAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.danger = false,
    this.primary = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool danger;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final color = danger
        ? _ReferenceJobPalette.red
        : (primary ? Colors.white : _ReferenceJobPalette.navy);
    final border = danger
        ? const Color(0xFFEB6C6C)
        : (primary ? _ReferenceJobPalette.teal : _ReferenceJobPalette.border);
    final background = danger
        ? const Color(0xFFFFFBFB)
        : (primary ? _ReferenceJobPalette.teal : Colors.white);

    return SizedBox(
      height: 50,
      child: OutlinedButton.icon(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          backgroundColor: background,
          side: BorderSide(color: border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        icon: Icon(icon, size: 18),
        label: Text(
          label,
          style: const TextStyle(
            fontSize: 11.8,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _ReferenceCompanyImageFallback extends StatelessWidget {
  const _ReferenceCompanyImageFallback({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF62B8C4), Color(0xFF17657A)],
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        _initials(name),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _ReferenceJobImageFallback extends StatelessWidget {
  const _ReferenceJobImageFallback({required this.category});

  final String category;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF6EB6C2), Color(0xFF1E5A73)],
        ),
      ),
      alignment: Alignment.center,
      child: Icon(
        category.toLowerCase().contains('survey')
            ? Icons.map_outlined
            : category.toLowerCase().contains('photo')
            ? Icons.photo_camera_outlined
            : Icons.flight_takeoff_rounded,
        color: Colors.white,
        size: 27,
      ),
    );
  }
}

class _ReferenceCompanyBottomNav extends StatelessWidget {
  const _ReferenceCompanyBottomNav({required this.onTap});

  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    const items = [
      (Icons.home_outlined, 'Home'),
      (Icons.work_outline_rounded, 'Jobs'),
      (Icons.assignment_outlined, 'Applications'),
      (Icons.chat_bubble_outline_rounded, 'Messages'),
      (Icons.business_outlined, 'Profile'),
    ];

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: _ReferenceJobPalette.line)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 63,
          child: Row(
            children: List.generate(items.length, (index) {
              final item = items[index];
              return Expanded(
                child: InkWell(
                  onTap: () => onTap(index),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(item.$1, size: 21, color: _ReferenceJobPalette.muted),
                      const SizedBox(height: 4),
                      Text(
                        item.$2,
                        style: const TextStyle(
                          color: _ReferenceJobPalette.muted,
                          fontSize: 9.4,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _ReferenceJobDetailsShimmer extends StatelessWidget {
  const _ReferenceJobDetailsShimmer();

  @override
  Widget build(BuildContext context) {
    return const _ShimmerAnimator(
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 10, 20, 20),
        child: Column(
          children: [
            Row(
              children: [
                _ShimmerBox(width: 24, height: 24, radius: 8),
                Spacer(),
                _ShimmerBox(width: 92, height: 15, radius: 7),
                Spacer(),
                _ShimmerBox(width: 24, height: 24, radius: 8),
              ],
            ),
            SizedBox(height: 16),
            Row(
              children: [
                _ShimmerBox(width: 78, height: 72, radius: 10),
                SizedBox(width: 12),
                Expanded(child: _ShimmerBox(height: 72, radius: 10)),
              ],
            ),
            SizedBox(height: 14),
            _ShimmerBox(height: 174, radius: 16),
            SizedBox(height: 10),
            _ShimmerBox(height: 210, radius: 16),
            SizedBox(height: 10),
            _ShimmerBox(height: 130, radius: 16),
          ],
        ),
      ),
    );
  }
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
                  Text(
                    AppLanguage.text('Open'),
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
            style: const TextStyle(color: AppColors.grey, fontSize: 10.5),
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
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
        ),
      );
    }

    return OutlinedButton.icon(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: danger ? Colors.red.shade700 : AppColors.navy,
        backgroundColor: Colors.white,
        side: BorderSide(
          color: danger ? Colors.red.withOpacity(0.22) : AppColors.cardBorder,
        ),
        minimumSize: const Size.fromHeight(44),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
      ),
      icon: Icon(icon, size: 17),
      label: Text(
        label,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
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
  const _HeroMiniPill({required this.icon, required this.text});

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
  const _RoundIconButton({required this.icon, required this.onTap});

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
      child: Column(
        children: [
          Icon(
            Icons.people_outline_rounded,
            color: AppColors.lightGrey,
            size: 32,
          ),
          SizedBox(height: 8),
          Text(
            AppLanguage.text('No applications yet'),
            style: TextStyle(
              color: AppColors.navy,
              fontSize: 13.5,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 4),
          Text(
            AppLanguage.text(
              'Pilot applications for this job will appear here.',
            ),
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.grey, fontSize: 11.5),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

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
              child: Text(AppLanguage.text('Try Again')),
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
  const _ShimmerBox({this.width, required this.height, this.radius = 8});

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

String _readDynamicJobImage(dynamic job) {
  String clean(dynamic value) => value?.toString().trim() ?? '';

  try {
    final value = clean(job.coverImageUrl);
    if (value.isNotEmpty) return value;
  } catch (_) {}
  try {
    final value = clean(job.coverImage);
    if (value.isNotEmpty) return value;
  } catch (_) {}
  try {
    final value = clean(job.imageUrl);
    if (value.isNotEmpty) return value;
  } catch (_) {}
  try {
    final value = clean(job.image);
    if (value.isNotEmpty) return value;
  } catch (_) {}
  try {
    final value = clean(job.thumbnailUrl);
    if (value.isNotEmpty) return value;
  } catch (_) {}
  try {
    final attachments = job.attachments;
    if (attachments is Iterable) {
      for (final item in attachments) {
        bool isImage = false;
        try {
          isImage = item.isImage == true;
        } catch (_) {}
        if (!isImage) continue;
        final url = _readDynamicAttachmentUrl(item);
        if (url.isNotEmpty) return url;
      }
    }
  } catch (_) {}
  return '';
}

String _readDynamicAttachmentUrl(dynamic attachment) {
  String clean(dynamic value) => value?.toString().trim() ?? '';
  try {
    final value = clean(attachment.url);
    if (value.isNotEmpty) return value;
  } catch (_) {}
  try {
    final value = clean(attachment.fileUrl);
    if (value.isNotEmpty) return value;
  } catch (_) {}
  try {
    final value = clean(attachment.downloadUrl);
    if (value.isNotEmpty) return value;
  } catch (_) {}
  try {
    final value = clean(attachment.path);
    if (value.startsWith('http://') || value.startsWith('https://')) return value;
  } catch (_) {}
  return '';
}


String _readDynamicCompanyImage(dynamic company) {
  String clean(dynamic value) => value?.toString().trim() ?? '';
  try {
    final value = clean(company.logoUrl);
    if (value.isNotEmpty) return value;
  } catch (_) {}
  try {
    final value = clean(company.logo);
    if (value.isNotEmpty) return value;
  } catch (_) {}
  try {
    final value = clean(company.companyLogo);
    if (value.isNotEmpty) return value;
  } catch (_) {}
  try {
    final value = clean(company.companyLogoUrl);
    if (value.isNotEmpty) return value;
  } catch (_) {}
  try {
    final value = clean(company.profilePhoto);
    if (value.isNotEmpty) return value;
  } catch (_) {}
  try {
    final value = clean(company.imageUrl);
    if (value.isNotEmpty) return value;
  } catch (_) {}
  try {
    final value = clean(company.image);
    if (value.isNotEmpty) return value;
  } catch (_) {}
  return '';
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
        (part) => '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}',
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
