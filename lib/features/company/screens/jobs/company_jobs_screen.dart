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
  String? _selectedStatus;
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
        builder: (_) => const PostJobScreen(),
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
    final jobs = List<_JobListSnapshot>.from(_jobs);
    if (_selectedStatus == null) return jobs;

    return jobs
        .where(
          (job) => job.status.toLowerCase() == _selectedStatus,
    )
        .toList(growable: false);
  }

  int get _publishedCount => _jobs
      .where((job) => job.status.toLowerCase() == 'published')
      .length;

  bool get _showInitialShimmer =>
      !_cachePresent &&
          !_firstNetworkAttemptFinished &&
          (_jobs.isEmpty || !_cacheReadFinished);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      floatingActionButton: _showInitialShimmer
          ? null
          : FloatingActionButton.extended(
        onPressed: _openPostJob,
        backgroundColor: AppColors.blue,
        foregroundColor: Colors.white,
        elevation: 3,
        icon: const Icon(Icons.add_rounded, size: 19),
        label: const Text(
          'Post Job',
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: Stack(
        children: [
          Positioned(
            top: -150,
            right: -130,
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
          SafeArea(
            child: _showInitialShimmer
                ? const _JobsPageShimmer()
                : _errorMessage != null && _jobs.isEmpty
                ? _ErrorView(
              message: _errorMessage!,
              onRetry: () => _refreshFromNetwork(),
            )
                : _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final visible = _visibleJobs;

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
                      'My Jobs',
                      style: TextStyle(
                        color: AppColors.navy,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.15,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${_jobs.length} postings · $_publishedCount published',
                      style: const TextStyle(
                        color: AppColors.grey,
                        fontSize: 11.8,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: _networkRefreshing
                    ? Container(
                  key: const ValueKey('syncing'),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 6,
                  ),
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
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                )
                    : const SizedBox.shrink(
                  key: ValueKey('idle'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        _statusFilters(),
        const SizedBox(height: 14),
        Expanded(
          child: RefreshIndicator(
            color: AppColors.blue,
            onRefresh: _manualRefresh,
            child: visible.isEmpty
                ? _EmptyJobsView(status: _selectedStatus)
                : ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
              itemCount: visible.length,
              separatorBuilder: (_, __) =>
              const SizedBox(height: 11),
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
    const statuses = ['draft', 'published', 'closed', 'cancelled'];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          _FilterChip(
            label: 'All',
            selected: _selectedStatus == null,
            onTap: () => setState(() => _selectedStatus = null),
          ),
          const SizedBox(width: 8),
          ...statuses.map(
                (status) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _FilterChip(
                label: _pretty(status),
                selected: _selectedStatus == status,
                onTap: () => setState(() => _selectedStatus = status),
              ),
            ),
          ),
        ],
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
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.blue.withOpacity(0.15),
                          AppColors.blueBg,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.work_outline_rounded,
                      color: AppColors.blue,
                      size: 21,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          job.title.isEmpty ? 'Untitled Job' : job.title,
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
                          job.serviceCategory.isEmpty
                              ? 'Job #${job.id}'
                              : '${_pretty(job.serviceCategory)} · #${job.id}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.grey,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: visual.background,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _pretty(job.status),
                      style: TextStyle(
                        color: visual.foreground,
                        fontSize: 10.2,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _MiniInfo(
                      icon: Icons.calendar_today_outlined,
                      value: job.dateRange,
                    ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: _MiniInfo(
                      icon: Icons.location_on_outlined,
                      value: job.location,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppColors.bg,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.payments_outlined,
                      color: AppColors.green,
                      size: 17,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        job.paymentLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.green,
                          fontSize: 13.2,
                          fontWeight: FontWeight.w900,
                        ),
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
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniInfo extends StatelessWidget {
  const _MiniInfo({required this.icon, required this.value});

  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.grey),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.grey,
              fontSize: 11.5,
            ),
          ),
        ),
      ],
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
        fontSize: 11.5,
        fontWeight: FontWeight.w800,
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
        const Text(
          'Pull down to refresh or create a new job posting.',
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
              child: const Text(
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

class _JobsPageShimmer extends StatelessWidget {
  const _JobsPageShimmer();

  @override
  Widget build(BuildContext context) {
    return const _ShimmerAnimator(
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ShimmerBox(width: 92, height: 16, radius: 6),
            SizedBox(height: 8),
            _ShimmerBox(width: 170, height: 10, radius: 5),
            SizedBox(height: 20),
            Row(
              children: [
                _ShimmerBox(width: 58, height: 32, radius: 16),
                SizedBox(width: 8),
                _ShimmerBox(width: 75, height: 32, radius: 16),
                SizedBox(width: 8),
                _ShimmerBox(width: 84, height: 32, radius: 16),
              ],
            ),
            SizedBox(height: 18),
            Expanded(
              child: SingleChildScrollView(
                physics: NeverScrollableScrollPhysics(),
                child: Column(
                  children: [
                    _JobCardSkeleton(),
                    SizedBox(height: 11),
                    _JobCardSkeleton(),
                    SizedBox(height: 11),
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
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: const Column(
        children: [
          Row(
            children: [
              _ShimmerBox(width: 44, height: 44, radius: 14),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ShimmerBox(width: 150, height: 13, radius: 5),
                    SizedBox(height: 8),
                    _ShimmerBox(width: 105, height: 9, radius: 5),
                  ],
                ),
              ),
              _ShimmerBox(width: 62, height: 24, radius: 12),
            ],
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _ShimmerBox(height: 12, radius: 5)),
              SizedBox(width: 18),
              Expanded(child: _ShimmerBox(height: 12, radius: 5)),
            ],
          ),
          SizedBox(height: 14),
          _ShimmerBox(height: 38, radius: 12),
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
}

class _VisualPair {
  const _VisualPair(this.foreground, this.background);

  final Color foreground;
  final Color background;
}

_VisualPair _statusVisual(String status) {
  switch (status.toLowerCase()) {
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
