import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:tototl_app/core/localization/app_language.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/storage/user_session_storage.dart';
import '../../../../core/theme/app_colors.dart';

import '../../controllers/company_job_controller.dart';
import '../../models/company_job_posting_model.dart';
import '../../services/company_job_service.dart';

import 'company_job_detail_screen.dart';
import 'post_job_screen.dart';

class CompanyJobsScreen extends StatefulWidget {
  const CompanyJobsScreen({super.key});

  @override
  State<CompanyJobsScreen> createState() => _CompanyJobsScreenState();
}

class _CompanyJobsScreenState extends State<CompanyJobsScreen> {
  static const FlutterSecureStorage _storage = FlutterSecureStorage();
  static const String _cachePrefix = 'company_jobs_v3_';

  late final CompanyJobController _controller;

  final List<_JobListSnapshot> _jobs = <_JobListSnapshot>[];
  String? _selectedStatus = 'published';
  String _searchQuery = '';
  String? _cacheKey;
  String? _errorMessage;

  bool _cacheReadFinished = false;
  bool _cachePresent = false;
  bool _firstNetworkAttemptFinished = false;
  bool _networkRefreshing = false;

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

  Future<String?> _resolveCacheKey() async {
    final existing = _cacheKey;
    if (existing != null) return existing;

    final userId = await UserSessionStorage.getUserId();
    if (userId == null) return null;

    final key = '$_cachePrefix$userId';
    _cacheKey = key;
    return key;
  }

  Future<void> _loadCache() async {
    try {
      final key = await _resolveCacheKey();
      if (key == null) return;

      final raw = await _storage.read(key: key);

      if (raw != null && raw.trim().isNotEmpty) {
        final decoded = jsonDecode(raw);
        if (decoded is Map) {
          final map = Map<String, dynamic>.from(decoded);
          final rawJobs = map['jobs'];
          final cachedJobs = <_JobListSnapshot>[];

          if (rawJobs is List) {
            for (final item in rawJobs) {
              if (item is Map) {
                cachedJobs.add(
                  _JobListSnapshot.fromJson(
                    Map<String, dynamic>.from(item),
                  ),
                );
              }
            }
          }

          if (mounted) {
            setState(() {
              _jobs
                ..clear()
                ..addAll(cachedJobs);
              _cachePresent = true;
            });
          }
        }
      }
    } catch (_) {
      // Cache failure must never block the API request.
    } finally {
      if (mounted) {
        setState(() => _cacheReadFinished = true);
      }
    }
  }

  Future<void> _saveCache(List<_JobListSnapshot> jobs) async {
    try {
      final key = await _resolveCacheKey();
      if (key == null) return;

      await _storage.write(
        key: key,
        value: jsonEncode({
          'saved_at': DateTime.now().toIso8601String(),
          'jobs': jobs.map((item) => item.toJson()).toList(),
        }),
      );
      _cachePresent = true;
    } catch (_) {
      // Cache write failure is intentionally silent.
    }
  }

  Future<void> _refreshFromNetwork({bool initial = false}) async {
    if (_networkRefreshing) return;
    _networkRefreshing = true;

    if (mounted && !initial) {
      setState(() {});
    }

    try {
      final success = await _controller.loadMyJobs();

      if (!mounted) return;

      if (success) {
        final fresh = _controller.jobs
            .map(_JobListSnapshot.fromModel)
            .toList(growable: false);

        setState(() {
          _jobs
            ..clear()
            ..addAll(fresh);
          _errorMessage = null;
        });

        unawaited(_saveCache(fresh));
      } else if (_jobs.isEmpty && !_cachePresent) {
        setState(() {
          _errorMessage =
              _controller.errorMessage ?? 'Unable to load jobs.';
        });
      }
    } catch (e) {
      if (mounted && _jobs.isEmpty && !_cachePresent) {
        setState(() {
          _errorMessage = _controller.errorMessage ?? e.toString();
        });
      }
    } finally {
      _networkRefreshing = false;
      if (mounted) {
        setState(() => _firstNetworkAttemptFinished = true);
      }
    }
  }

