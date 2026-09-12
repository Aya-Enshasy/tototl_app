import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/storage/user_session_storage.dart';
import '../../../../core/theme/app_colors.dart';
import '../../controllers/company_job_controller.dart';
 import '../../models/company_job_posting_model.dart';
import '../../services/company_job_service.dart';
import 'company_applicant_detail_screen.dart';
import 'company_applicant_list_item.dart';

class CompanyApplicationsScreen extends StatefulWidget {
  const CompanyApplicationsScreen({super.key});

  @override
  State<CompanyApplicationsScreen> createState() =>
      _CompanyApplicationsScreenState();
}

/// Backward-compatible wrapper so the current CompanyShellScreen keeps working
/// even before its import/widget name is changed from Operations to Applications.
class CompanyOperationsScreen extends StatelessWidget {
  const CompanyOperationsScreen({super.key});

  @override
  Widget build(BuildContext context) => const CompanyApplicationsScreen();
}

class _CompanyApplicationsScreenState extends State<CompanyApplicationsScreen> {
  static const FlutterSecureStorage _storage = FlutterSecureStorage();
  static const String _cachePrefix = 'company_all_applications_v1_';
  static const int _perPage = 26;

  late final CompanyJobController _controller;

  final List<CompanyApplicantListItem> _items = <CompanyApplicantListItem>[];

  String? _selectedStatus;
  String? _errorMessage;

  bool _cacheReadFinished = false;
  bool _hasSnapshot = false;
  bool _firstNetworkAttemptFinished = false;
  bool _networkRefreshing = false;

  int _viewSerial = 0;
  String? _queuedStatus;
  int? _queuedSerial;

  @override
  void initState() {
    super.initState();
    _controller = CompanyJobController(
      CompanyJobService(ApiClient()),
    );
    unawaited(_loadStatus(null));
  }

  Future<String> _resolveCacheKey(String? status) async {
    final userId = await UserSessionStorage.getUserId();
    final owner = userId?.toString().trim().isNotEmpty == true
        ? userId.toString().trim()
        : 'company';
    final bucket = status?.trim().toLowerCase().isNotEmpty == true
        ? status!.trim().toLowerCase()
        : 'all';
    return '$_cachePrefix${owner}_$bucket';
  }

  Future<void> _loadStatus(String? status) async {
    final normalized = _normalizeStatus(status);
    final serial = ++_viewSerial;

    if (mounted) {
      setState(() {
        _selectedStatus = normalized;
        _items.clear();
        _errorMessage = null;
        _cacheReadFinished = false;
        _hasSnapshot = false;
        _firstNetworkAttemptFinished = false;
      });
    }

    await _loadCache(normalized, serial);
    if (!mounted || serial != _viewSerial) return;

    unawaited(
      _refreshFromNetwork(
        status: normalized,
        serial: serial,
      ),
    );
  }

  Future<void> _loadCache(String? status, int serial) async {
    try {
      final key = await _resolveCacheKey(status);
      if (!mounted || serial != _viewSerial) return;
      final raw = await _storage.read(key: key);
      if (raw == null || raw.trim().isEmpty) return;

      final decoded = jsonDecode(raw);
      final values = decoded is Map ? decoded['items'] : decoded;
      if (values is! List) return;

      final cached = <CompanyApplicantListItem>[];
      for (final value in values) {
        if (value is Map) {
          cached.add(
            CompanyApplicantListItem.fromJson(
              Map<String, dynamic>.from(value),
            ),
          );
        }
      }

      _sortNewestFirst(cached);

      if (!mounted || serial != _viewSerial) return;
      setState(() {
        _items
          ..clear()
          ..addAll(cached);
        // An empty cached list is still a valid snapshot.
        _hasSnapshot = true;
      });
    } catch (_) {
      // Old/malformed cache must never block the live API request.
    } finally {
      if (mounted && serial == _viewSerial) {
        setState(() => _cacheReadFinished = true);
      }
    }
  }

  Future<void> _saveCache({
    required String? status,
    required List<CompanyApplicantListItem> items,
  }) async {
    try {
      final key = await _resolveCacheKey(status);
      await _storage.write(
        key: key,
        value: jsonEncode({
          'version': 1,
          'saved_at': DateTime.now().toIso8601String(),
          'status': status,
          'items': items.map((item) => item.toJson()).toList(growable: false),
        }),
      );
    } catch (_) {
      // Cache write failure should be invisible to the user.
    }
  }

