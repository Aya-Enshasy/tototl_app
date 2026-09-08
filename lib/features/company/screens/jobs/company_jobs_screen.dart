import 'package:flutter/material.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_colors.dart';

import '../../controllers/company_job_controller.dart';
import '../../models/company_job_posting_model.dart';
import '../../services/company_job_service.dart';

import 'company_job_detail_screen.dart';
import 'post_job_screen.dart';

class CompanyJobsScreen extends StatefulWidget {
  const CompanyJobsScreen({super.key});

  @override
  State<CompanyJobsScreen> createState() =>
      _CompanyJobsScreenState();
}

class _CompanyJobsScreenState extends State<CompanyJobsScreen> {
  late final CompanyJobController _controller;

  String? _selectedStatus;

  bool _loading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();

    _controller = CompanyJobController(
      CompanyJobService(ApiClient()),
    );

    _loadJobs();
  }

  Future<void> _loadJobs() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _errorMessage = null;
      });
    }

    final success = await _controller.loadMyJobs();

    if (!mounted) return;

    setState(() {
      _loading = false;

      if (!success) {
        _errorMessage =
            _controller.errorMessage ?? 'Unable to load jobs.';
      }
    });
  }

  Future<void> _refreshJobs() async {
    final success = await _controller.loadMyJobs();

    if (!mounted) return;

    setState(() {
      _errorMessage =
          success ? null : _controller.errorMessage;
    });
  }

  Future<void> _openJob(
    CompanyJobPostingModel job,
  ) async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => CompanyJobDetailScreen(
          jobId: job.id,
        ),
      ),
    );

    if (!mounted) return;

    // Always refresh when returning. The detail screen can edit, publish,
    // or delete a Draft, so the My Jobs list must stay authoritative.
    await _refreshJobs();
  }

  List<CompanyJobPostingModel> get _visibleJobs {
    final jobs = List<CompanyJobPostingModel>.from(
      _controller.jobs,
    );

    if (_selectedStatus == null) {
      return jobs;
    }

    return jobs
        .where(
          (job) =>
              job.status.toLowerCase() == _selectedStatus,
        )
        .toList();
  }

  int get _publishedCount => _controller.jobs
      .where(
        (job) => job.status.toLowerCase() == 'published',
      )
      .length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const PostJobScreen(),
            ),
          );

          if (mounted) {
            await _refreshJobs();
          }
        },
        backgroundColor: AppColors.blue,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text(
          'Post Job',
          style: TextStyle(
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SafeArea(
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : _errorMessage != null
                ? _ErrorView(
                    message: _errorMessage!,
                    onRetry: _loadJobs,
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.fromLTRB(
                          20,
                          24,
                          20,
                          6,
                        ),
                        child: Text(
                          'My Jobs',
                          style: TextStyle(
                            color: AppColors.navy,
                            fontSize: 25,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                        ),
                        child: Text(
                          '${_controller.jobs.length} job postings · $_publishedCount published',
                          style: const TextStyle(
                            color: AppColors.grey,
                            fontSize: 13.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      _statusFilters(),
                      const SizedBox(height: 14),
                      Expanded(
                        child: RefreshIndicator(
                          onRefresh: _refreshJobs,
                          child: _visibleJobs.isEmpty
                              ? _EmptyJobsView(
                                  status: _selectedStatus,
                                )
                              : ListView.separated(
                                  physics:
                                      const AlwaysScrollableScrollPhysics(),
                                  padding:
                                      const EdgeInsets.fromLTRB(
                                    20,
                                    0,
                                    20,
                                    100,
                                  ),
                                  itemCount: _visibleJobs.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(height: 12),
                                  itemBuilder: (_, index) {
                                    final job =
                                        _visibleJobs[index];

                                    return _CompanyJobCard(
                                      job: job,
                                      onTap: () => _openJob(job),
                                    );
                                  },
                                ),
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }

  Widget _statusFilters() {
    const statuses = [
      'draft',
      'published',
      'closed',
      'cancelled',
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
      ),
      child: Row(
        children: [
          _FilterChip(
            label: 'All',
            selected: _selectedStatus == null,
            onTap: () {
              setState(() {
                _selectedStatus = null;
              });
            },
          ),
          const SizedBox(width: 8),
          ...statuses.map(
            (status) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _FilterChip(
                label: _pretty(status),
                selected: _selectedStatus == status,
                onTap: () {
                  setState(() {
                    _selectedStatus = status;
                  });
                },
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

  final CompanyJobPostingModel job;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final status = job.status.toLowerCase();
    final visual = _statusVisual(status);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: AppColors.cardBorder,
            ),
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
                      color: AppColors.blueBg,
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: const Icon(
                      Icons.work_outline_rounded,
                      color: AppColors.blue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          job.title.isEmpty
                              ? 'Untitled Job'
                              : job.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.navy,
                            fontSize: 15.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _secondaryLine(job),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: visual.background,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _pretty(status),
                      style: TextStyle(
                        color: visual.foreground,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              Row(
                children: [
                  const Icon(
                    Icons.calendar_today_outlined,
                    size: 14,
                    color: AppColors.grey,
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      _dateRange(job),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.grey,
                        fontSize: 12.5,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 9),
              Row(
                children: [
                  const Icon(
                    Icons.location_on_outlined,
                    size: 15,
                    color: AppColors.grey,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      _location(job),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.grey,
                        fontSize: 12.5,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _payment(job),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.green,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.lightGrey,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _secondaryLine(CompanyJobPostingModel job) {
    final category = _pretty(job.serviceCategory);
    final idText = '#${job.id}';

    if (category.isEmpty) {
      return 'Job $idText';
    }

    return '$category · Job $idText';
  }

  String _location(CompanyJobPostingModel job) {
    final parts = <String>[
      if (job.city.isNotEmpty) job.city,
      if (job.state.isNotEmpty) job.state,
      if (job.country.isNotEmpty) job.country,
    ];

    if (parts.isEmpty && job.region.isNotEmpty) {
      return job.region;
    }

    if (parts.isEmpty) {
      return 'Location not specified';
    }

    return parts.join(', ');
  }

  String _dateRange(CompanyJobPostingModel job) {
    final start = _formatDate(job.startDate);
    final end = _formatDate(job.endDate);

    if (start == '—' && end == '—') {
      return 'Date not specified';
    }

    if (end == '—' || start == end) {
      return start;
    }

    return '$start → $end';
  }

  String _payment(CompanyJobPostingModel job) {
    final type = _pretty(job.paymentType);

    if (job.paymentType.toLowerCase() == 'negotiable') {
      return 'Negotiable';
    }

    final min = _money(job.paymentMin);
    final max = _money(job.paymentMax);

    if (job.paymentMin == null && job.paymentMax == null) {
      return type.isEmpty ? 'Payment not specified' : type;
    }

    if (job.paymentMax == null) {
      return type.isEmpty ? '\$$min' : '$type · \$$min';
    }

    return type.isEmpty
        ? '\$$min - \$$max'
        : '$type · \$$min - \$$max';
  }

  String _money(double? value) {
    if (value == null) return '';

    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }

    return value.toStringAsFixed(2);
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '—';

    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    return '${date.year}-$month-$day';
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
      labelStyle: TextStyle(
        color: selected ? Colors.white : AppColors.navy,
        fontWeight: FontWeight.w700,
        fontSize: 12.5,
      ),
      backgroundColor: Colors.white,
      side: BorderSide(
        color:
            selected ? AppColors.blue : AppColors.cardBorder,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }
}

class _EmptyJobsView extends StatelessWidget {
  const _EmptyJobsView({
    required this.status,
  });

  final String? status;

  @override
  Widget build(BuildContext context) {
    final message = status == null
        ? 'You have not created any jobs yet.'
        : 'No ${_pretty(status!)} jobs found.';

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        20,
        60,
        20,
        120,
      ),
      children: [
        const Icon(
          Icons.work_outline_rounded,
          size: 52,
          color: AppColors.lightGrey,
        ),
        const SizedBox(height: 14),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.grey,
            fontSize: 14,
            fontWeight: FontWeight.w600,
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
              Icons.error_outline_rounded,
              size: 48,
              color: AppColors.grey,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.grey,
                fontSize: 13.5,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onRetry,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.blue,
              ),
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}

class _VisualPair {
  final Color foreground;
  final Color background;

  const _VisualPair(
    this.foreground,
    this.background,
  );
}

_VisualPair _statusVisual(String status) {
  switch (status.toLowerCase()) {
    case 'published':
      return const _VisualPair(
        AppColors.green,
        AppColors.greenBg,
      );

    case 'draft':
      return const _VisualPair(
        AppColors.orange,
        AppColors.orangeBg,
      );

    case 'cancelled':
      return _VisualPair(
        Colors.red.shade700,
        Colors.red.shade50,
      );

    case 'closed':
      return _VisualPair(
        AppColors.grey,
        Colors.grey.shade100,
      );

    default:
      return const _VisualPair(
        AppColors.grey,
        AppColors.blueBg,
      );
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