  Future<void> _manualRefresh() async {
    await _refreshFromNetwork();
  }

  Future<void> _openPostJob() async {
    HapticFeedback.selectionClick();
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>   PostJobScreen(),
      ),
    );

    if (!mounted) return;
    unawaited(_refreshFromNetwork());
  }

  Future<void> _openJob(int jobId) async {
    HapticFeedback.selectionClick();
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => CompanyJobDetailScreen(jobId: jobId),
      ),
    );

    if (!mounted) return;
    unawaited(_refreshFromNetwork());
  }

  List<_JobListSnapshot> get _visibleJobs {
    Iterable<_JobListSnapshot> jobs = _jobs;

    if (_selectedStatus != null) {
      jobs = jobs.where(
            (job) => job.status.toLowerCase() == _selectedStatus,
      );
    }

    final query = _searchQuery.trim().toLowerCase();
    if (query.isNotEmpty) {
      jobs = jobs.where((job) {
        return job.title.toLowerCase().contains(query) ||
            job.serviceCategory.toLowerCase().contains(query) ||
            job.location.toLowerCase().contains(query) ||
            job.id.toString().contains(query);
      });
    }

    return jobs.toList(growable: false);
  }

  int _statusCount(String status) => _jobs
      .where((job) => job.status.toLowerCase() == status)
      .length;

  int get _publishedCount => _statusCount('published');

  bool get _showInitialShimmer =>
      !_cachePresent &&
          !_firstNetworkAttemptFinished &&
          (_jobs.isEmpty || !_cacheReadFinished);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _JobsPalette.background,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: _showInitialShimmer
          ? null
          : _PostJobFloatingButton(onTap: _openPostJob),
      body: SafeArea(
        child: _showInitialShimmer
            ? const _JobsPageShimmer()
            : _errorMessage != null && _jobs.isEmpty
            ? _ErrorView(
          message: _errorMessage!,
          onRetry: () => _refreshFromNetwork(),
        )
            : _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    final visible = _visibleJobs;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 15, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'My Jobs',
                style: TextStyle(
                  color: _JobsPalette.navy,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -.25,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '${_jobs.length} postings · $_publishedCount published',
                style: const TextStyle(
                  color: _JobsPalette.muted,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 13),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 43,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF7FAFB),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: _JobsPalette.line),
                      ),
                      child: TextField(
                        onChanged: (value) => setState(() => _searchQuery = value),
                        style: const TextStyle(
                          color: _JobsPalette.navy,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'Search jobs...',
                          hintStyle: TextStyle(
                            color: _JobsPalette.muted,
                            fontSize: 11.5,
                          ),
                          prefixIcon: Icon(
                            Icons.search_rounded,
                            size: 20,
                            color: _JobsPalette.muted,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 13),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    child: InkWell(
                      onTap: _showFiltersSheet,
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        width: 43,
                        height: 43,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: _JobsPalette.line),
                        ),
                        child: const Icon(
                          Icons.tune_rounded,
                          color: _JobsPalette.navy,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        _statusFilters(),
        const SizedBox(height: 12),
        Expanded(
          child: RefreshIndicator(
            color: _JobsPalette.teal,
            onRefresh: _manualRefresh,
            child: visible.isEmpty
                ? _EmptyJobsView(status: _selectedStatus)
                : ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 116),
              itemCount: visible.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, index) {
                final job = visible[index];
                return _CompanyJobCard(
                  job: job,
                  onTap: () => _openJob(job.id),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _statusFilters() {
    const statuses = ['published', 'draft', 'closed', 'cancelled'];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: statuses.asMap().entries.map((entry) {
          final status = entry.value;
          return Padding(
            padding: EdgeInsets.only(right: entry.key == statuses.length - 1 ? 0 : 7),
            child: _ReferenceStatusChip(
              label: '${_pretty(status)} (${_statusCount(status)})',
              selected: _selectedStatus == status,
              onTap: () => setState(() => _selectedStatus = status),
            ),
          );
        }).toList(),
      ),
    );
  }

  void _showFiltersSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        const statuses = ['published', 'draft', 'closed', 'cancelled'];
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Filter jobs',
                  style: TextStyle(
                    color: _JobsPalette.navy,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: statuses.map((status) {
                    return _ReferenceStatusChip(
                      label: '${_pretty(status)} (${_statusCount(status)})',
                      selected: _selectedStatus == status,
                      onTap: () {
                        Navigator.pop(context);
                        setState(() => _selectedStatus = status);
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _JobsPalette {
  static const background = Color(0xFFF9FCFD);
  static const navy = Color(0xFF082A43);
  static const muted = Color(0xFF74879A);
  static const teal = Color(0xFF19A7B9);
  static const tealDark = Color(0xFF0D8F9E);
  static const mint = Color(0xFF19A97F);
  static const line = Color(0xFFE6EDF0);
  static const softBlue = Color(0xFFF0F7FA);
  static const softGreen = Color(0xFFE9F9F4);
  static const softOrange = Color(0xFFFFF4E8);
}

class _PostJobFloatingButton extends StatelessWidget {
  const _PostJobFloatingButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(26),
        child: Ink(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF17A9BE), Color(0xFF108EA6)],
            ),
            borderRadius: BorderRadius.circular(26),
            boxShadow: [
              BoxShadow(
                color: _JobsPalette.teal.withOpacity(.24),
                blurRadius: 18,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add_rounded, color: Colors.white, size: 24),
              SizedBox(width: 7),
              Text(
                'Post Job',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CompanyJobCard extends StatelessWidget {
  const _CompanyJobCard({
    required this.job,
    required this.onTap,
  });

  final _JobListSnapshot job;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final visual = _statusVisual(job.status);
    final isPublished = job.status.toLowerCase() == 'published';
    final isDraft = job.status.toLowerCase() == 'draft';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: const EdgeInsets.fromLTRB(12, 11, 12, 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _JobsPalette.line),
            boxShadow: [
              BoxShadow(
                color: _JobsPalette.navy.withOpacity(.025),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _JobThumbnail(job: job),
                  const SizedBox(width: 11),
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
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: _JobsPalette.navy,
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -.1,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    job.serviceCategory.isEmpty
                                        ? '#${job.id}'
                                        : '${_pretty(job.serviceCategory)} · #${job.id}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: _JobsPalette.muted,
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                              decoration: BoxDecoration(
                                color: visual.background,
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: Text(
                                _pretty(job.status),
                                style: TextStyle(
                                  color: visual.foreground,
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _InlineMeta(
                                icon: Icons.location_on_outlined,
                                text: job.location,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _InlineMeta(
                                icon: Icons.calendar_today_outlined,
                                text: job.referenceDateRange,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _PaymentMeta(label: job.referencePaymentLabel),
                  ),
                  const SizedBox(width: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.people_alt_outlined,
                        size: 16,
                        color: _JobsPalette.muted,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        '${job.applicantsCount} applicant${job.applicantsCount == 1 ? '' : 's'}',
                        style: const TextStyle(
                          color: _JobsPalette.muted,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 9),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onTap,
                  borderRadius: BorderRadius.circular(10),
                  child: Ink(
                    height: 34,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: _JobsPalette.softBlue,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            isDraft
                                ? 'Edit job'
                                : isPublished
                                ? 'View applicants'
                                : 'View job',
                            style: const TextStyle(
                              color: _JobsPalette.tealDark,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right_rounded,
                          color: _JobsPalette.tealDark,
                          size: 19,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _JobThumbnail extends StatelessWidget {
  const _JobThumbnail({required this.job});

  final _JobListSnapshot job;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(11),
      child: SizedBox(
        width: 78,
        height: 70,
        child: job.imageUrl.isNotEmpty
            ? Image.network(
          job.imageUrl,
          fit: BoxFit.cover,
          alignment: Alignment.center,
          errorBuilder: (_, __, ___) => _CategoryThumbnail(category: job.serviceCategory),
        )
            : _CategoryThumbnail(category: job.serviceCategory),
      ),
    );
  }
}

class _CategoryThumbnail extends StatelessWidget {
  const _CategoryThumbnail({required this.category});

  final String category;

  @override
  Widget build(BuildContext context) {
    final categoryLower = category.toLowerCase();
    final icon = categoryLower.contains('survey') || categoryLower.contains('mapping')
        ? Icons.solar_power_outlined
        : categoryLower.contains('inspection')
        ? Icons.cell_tower_rounded
        : categoryLower.contains('photo')
        ? Icons.landscape_outlined
        : Icons.flight_takeoff_rounded;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF4B9BB1), Color(0xFF1B526C)],
        ),
      ),
      alignment: Alignment.center,
      child: Icon(icon, color: Colors.white, size: 26),
    );
  }
}

class _InlineMeta extends StatelessWidget {
  const _InlineMeta({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: _JobsPalette.muted),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _JobsPalette.muted,
              fontSize: 10.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

class _PaymentMeta extends StatelessWidget {
  const _PaymentMeta({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(
          Icons.payments_outlined,
          size: 16,
          color: _JobsPalette.mint,
        ),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _JobsPalette.mint,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _ReferenceStatusChip extends StatelessWidget {
  const _ReferenceStatusChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 170),
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: selected ? _JobsPalette.teal : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected ? _JobsPalette.teal : _JobsPalette.line,
            ),
            boxShadow: selected
                ? [
              BoxShadow(
                color: _JobsPalette.teal.withOpacity(.17),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ]
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : _JobsPalette.navy,
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyJobsView extends StatelessWidget {
  const _EmptyJobsView({required this.status});

  final String? status;

  @override
  Widget build(BuildContext context) {
    final message = status == null
        ? 'You have not created any jobs yet.'
        : 'No ${_pretty(status!)} jobs found.';

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 70, 20, 120),
      children: [
        Container(
          width: 72,
          height: 72,
          margin: const EdgeInsets.symmetric(horizontal: 110),
          decoration: BoxDecoration(
            color: AppColors.blueBg,
            borderRadius: BorderRadius.circular(22),
          ),
          child: const Icon(
            Icons.work_outline_rounded,
            size: 32,
            color: AppColors.blue,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.navy,
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 5),
        Text(AppLanguage.text('Pull down to refresh or create a new job posting.'),
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.grey,
            fontSize: 11.5,
            height: 1.4,
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
            const Icon(
              Icons.cloud_off_rounded,
              size: 44,
              color: AppColors.grey,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.grey,
                fontSize: 12.5,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onRetry,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.blue,
              ),
              child: Text(AppLanguage.text('Try Again'),
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

class _JobsPageShimmer extends StatelessWidget {
  const _JobsPageShimmer();

  @override
  Widget build(BuildContext context) {
    return const _ShimmerAnimator(
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 15, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ShimmerBox(width: 88, height: 16, radius: 6),
            SizedBox(height: 7),
            _ShimmerBox(width: 155, height: 9, radius: 5),
            SizedBox(height: 14),
            Row(
              children: [
                Expanded(child: _ShimmerBox(height: 43, radius: 14)),
                SizedBox(width: 8),
                _ShimmerBox(width: 43, height: 43, radius: 14),
              ],
            ),
            SizedBox(height: 11),
            Row(
              children: [
                _ShimmerBox(width: 94, height: 36, radius: 18),
                SizedBox(width: 7),
                _ShimmerBox(width: 75, height: 36, radius: 18),
                SizedBox(width: 7),
                _ShimmerBox(width: 78, height: 36, radius: 18),
              ],
            ),
            SizedBox(height: 12),
            Expanded(
              child: SingleChildScrollView(
                physics: NeverScrollableScrollPhysics(),
                child: Column(
                  children: [
                    _JobCardSkeleton(),
                    SizedBox(height: 10),
                    _JobCardSkeleton(),
                    SizedBox(height: 10),
                    _JobCardSkeleton(),
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

class _JobCardSkeleton extends StatelessWidget {
  const _JobCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 11, 12, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _JobsPalette.line),
      ),
      child: const Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ShimmerBox(width: 78, height: 70, radius: 11),
              SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: _ShimmerBox(height: 12, radius: 5)),
                        SizedBox(width: 10),
                        _ShimmerBox(width: 62, height: 26, radius: 13),
                      ],
                    ),
                    SizedBox(height: 7),
                    _ShimmerBox(width: 105, height: 8, radius: 5),
                    SizedBox(height: 15),
                    Row(
                      children: [
                        Expanded(child: _ShimmerBox(height: 9, radius: 5)),
                        SizedBox(width: 10),
                        Expanded(child: _ShimmerBox(height: 9, radius: 5)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 11),
          Row(
            children: [
              Expanded(child: _ShimmerBox(height: 10, radius: 5)),
              SizedBox(width: 18),
              _ShimmerBox(width: 78, height: 10, radius: 5),
            ],
          ),
          SizedBox(height: 10),
          _ShimmerBox(height: 34, radius: 10),
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
          shaderCallback: (bounds) {
            return LinearGradient(
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

class _JobListSnapshot {
  const _JobListSnapshot({
    required this.id,
    required this.title,
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
    required this.imageUrl,
    required this.applicantsCount,
  });

  final int id;
  final String title;
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
  final String imageUrl;
  final int applicantsCount;

  factory _JobListSnapshot.fromModel(CompanyJobPostingModel job) {
    return _JobListSnapshot(
      id: job.id,
      title: job.title,
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
      imageUrl: _readJobImage(job),
      applicantsCount: _readApplicantsCount(job),
    );
  }

  factory _JobListSnapshot.fromJson(Map<String, dynamic> json) {
    return _JobListSnapshot(
      id: _asInt(json['id']),
      title: _asString(json['title']),
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
      imageUrl: _asString(json['image_url']),
      applicantsCount: _asInt(json['applicants_count']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
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
      'image_url': imageUrl,
      'applicants_count': applicantsCount,
    };
  }

  String get location {
    final parts = <String>[
      if (city.trim().isNotEmpty) city.trim(),
      if (state.trim().isNotEmpty) state.trim(),
      if (country.trim().isNotEmpty) country.trim(),
    ];

    if (parts.isEmpty && region.trim().isNotEmpty) {
      return region.trim();
    }

    return parts.isEmpty ? 'Location not specified' : parts.join(', ');
  }

  String get dateRange {
    final start = _formatDate(startDate);
    final end = _formatDate(endDate);
    if (start == '—' && end == '—') return 'Date not specified';
    if (end == '—' || start == end) return start;
    return '$start → $end';
  }

  String get paymentLabel {
    if (paymentType.toLowerCase() == 'negotiable') return 'Negotiable';

    final type = _pretty(paymentType);
    final min = _money(paymentMin);
    final max = _money(paymentMax);

    if (paymentMin == null && paymentMax == null) {
      return type.isEmpty ? 'Payment not specified' : type;
    }

    if (paymentMax == null) {
      return type.isEmpty ? '\$$min' : '$type · \$$min';
    }

    return type.isEmpty
        ? '\$$min - \$$max'
        : '$type · \$$min - \$$max';
  }

  String get referenceDateRange => _formatDateRangeReference(startDate, endDate);

  String get referencePaymentLabel {
    if (paymentType.toLowerCase() == 'negotiable') return 'Negotiable';

    final type = _pretty(paymentType);
    final min = _money(paymentMin);
    final max = _money(paymentMax);

    if (paymentMin == null && paymentMax == null) {
      return type.isEmpty ? 'Payment not specified' : type;
    }
    if (paymentMax == null) {
      return type.isEmpty ? '\$$min' : '$type · \$$min';
    }
    return type.isEmpty
        ? '\$$min – \$$max'
        : '$type · \$$min – \$$max';
  }
}

String _readJobImage(dynamic job) {
  dynamic value;

  try { value = job.imageUrl; } catch (_) {}
  if (_cleanDynamicString(value).isNotEmpty) return _cleanDynamicString(value);

  try { value = job.coverImage; } catch (_) {}
  if (_cleanDynamicString(value).isNotEmpty) return _cleanDynamicString(value);

  try { value = job.coverImageUrl; } catch (_) {}
  if (_cleanDynamicString(value).isNotEmpty) return _cleanDynamicString(value);

  try { value = job.photo; } catch (_) {}
  if (_cleanDynamicString(value).isNotEmpty) return _cleanDynamicString(value);

  try { value = job.photoUrl; } catch (_) {}
  if (_cleanDynamicString(value).isNotEmpty) return _cleanDynamicString(value);

  try {
    final dynamic images = job.images;
    if (images is List && images.isNotEmpty) {
      final first = images.first;
      if (first is String && first.trim().isNotEmpty) return first.trim();
      if (first is Map) {
        final map = Map<String, dynamic>.from(first);
        for (final key in ['url', 'image_url', 'path']) {
          final text = _cleanDynamicString(map[key]);
          if (text.isNotEmpty) return text;
        }
      }
    }
  } catch (_) {}

  return '';
}

int _readApplicantsCount(dynamic job) {
  dynamic value;
  try { value = job.applicantsCount; } catch (_) {}
  if (value != null) return _asInt(value);

  try { value = job.applicationsCount; } catch (_) {}
  if (value != null) return _asInt(value);

  try { value = job.applicantCount; } catch (_) {}
  if (value != null) return _asInt(value);

  try {
    final dynamic applicants = job.applicants;
    if (applicants is List) return applicants.length;
  } catch (_) {}

  try {
    final dynamic applications = job.applications;
    if (applications is List) return applications.length;
  } catch (_) {}

  return 0;
}

String _cleanDynamicString(dynamic value) {
  if (value == null) return '';
  final text = value.toString().trim();
  return text == 'null' ? '' : text;
}

String _formatDateRangeReference(DateTime? start, DateTime? end) {
  if (start == null && end == null) return 'Date not specified';
  if (start != null && end == null) {
    return _formatReferenceDate(start, includeYear: true);
  }
  if (start == null && end != null) {
    return _formatReferenceDate(end, includeYear: true);
  }

  final s = start!;
  final e = end!;

  if (s.year == e.year) {
    if (s.month == e.month && s.day == e.day) {
      return _formatReferenceDate(s, includeYear: true);
    }
    return '${_monthName(s.month)} ${s.day} – ${_monthName(e.month)} ${e.day}, ${e.year}';
  }

  return '${_formatReferenceDate(s, includeYear: true)} – ${_formatReferenceDate(e, includeYear: true)}';
}

String _formatReferenceDate(DateTime date, {required bool includeYear}) {
  final base = '${_monthName(date.month)} ${date.day}';
  return includeYear ? '$base, ${date.year}' : base;
}

String _monthName(int month) {
  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  if (month < 1 || month > 12) return '';
  return months[month - 1];
}

class _VisualPair {
  const _VisualPair(this.foreground, this.background);

  final Color foreground;
  final Color background;
}

_VisualPair _statusVisual(String status) {
  switch (status.toLowerCase()) {
    case 'published':
      return const _VisualPair(Color(0xFF169C7C), Color(0xFFE7F8F2));
    case 'draft':
      return const _VisualPair(Color(0xFFE79A34), Color(0xFFFFF3E4));
    case 'cancelled':
      return _VisualPair(Colors.red.shade700, Colors.red.shade50);
    case 'closed':
      return const _VisualPair(Color(0xFF708295), Color(0xFFF0F3F5));
    default:
      return const _VisualPair(AppColors.grey, AppColors.blueBg);
  }
}

String _pretty(String value) {
  final clean = value.trim();
  if (clean.isEmpty) return '';

  return clean
      .split('_')
      .where((part) => part.isNotEmpty)
      .map(
        (part) =>
    '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}',
  )
      .join(' ');
}

String _formatDate(DateTime? date) {
  if (date == null) return '—';
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}-$month-$day';
}

String _money(double? value) {
  if (value == null) return '';
  if (value == value.roundToDouble()) return value.toStringAsFixed(0);
  return value.toStringAsFixed(2);
}

int _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

double? _asDouble(dynamic value) {
  if (value == null) return null;
  if (value is double) return value;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}

String _asString(dynamic value) => value?.toString() ?? '';

DateTime? _asDate(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  return DateTime.tryParse(value.toString());
}