  Future<void> _refreshFromNetwork({
    required String? status,
    required int serial,
    bool manual = false,
  }) async {
    if (_networkRefreshing) {
      _queuedStatus = status;
      _queuedSerial = serial;
      return;
    }

    _networkRefreshing = true;
    if (mounted && serial == _viewSerial) {
      setState(() {
        if (!_hasSnapshot) _errorMessage = null;
      });
    }

    try {
      final success = await _controller.loadCompanyApplicants(
        status: status,
        perPage: _perPage,
      );

      if (!mounted) return;

      // Do not paint a response that belongs to an old filter selection.
      if (serial != _viewSerial || status != _selectedStatus) return;

      if (success) {
        final fresh = List<CompanyApplicantListItem>.from(
          _controller.companyApplicants,
        );
        _sortNewestFirst(fresh);

        setState(() {
          _items
            ..clear()
            ..addAll(fresh);
          _hasSnapshot = true;
          _errorMessage = null;
        });

        unawaited(
          _saveCache(
            status: status,
            items: fresh,
          ),
        );
      } else {
        final message = _controller.companyApplicantsErrorMessage ??
            'Unable to load applications.';

        if (!_hasSnapshot) {
          setState(() => _errorMessage = message);
        } else if (manual) {
          _showSnack(message, isError: true);
        }
      }
    } catch (e) {
      if (!mounted || serial != _viewSerial || status != _selectedStatus) {
        return;
      }

      if (!_hasSnapshot) {
        setState(() => _errorMessage = e.toString());
      } else if (manual) {
        _showSnack(e.toString(), isError: true);
      }
    } finally {
      _networkRefreshing = false;

      if (mounted && serial == _viewSerial) {
        setState(() => _firstNetworkAttemptFinished = true);
      }

      final queuedSerial = _queuedSerial;
      final queuedStatus = _queuedStatus;
      _queuedSerial = null;
      _queuedStatus = null;

      if (mounted &&
          queuedSerial != null &&
          queuedSerial == _viewSerial &&
          queuedStatus == _selectedStatus) {
        unawaited(
          _refreshFromNetwork(
            status: queuedStatus,
            serial: queuedSerial,
          ),
        );
      }
    }
  }

  Future<void> _manualRefresh() async {
    final serial = _viewSerial;
    final status = _selectedStatus;
    await _refreshFromNetwork(
      status: status,
      serial: serial,
      manual: true,
    );
  }

