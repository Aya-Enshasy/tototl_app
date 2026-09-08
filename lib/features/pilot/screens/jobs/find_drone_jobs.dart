import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tototl_app/core/network/api_client.dart';
import 'package:tototl_app/core/theme/app_colors.dart';

import '../../controllers/pilot_job_controller.dart';
import '../../models/pilot_job_filters.dart';
import '../../models/pilot_job_model.dart';
import '../../services/pilot_job_service.dart';
import 'job_details.dart';

class FindDroneJobsScreen extends StatefulWidget {
  const FindDroneJobsScreen({super.key});

  @override
  State<FindDroneJobsScreen> createState() =>
      _FindDroneJobsScreenState();
}

class _FindDroneJobsScreenState extends State<FindDroneJobsScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController =
      TextEditingController();
  final ScrollController _scrollController = ScrollController();

  late final PilotJobController _controller;
  late final AnimationController _pageAnimationController;

  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();

    _controller = PilotJobController(
      PilotJobService(ApiClient()),
    );

    _pageAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();

    _searchController.addListener(_onSearchChanged);
    _scrollController.addListener(_onScroll);

    _controller.loadInitial();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _scrollController.removeListener(_onScroll);
    _searchController.dispose();
    _scrollController.dispose();
    _pageAnimationController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;

    final position = _scrollController.position;

    if (position.pixels >= position.maxScrollExtent - 420) {
      _controller.loadMore();
    }
  }

  void _onSearchChanged() {
    setState(() {});

    _searchDebounce?.cancel();
    _searchDebounce = Timer(
      const Duration(milliseconds: 450),
      () {
        if (!mounted) return;
        _controller.updateSearch(_searchController.text);
      },
    );
  }

  Future<void> _openFilters() async {
    HapticFeedback.selectionClick();

    final result = await showModalBottomSheet<PilotJobFilters>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _JobFilterSheet(
        initial: _controller.filters,
      ),
    );

    if (result == null || !mounted) return;

    await _controller.applyFilters(
      result.copyWith(search: _searchController.text.trim()),
    );
  }

  Future<void> _clearAll() async {
    _searchDebounce?.cancel();
    _searchController.clear();
    await _controller.applyFilters(const PilotJobFilters());
  }

  Future<void> _openJob(PilotJobModel job) async {
    HapticFeedback.selectionClick();

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => JobDetailsScreen(jobId: job.id),
      ),
    );
  }

  Widget _animatedEntry({
    required int index,
    required Widget child,
  }) {
    final start = (index * 0.07).clamp(0.0, 0.60).toDouble();
    final end = (start + 0.35).clamp(0.0, 1.0).toDouble();

    final animation = CurvedAnimation(
      parent: _pageAnimationController,
      curve: Interval(start, end, curve: Curves.easeOutCubic),
    );

    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.025),
          end: Offset.zero,
        ).animate(animation),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: AppColors.bg,
          body: Stack(
            children: [
              _backgroundGlow(),
              SafeArea(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _animatedEntry(index: 0, child: _header()),
                          const SizedBox(height: 18),
                          _animatedEntry(
                            index: 1,
                            child: _searchAndFilter(),
                          ),
                          if (_controller.filters.hasAdvancedFilters) ...[
                            const SizedBox(height: 11),
                            _activeFilters(),
                          ],
                          const SizedBox(height: 14),
                          _resultsRow(),
                          const SizedBox(height: 13),
                        ],
                      ),
                    ),
                    Expanded(child: _body()),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _backgroundGlow() {
    return Stack(
      children: [
        Positioned(
          top: -160,
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
          top: 470,
          left: -150,
          child: IgnorePointer(
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.logoTurquoise.withOpacity(0.035),
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

  Widget _header() {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.blue.withOpacity(0.08),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(
            Icons.travel_explore_rounded,
            color: AppColors.blue,
            size: 21,
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Find Drone Jobs',
                style: TextStyle(
                  color: AppColors.navy,
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.45,
                  height: 1.1,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Published opportunities ready for pilots',
                style: TextStyle(
                  color: AppColors.grey,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _searchAndFilter() {
    return Row(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(17),
              boxShadow: [
                BoxShadow(
                  color: AppColors.navy.withOpacity(0.025),
                  blurRadius: 14,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              textInputAction: TextInputAction.search,
              style: const TextStyle(
                color: AppColors.navy,
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                hintText: 'Search title, location, service...',
                hintStyle: TextStyle(
                  color: AppColors.grey.withOpacity(0.78),
                  fontSize: 12.2,
                ),
                prefixIcon: Container(
                  margin: const EdgeInsets.all(11),
                  decoration: BoxDecoration(
                    color: AppColors.blue.withOpacity(0.07),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.search_rounded,
                    color: AppColors.blue,
                    size: 18,
                  ),
                ),
                suffixIcon: _searchController.text.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Clear search',
                        onPressed: () {
                          HapticFeedback.selectionClick();
                          _searchController.clear();
                        },
                        icon: const Icon(
                          Icons.close_rounded,
                          color: AppColors.grey,
                          size: 18,
                        ),
                      ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 15),
                border: _inputBorder(AppColors.cardBorder),
                enabledBorder: _inputBorder(AppColors.cardBorder),
                focusedBorder: _inputBorder(AppColors.blue, width: 1.25),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        _filterButton(),
      ],
    );
  }

  Widget _filterButton() {
    final count = _controller.filters.activeFilterCount;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(17),
      child: InkWell(
        borderRadius: BorderRadius.circular(17),
        onTap: _openFilters,
        child: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(17),
            border: Border.all(
              color: count > 0 ? AppColors.blue : AppColors.cardBorder,
              width: count > 0 ? 1.15 : 0.8,
            ),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(
                Icons.tune_rounded,
                color: count > 0 ? AppColors.blue : AppColors.navy,
                size: 20,
              ),
              if (count > 0)
                Positioned(
                  top: 7,
                  right: 7,
                  child: Container(
                    width: 17,
                    height: 17,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: AppColors.blue,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$count',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8.5,
                        fontWeight: FontWeight.w800,
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

  Widget _activeFilters() {
    final f = _controller.filters;

    final labels = <String>[
      if (f.category.isNotEmpty) _pretty(f.category),
      if (f.city.isNotEmpty) f.city,
      if (f.country.isNotEmpty) f.country,
      if (f.paymentMin != null || f.paymentMax != null) 'Budget',
      if (f.dateFrom != null || f.dateTo != null) 'Dates',
      if (f.capabilities.isNotEmpty) '${f.capabilities.length} capabilities',
      if (f.sort != 'newest') 'Sort: ${_sortLabel(f.sort)}',
    ];

    return SizedBox(
      height: 31,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          ...labels.map(
            (label) => Padding(
              padding: const EdgeInsets.only(right: 7),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.blue.withOpacity(0.055),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.blue.withOpacity(0.08),
                  ),
                ),
                child: Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.navy,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
          TextButton(
            onPressed: _controller.clearAdvancedFilters,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 7),
            ),
            child: const Text(
              'Clear',
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _resultsRow() {
    final count = _controller.total > 0
        ? _controller.total
        : _controller.jobs.length;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
          decoration: BoxDecoration(
            color: AppColors.blue.withOpacity(0.06),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.work_history_outlined,
                color: AppColors.blue,
                size: 13,
              ),
              const SizedBox(width: 5),
              Text(
                '$count jobs found',
                style: const TextStyle(
                  color: AppColors.navy,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.swap_vert_rounded,
                color: AppColors.blue,
                size: 13,
              ),
              const SizedBox(width: 4),
              Text(
                _sortLabel(_controller.filters.sort),
                style: const TextStyle(
                  color: AppColors.navy,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _body() {
    if (_controller.isInitialLoading) {
      return const _JobsShimmer();
    }

    if (_controller.errorMessage != null && _controller.jobs.isEmpty) {
      return _JobsError(
        message: _controller.errorMessage!,
        onRetry: _controller.loadInitial,
      );
    }

    if (_controller.jobs.isEmpty) {
      return _NoResults(onClear: _clearAll);
    }

    return RefreshIndicator(
      onRefresh: _controller.refresh,
      child: ListView.separated(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
        itemCount:
            _controller.jobs.length + (_controller.isLoadingMore ? 1 : 0),
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          if (index >= _controller.jobs.length) {
            return const _InlineShimmer();
          }

          final job = _controller.jobs[index];

          return _animatedEntry(
            index: 3 + (index > 6 ? 6 : index),
            child: _JobListCard(
              job: job,
              onTap: () => _openJob(job),
            ),
          );
        },
      ),
    );
  }

  OutlineInputBorder _inputBorder(Color color, {double width = 0.8}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(17),
      borderSide: BorderSide(color: color, width: width),
    );
  }

  String _sortLabel(String value) {
    switch (value) {
      case 'pay':
        return 'Pay';
      case 'date':
        return 'Date';
      default:
        return 'Newest';
    }
  }

  String _pretty(String value) {
    if (value.trim().isEmpty) return '';
    return value
        .split(RegExp(r'[_\s-]+'))
        .where((part) => part.isNotEmpty)
        .map(
          (part) =>
              '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}',
        )
        .join(' ');
  }
}

class _JobListCard extends StatefulWidget {
  const _JobListCard({
    required this.job,
    required this.onTap,
  });

  final PilotJobModel job;
  final VoidCallback onTap;

  @override
  State<_JobListCard> createState() => _JobListCardState();
}

class _JobListCardState extends State<_JobListCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final job = widget.job;

    return AnimatedScale(
      duration: const Duration(milliseconds: 120),
      scale: _pressed ? 0.985 : 1,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTapDown: (_) => setState(() => _pressed = true),
          onTapCancel: () => setState(() => _pressed = false),
          onTapUp: (_) => setState(() => _pressed = false),
          onTap: widget.onTap,
          child: Ink(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.cardBorder.withOpacity(0.9),
                width: 0.8,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.navy.withOpacity(0.035),
                  blurRadius: 18,
                  offset: const Offset(0, 7),
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
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.blueBg,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        _categoryIcon(job.serviceCategory),
                        color: AppColors.blue,
                        size: 22,
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
                              fontWeight: FontWeight.w800,
                              height: 1.25,
                              letterSpacing: -0.15,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            _subtitle(job),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.grey,
                              fontSize: 11.8,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 7),
                    Container(
                      width: 31,
                      height: 31,
                      decoration: BoxDecoration(
                        color: AppColors.blue.withOpacity(0.055),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.blue,
                        size: 19,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _InfoItem(
                        icon: Icons.location_on_outlined,
                        text: job.locationLabel,
                      ),
                    ),
                    const SizedBox(width: 9),
                    Flexible(
                      child: _InfoItem(
                        icon: Icons.calendar_today_outlined,
                        text: job.dateLabel,
                      ),
                    ),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  child: Divider(height: 1, color: AppColors.cardBorder),
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.green.withOpacity(0.075),
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: Text(
                          job.payLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.green,
                            fontSize: 13.2,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                    if (job.requiredCapabilities.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Expanded(
                        child: Wrap(
                          alignment: WrapAlignment.end,
                          spacing: 6,
                          runSpacing: 5,
                          children: [
                            ...job.requiredCapabilities.take(2).map(
                                  (item) => _CapabilityPill(label: item),
                                ),
                            if (job.requiredCapabilities.length > 2)
                              _CapabilityPill(
                                label: '+${job.requiredCapabilities.length - 2}',
                              ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _subtitle(PilotJobModel job) {
    final values = <String>[job.categoryLabel];

    if (job.droneSize.isNotEmpty) {
      values.add('${_pretty(job.droneSize)} drone');
    }

    return values.join(' · ');
  }

  IconData _categoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'inspection':
        return Icons.manage_search_rounded;
      case 'mapping':
        return Icons.map_outlined;
      case 'photography':
        return Icons.photo_camera_outlined;
      case 'construction':
        return Icons.construction_outlined;
      case 'surveying':
        return Icons.straighten_rounded;
      default:
        return Icons.flight_takeoff_rounded;
    }
  }

  String _pretty(String value) {
    if (value.trim().isEmpty) return '';
    return value
        .split(RegExp(r'[_\s-]+'))
        .where((part) => part.isNotEmpty)
        .map(
          (part) =>
              '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}',
        )
        .join(' ');
  }
}

class _InfoItem extends StatelessWidget {
  const _InfoItem({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.grey),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppColors.grey.withOpacity(0.9),
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

class _CapabilityPill extends StatelessWidget {
  const _CapabilityPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.blue.withOpacity(0.055),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: AppColors.blue.withOpacity(0.08)),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: AppColors.navy,
          fontSize: 9.5,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _NoResults extends StatelessWidget {
  const _NoResults({required this.onClear});

  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 70),
      children: [
        const Icon(
          Icons.search_off_rounded,
          color: AppColors.blue,
          size: 50,
        ),
        const SizedBox(height: 14),
        const Text(
          'No jobs match your search',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.navy,
            fontSize: 14.5,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Try changing the search or clearing the filters.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.grey,
            fontSize: 11.8,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 14),
        Center(
          child: TextButton.icon(
            onPressed: onClear,
            icon: const Icon(Icons.refresh_rounded, size: 17),
            label: const Text('Clear search & filters'),
          ),
        ),
      ],
    );
  }
}

class _JobsError extends StatelessWidget {
  const _JobsError({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              color: AppColors.blue,
              size: 46,
            ),
            const SizedBox(height: 13),
            const Text(
              'Couldn’t load jobs',
              style: TextStyle(
                color: AppColors.navy,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.grey,
                fontSize: 11.8,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              style: FilledButton.styleFrom(backgroundColor: AppColors.blue),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}

class _JobFilterSheet extends StatefulWidget {
  const _JobFilterSheet({required this.initial});

  final PilotJobFilters initial;

  @override
  State<_JobFilterSheet> createState() => _JobFilterSheetState();
}

class _JobFilterSheetState extends State<_JobFilterSheet> {
  late final TextEditingController _country;
  late final TextEditingController _state;
  late final TextEditingController _city;
  late final TextEditingController _region;
  late final TextEditingController _paymentMin;
  late final TextEditingController _paymentMax;

  late String _category;
  late String _sort;
  late Set<String> _capabilities;
  DateTime? _dateFrom;
  DateTime? _dateTo;

  static const categories = [
    'inspection',
    'mapping',
    'photography',
    'construction',
    'surveying',
    'other',
  ];

  static const capabilities = [
    'Thermal Camera',
    'RTK',
    'Zoom',
    'LiDAR',
    'Multispectral',
    'Night Vision',
    'Spotlight',
    'Winch',
  ];

  @override
  void initState() {
    super.initState();
    final f = widget.initial;

    _country = TextEditingController(text: f.country);
    _state = TextEditingController(text: f.state);
    _city = TextEditingController(text: f.city);
    _region = TextEditingController(text: f.region);
    _paymentMin = TextEditingController(text: _number(f.paymentMin));
    _paymentMax = TextEditingController(text: _number(f.paymentMax));

    _category = f.category;
    _sort = f.sort;
    _capabilities = f.capabilities.toSet();
    _dateFrom = f.dateFrom;
    _dateTo = f.dateTo;
  }

  @override
  void dispose() {
    _country.dispose();
    _state.dispose();
    _city.dispose();
    _region.dispose();
    _paymentMin.dispose();
    _paymentMax.dispose();
    super.dispose();
  }

  Future<void> _pickDates() async {
    final now = DateTime.now();

    final result = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
      initialDateRange: _dateFrom != null && _dateTo != null
          ? DateTimeRange(start: _dateFrom!, end: _dateTo!)
          : null,
    );

    if (result == null) return;

    setState(() {
      _dateFrom = result.start;
      _dateTo = result.end;
    });
  }

  void _apply() {
    final minText = _paymentMin.text.trim();
    final maxText = _paymentMax.text.trim();
    final min = minText.isEmpty ? null : double.tryParse(minText);
    final max = maxText.isEmpty ? null : double.tryParse(maxText);

    if (minText.isNotEmpty && min == null) {
      _snack('Enter a valid minimum payment.');
      return;
    }

    if (maxText.isNotEmpty && max == null) {
      _snack('Enter a valid maximum payment.');
      return;
    }

    if (min != null && max != null && max < min) {
      _snack('Maximum payment must be greater than or equal to minimum.');
      return;
    }

    Navigator.of(context).pop(
      PilotJobFilters(
        search: widget.initial.search,
        country: _country.text.trim(),
        state: _state.text.trim(),
        city: _city.text.trim(),
        region: _region.text.trim(),
        category: _category,
        dateFrom: _dateFrom,
        dateTo: _dateTo,
        paymentMin: min,
        paymentMax: max,
        capabilities: _capabilities.toList(),
        sort: _sort,
      ),
    );
  }

  void _reset() {
    setState(() {
      _country.clear();
      _state.clear();
      _city.clear();
      _region.clear();
      _paymentMin.clear();
      _paymentMax.clear();
      _category = '';
      _sort = 'newest';
      _capabilities.clear();
      _dateFrom = null;
      _dateTo = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.90,
      ),
      padding: EdgeInsets.fromLTRB(20, 10, 20, 18 + bottom),
      decoration: const BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      child: Column(
        children: [
          Container(
            width: 42,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.cardBorder,
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Filter Jobs',
                  style: TextStyle(
                    color: AppColors.navy,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              TextButton(onPressed: _reset, child: const Text('Reset')),
            ],
          ),
          Expanded(
            child: ListView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              children: [
                _sectionLabel('Location'),
                _field(_country, 'Country', Icons.public_rounded),
                const SizedBox(height: 9),
                Row(
                  children: [
                    Expanded(
                      child: _field(_state, 'State', Icons.map_outlined),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: _field(
                        _city,
                        'City',
                        Icons.location_city_outlined,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 9),
                _field(_region, 'Region / Area', Icons.place_outlined),
                _sectionLabel('Service Category'),
                Wrap(
                  spacing: 7,
                  runSpacing: 7,
                  children: categories.map((item) {
                    final selected = _category == item;
                    return ChoiceChip(
                      label: Text(_pretty(item)),
                      selected: selected,
                      onSelected: (value) {
                        setState(() => _category = value ? item : '');
                      },
                      selectedColor: AppColors.blueBg,
                      checkmarkColor: AppColors.blue,
                      backgroundColor: Colors.white,
                      side: BorderSide(
                        color: selected ? AppColors.blue : AppColors.cardBorder,
                      ),
                    );
                  }).toList(),
                ),
                _sectionLabel('Mission Dates'),
                Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    onTap: _pickDates,
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.calendar_month_outlined,
                            color: AppColors.blue,
                            size: 19,
                          ),
                          const SizedBox(width: 9),
                          Expanded(
                            child: Text(
                              _dateFrom == null || _dateTo == null
                                  ? 'Any date'
                                  : '${_date(_dateFrom!)} – ${_date(_dateTo!)}',
                              style: TextStyle(
                                color: _dateFrom == null
                                    ? AppColors.grey
                                    : AppColors.navy,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          if (_dateFrom != null)
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              onPressed: () {
                                setState(() {
                                  _dateFrom = null;
                                  _dateTo = null;
                                });
                              },
                              icon: const Icon(Icons.close_rounded, size: 17),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                _sectionLabel('Payment'),
                Row(
                  children: [
                    Expanded(
                      child: _field(
                        _paymentMin,
                        'Min',
                        Icons.payments_outlined,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: _field(
                        _paymentMax,
                        'Max',
                        Icons.payments_outlined,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                      ),
                    ),
                  ],
                ),
                _sectionLabel('Drone Capabilities'),
                Wrap(
                  spacing: 7,
                  runSpacing: 7,
                  children: capabilities.map((item) {
                    final selected = _capabilities.contains(item);
                    return FilterChip(
                      label: Text(item),
                      selected: selected,
                      onSelected: (value) {
                        setState(() {
                          value
                              ? _capabilities.add(item)
                              : _capabilities.remove(item);
                        });
                      },
                      selectedColor: AppColors.greenBg,
                      checkmarkColor: AppColors.green,
                      backgroundColor: Colors.white,
                      side: BorderSide(
                        color:
                            selected ? AppColors.green : AppColors.cardBorder,
                      ),
                    );
                  }).toList(),
                ),
                _sectionLabel('Sort'),
                _sortTile('newest', 'Newest first', Icons.auto_awesome_outlined),
                _sortTile('pay', 'Pay', Icons.payments_outlined),
                _sortTile('date', 'Mission date', Icons.calendar_today_outlined),
                const SizedBox(height: 12),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton.icon(
              onPressed: _apply,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.blue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              icon: const Icon(Icons.tune_rounded, size: 18),
              label: const Text(
                'Apply Filters',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 22, bottom: 9),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.navy,
          fontSize: 13,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String hint,
    IconData icon, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.grey, fontSize: 12.2),
        prefixIcon: Icon(icon, color: AppColors.blue, size: 18),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 13),
        border: _border(AppColors.cardBorder),
        enabledBorder: _border(AppColors.cardBorder),
        focusedBorder: _border(AppColors.blue, width: 1.2),
      ),
    );
  }

  Widget _sortTile(String value, String title, IconData icon) {
    final selected = _sort == value;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: selected ? AppColors.blue : AppColors.cardBorder,
        ),
      ),
      child: RadioListTile<String>(
        value: value,
        groupValue: _sort,
        onChanged: (newValue) {
          if (newValue == null) return;
          setState(() => _sort = newValue);
        },
        activeColor: AppColors.blue,
        secondary: Icon(
          icon,
          color: selected ? AppColors.blue : AppColors.grey,
          size: 19,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: selected ? AppColors.navy : AppColors.grey,
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  OutlineInputBorder _border(Color color, {double width = 0.8}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: color, width: width),
    );
  }

  String _pretty(String value) {
    return value
        .split(RegExp(r'[_\s-]+'))
        .where((part) => part.isNotEmpty)
        .map(
          (part) =>
              '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}',
        )
        .join(' ');
  }

  String _date(DateTime value) =>
      '${value.year}-${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';

  String _number(double? value) {
    if (value == null) return '';
    return value == value.roundToDouble()
        ? value.toStringAsFixed(0)
        : value.toStringAsFixed(2);
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(message),
        ),
      );
  }
}

class _JobsShimmer extends StatefulWidget {
  const _JobsShimmer();

  @override
  State<_JobsShimmer> createState() => _JobsShimmerState();
}

class _JobsShimmerState extends State<_JobsShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animation;

  @override
  void initState() {
    super.initState();
    _animation = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1250),
    )..repeat();
  }

  @override
  void dispose() {
    _animation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) {
        return ListView.separated(
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
          itemCount: 4,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (_, __) => _ShimmerJobCard(t: _animation.value),
        );
      },
    );
  }
}

class _InlineShimmer extends StatefulWidget {
  const _InlineShimmer();

  @override
  State<_InlineShimmer> createState() => _InlineShimmerState();
}

class _InlineShimmerState extends State<_InlineShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animation;

  @override
  void initState() {
    super.initState();
    _animation = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1250),
    )..repeat();
  }

  @override
  void dispose() {
    _animation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (_, __) => _ShimmerJobCard(t: _animation.value),
    );
  }
}

class _ShimmerJobCard extends StatelessWidget {
  const _ShimmerJobCard({required this.t});

  final double t;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 186,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _box(48, 48, 14),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _box(double.infinity, 14, 7),
                    const SizedBox(height: 8),
                    _box(130, 10, 6),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 17),
          _box(double.infinity, 11, 6),
          const SizedBox(height: 13),
          const Divider(height: 1, color: AppColors.cardBorder),
          const SizedBox(height: 13),
          Row(
            children: [
              _box(112, 28, 10),
              const Spacer(),
              _box(78, 23, 9),
            ],
          ),
        ],
      ),
    );
  }

  Widget _box(double width, double height, double radius) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: LinearGradient(
          begin: Alignment(-1.6 + (3.2 * t), 0),
          end: Alignment(-0.6 + (3.2 * t), 0),
          colors: [
            Colors.grey.shade100,
            Colors.grey.shade200,
            Colors.grey.shade100,
          ],
        ),
      ),
    );
  }
}