  Future<void> _openApplication(CompanyApplicantListItem item) async {
    HapticFeedback.selectionClick();

    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => CompanyApplicantDetailScreen(
          jobId: item.application.jobPostingId,
          application: item.application,
        ),
      ),
    );

    if (!mounted) return;

    // Accept/reject can happen in details. Always request the newest state in
    // the background while the cached/list state remains visible.
    unawaited(_manualRefresh());

    if (changed == true) {
      _showSnack('Application updated.');
    }
  }

  bool get _showInitialShimmer =>
      !_hasSnapshot &&
          !_firstNetworkAttemptFinished &&
          (_items.isEmpty || !_cacheReadFinished);

  int get _pendingCount => _items
      .where((item) => item.application.status.trim().toLowerCase() == 'pending')
      .length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        children: [
          const _ApplicationsBackground(),
          SafeArea(
            child: _showInitialShimmer
                ? const _ApplicationsPageShimmer()
                : _errorMessage != null && !_hasSnapshot
                ? _ErrorView(
              message: _errorMessage!,
              onRetry: () => _loadStatus(_selectedStatus),
            )
                : _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final label = _selectedStatus == null
        ? '${_items.length} application${_items.length == 1 ? '' : 's'}'
        : '${_items.length} ${_pretty(_selectedStatus!)}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Applications',
                      style: TextStyle(
                        color: AppColors.navy,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.15,
                      ),
                    ),
                    const SizedBox(height: 5),

                  ],
                ),
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: _networkRefreshing && _hasSnapshot
                    ? const _SyncPill(
                  key: ValueKey('syncing'),
                )
                    : const SizedBox.shrink(
                  key: ValueKey('idle'),
                ),
              ),
            ],
          ),
        ),
        if (_selectedStatus == null && _items.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 10),
            child: _SummaryStrip(
              total: _items.length,
              pending: _pendingCount,
            ),
          ),
        ],
        _filters(),
        const SizedBox(height: 12),
        Expanded(
          child: RefreshIndicator(
            color: AppColors.blue,
            backgroundColor: Colors.white,
            onRefresh: _manualRefresh,
            child: _items.isEmpty
                ? _EmptyApplications(status: _selectedStatus)
                : ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 110),
              itemCount: _items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 11),
              itemBuilder: (_, index) {
                final item = _items[index];
                return _ApplicationCard(
                  item: item,
                  onTap: () => _openApplication(item),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _filters() {
    const statuses = <String>[
      'pending',
      'accepted',
      'rejected',
      'withdrawn',
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          _FilterChip(
            label: 'All',
            selected: _selectedStatus == null,
            onTap: () => _loadStatus(null),
          ),
          const SizedBox(width: 8),
          ...statuses.map(
                (status) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _FilterChip(
                label: _pretty(status),
                selected: _selectedStatus == status,
                onTap: () => _loadStatus(status),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSnack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: isError ? Colors.red.shade700 : AppColors.navy,
          content: Text(
            message,
            style: const TextStyle(fontSize: 12.5),
          ),
        ),
      );
  }
}

class _ApplicationCard extends StatelessWidget {
  const _ApplicationCard({
    required this.item,
    required this.onTap,
  });

  final CompanyApplicantListItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final application = item.application;
    final job = item.jobPosting;
    final pilot = application.pilotProfile;
    final drone = application.drone;
    final visual = _statusVisual(application.status);

    final pilotName = pilot?.displayName.trim().isNotEmpty == true
        ? pilot!.displayName.trim()
        : 'Pilot #${application.pilotProfileId}';

    final pilotPhoto = pilot?.profilePhoto.trim() ?? '';
    final pilotMeta = <String>[
      if (pilot?.location.trim().isNotEmpty == true) pilot!.location.trim(),
      if (pilot?.experienceYears != null) '${pilot!.experienceYears} yrs exp',
    ];

    final jobTitle = job?.title.trim().isNotEmpty == true
        ? job!.title.trim()
        : 'Job #${application.jobPostingId}';

    final jobMeta = <String>[
      if (job?.serviceCategory.trim().isNotEmpty == true)
        _pretty(job!.serviceCategory),
      if (job != null && _jobLocation(job).isNotEmpty) _jobLocation(job),
    ];

    final droneName = drone?.displayName.trim().isNotEmpty == true
        ? drone!.displayName.trim()
        : 'Drone #${application.droneId}';

    final capability = drone?.capabilities.isNotEmpty == true
        ? drone!.capabilities.first
        : '';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.cardBorder),
            boxShadow: [
              BoxShadow(
                color: AppColors.navy.withOpacity(0.045),
                blurRadius: 24,
                offset: const Offset(0, 9),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.blue.withOpacity(0.14),
                          AppColors.blueBg,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: const Icon(
                      Icons.assignment_outlined,
                      color: AppColors.blue,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          jobTitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.navy,
                            fontSize: 15.5,
                            fontWeight: FontWeight.w900,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          jobMeta.isEmpty
                              ? 'Job #${application.jobPostingId}'
                              : jobMeta.join(' · '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.grey,
                            fontSize: 11.3,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _StatusBadge(
                    label: application.statusLabel.trim().isNotEmpty
                        ? application.statusLabel
                        : _pretty(application.status),
                    foreground: visual.foreground,
                    background: visual.background,
                  ),
                ],
              ),
              const SizedBox(height: 13),
              Container(
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color: AppColors.bg,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.blue.withOpacity(0.12),
                        ),
                      ),
                      child: CircleAvatar(
                        backgroundColor: AppColors.blueBg,
                        foregroundImage: pilotPhoto.isNotEmpty
                            ? NetworkImage(pilotPhoto)
                            : null,
                        child: pilotPhoto.isNotEmpty
                            ? null
                            : Text(
                          _initials(pilotName),
                          style: const TextStyle(
                            color: AppColors.blue,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w900,
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
                            pilotName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.navy,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            pilotMeta.isEmpty
                                ? 'Pilot profile #${application.pilotProfileId}'
                                : pilotMeta.join(' · '),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.grey,
                              fontSize: 10.8,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.lightGrey,
                      size: 20,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 11),
              Row(
                children: [
                  Expanded(
                    child: _MiniInfoPill(
                      icon: Icons.flight_outlined,
                      text: capability.isEmpty
                          ? droneName
                          : '$droneName · ${_pretty(capability)}',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _MiniInfoPill(
                      icon: Icons.payments_outlined,
                      text: job == null ? 'Payment —' : _payment(job),
                      accent: AppColors.green,
                    ),
                  ),
                ],
              ),
              if (application.coverMessage.trim().isNotEmpty) ...[
                const SizedBox(height: 11),
                Text(
                  application.coverMessage.trim(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.grey,
                    fontSize: 11.4,
                    height: 1.4,
                  ),
                ),
              ],
              const SizedBox(height: 11),
              Row(
                children: [
                  const Icon(
                    Icons.schedule_rounded,
                    size: 14,
                    color: AppColors.lightGrey,
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      'Applied ${_formatDateTime(application.createdAt)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.grey,
                        fontSize: 10.8,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Text(
                    '#${application.id}',
                    style: const TextStyle(
                      color: AppColors.lightGrey,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                    ),
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

class _SummaryStrip extends StatelessWidget {
  const _SummaryStrip({
    required this.total,
    required this.pending,
  });

  final int total;
  final int pending;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.blue.withOpacity(0.08),
            AppColors.logoTurquoiseDark.withOpacity(0.055),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.blue.withOpacity(0.08)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.inbox_outlined,
            color: AppColors.blue,
            size: 18,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              '$total total application${total == 1 ? '' : 's'}',
              style: const TextStyle(
                color: AppColors.navy,
                fontSize: 11.8,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          if (pending > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.orangeBg,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '$pending pending',
                style: const TextStyle(
                  color: AppColors.orange,
                  fontSize: 10.2,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MiniInfoPill extends StatelessWidget {
  const _MiniInfoPill({
    required this.icon,
    required this.text,
    this.accent = AppColors.blue,
  });

  final IconData icon;
  final String text;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: accent.withOpacity(0.065),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: accent, size: 15),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: accent == AppColors.green ? AppColors.green : AppColors.navy,
                fontSize: 10.7,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: AppColors.blue,
      backgroundColor: Colors.white,
      side: BorderSide(
        color: selected ? AppColors.blue : AppColors.cardBorder,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      labelStyle: TextStyle(
        color: selected ? Colors.white : AppColors.navy,
        fontSize: 11.3,
        fontWeight: FontWeight.w800,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: foreground,
          fontSize: 9.8,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _SyncPill extends StatelessWidget {
  const _SyncPill({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.blueBg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _TinyPulse(),
          SizedBox(width: 6),
          Text(
            'Updating',
            style: TextStyle(
              color: AppColors.blue,
              fontSize: 10.3,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyApplications extends StatelessWidget {
  const _EmptyApplications({required this.status});

  final String? status;

  @override
  Widget build(BuildContext context) {
    final message = status == null
        ? 'No applications yet'
        : 'No ${_pretty(status!)} applications';

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 70, 20, 120),
      children: [
        Center(
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.blueBg,
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Icon(
              Icons.assignment_outlined,
              size: 31,
              color: AppColors.blue,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.navy,
            fontSize: 15,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Applications from pilots will appear here as soon as they apply to your jobs.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.grey,
            fontSize: 11.7,
            height: 1.45,
          ),
        ),
      ],
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
              width: 62,
              height: 62,
              decoration: BoxDecoration(
                color: AppColors.blueBg,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.cloud_off_rounded,
                color: AppColors.blue,
                size: 28,
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Could not load applications',
              style: TextStyle(
                color: AppColors.navy,
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.grey,
                fontSize: 11.7,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.blue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Icon(Icons.refresh_rounded, size: 17),
              label: const Text(
                'Try Again',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ApplicationsBackground extends StatelessWidget {
  const _ApplicationsBackground();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: -155,
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
          top: 430,
          left: -190,
          child: IgnorePointer(
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.logoTurquoiseDark.withOpacity(0.055),
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

// =============================================================================
// PREMIUM SHIMMER
// =============================================================================

class _ApplicationsPageShimmer extends StatelessWidget {
  const _ApplicationsPageShimmer();

  @override
  Widget build(BuildContext context) {
    return const _ShimmerAnimator(
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _ShimmerBox(width: 108, height: 16, radius: 7),
                      SizedBox(height: 8),
                      _ShimmerBox(width: 158, height: 9, radius: 5),
                    ],
                  ),
                ),
                _ShimmerBox(width: 72, height: 27, radius: 14),
              ],
            ),
            SizedBox(height: 18),
            _ShimmerBox(height: 50, radius: 16),
            SizedBox(height: 14),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: NeverScrollableScrollPhysics(),
              child: Row(
                children: [
                  _ShimmerBox(width: 55, height: 31, radius: 16),
                  SizedBox(width: 8),
                  _ShimmerBox(width: 76, height: 31, radius: 16),
                  SizedBox(width: 8),
                  _ShimmerBox(width: 82, height: 31, radius: 16),
                  SizedBox(width: 8),
                  _ShimmerBox(width: 78, height: 31, radius: 16),
                ],
              ),
            ),
            SizedBox(height: 15),
            Expanded(
              child: SingleChildScrollView(
                physics: NeverScrollableScrollPhysics(),
                child: Column(
                  children: [
                    _ApplicationCardSkeleton(),
                    SizedBox(height: 11),
                    _ApplicationCardSkeleton(),
                    SizedBox(height: 11),
                    _ApplicationCardSkeleton(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ApplicationCardSkeleton extends StatelessWidget {
  const _ApplicationCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
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
              _ShimmerBox(width: 42, height: 42, radius: 13),
              SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ShimmerBox(width: 158, height: 13, radius: 6),
                    SizedBox(height: 8),
                    _ShimmerBox(width: 112, height: 9, radius: 5),
                  ],
                ),
              ),
              _ShimmerBox(width: 64, height: 24, radius: 12),
            ],
          ),
          SizedBox(height: 13),
          _PilotSkeleton(),
          SizedBox(height: 11),
          Row(
            children: [
              Expanded(child: _ShimmerBox(height: 38, radius: 12)),
              SizedBox(width: 8),
              Expanded(child: _ShimmerBox(height: 38, radius: 12)),
            ],
          ),
          SizedBox(height: 12),
          _ShimmerBox(width: 175, height: 9, radius: 5),
        ],
      ),
    );
  }
}

class _PilotSkeleton extends StatelessWidget {
  const _PilotSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.circular(15),
      ),
      child: const Row(
        children: [
          _ShimmerBox(width: 42, height: 42, radius: 21),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ShimmerBox(width: 120, height: 11, radius: 5),
                SizedBox(height: 7),
                _ShimmerBox(width: 165, height: 8, radius: 4),
              ],
            ),
          ),
          _ShimmerBox(width: 18, height: 18, radius: 9),
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
            stops: const [0.0, 0.30, 0.50, 0.70, 1.0],
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
        width: 7,
        height: 7,
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
    case 'accepted':
      return const _VisualPair(AppColors.green, AppColors.greenBg);
    case 'rejected':
      return _VisualPair(Colors.red.shade700, Colors.red.shade50);
    case 'withdrawn':
      return _VisualPair(AppColors.grey, Colors.grey.shade100);
    default:
      return const _VisualPair(AppColors.orange, AppColors.orangeBg);
  }
}

String? _normalizeStatus(String? value) {
  final clean = value?.trim().toLowerCase() ?? '';
  return clean.isEmpty ? null : clean;
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
      .toList(growable: false);

  if (parts.isEmpty) return 'P';
  if (parts.length == 1) return parts.first[0].toUpperCase();
  return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
}

String _jobLocation(CompanyJobPostingModel job) {
  final parts = <String>[
    if (job.city.trim().isNotEmpty) job.city.trim(),
    if (job.state.trim().isNotEmpty) job.state.trim(),
    if (job.country.trim().isNotEmpty) job.country.trim(),
  ];

  if (parts.isEmpty && job.region.trim().isNotEmpty) {
    return job.region.trim();
  }

  return parts.join(', ');
}

String _payment(CompanyJobPostingModel job) {
  final type = job.paymentType.trim().toLowerCase();
  if (type == 'negotiable') return 'Negotiable';

  final min = _money(job.paymentMin);
  final max = _money(job.paymentMax);
  final label = _pretty(type);

  if (job.paymentMin == null && job.paymentMax == null) {
    return label.isEmpty ? 'Payment —' : label;
  }

  if (job.paymentMax == null || job.paymentMax == job.paymentMin) {
    return label.isEmpty ? '\$$min' : '\$$min · $label';
  }

  return '\$$min–\$$max${label.isEmpty ? '' : ' · $label'}';
}

String _money(double? value) {
  if (value == null) return '';
  if (value == value.roundToDouble()) return value.toStringAsFixed(0);
  return value.toStringAsFixed(2);
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

void _sortNewestFirst(List<CompanyApplicantListItem> values) {
  values.sort((a, b) {
    final left = a.application.createdAt;
    final right = b.application.createdAt;

    if (left == null && right == null) {
      return b.application.id.compareTo(a.application.id);
    }
    if (left == null) return 1;
    if (right == null) return -1;
    return right.compareTo(left);
  });
}
