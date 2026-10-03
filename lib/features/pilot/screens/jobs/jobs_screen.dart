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
import 'package:tototl_app/core/localization/app_language.dart';

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

  late final PilotJobService _jobService;
  late final PilotJobController _controller;
  late final AnimationController _pageAnimationController;

  Timer? _searchDebounce;
  bool _suppressSearchListener = false;
  Future<void>? _initialLoadFuture;

  @override
  void initState() {
    super.initState();

    _jobService = PilotJobService(ApiClient());

    _controller = PilotJobController(
      _jobService,
    );

    _pageAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();

    _searchController.addListener(_onSearchChanged);
    _scrollController.addListener(_onScroll);

    _initialLoadFuture = _controller.loadInitial();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _scrollController.removeListener(_onScroll);
    _searchController.dispose();
    _scrollController.dispose();
    _pageAnimationController.dispose();

    // loadInitial() may still be awaiting the jobs API when the user leaves
    // this screen. Disposing the ChangeNotifier before that Future finishes
    // causes its finally/notifyListeners() to throw:
    // "PilotJobController was used after being disposed."
    //
    // Defer disposal until that first request is fully settled.
    final pending = _initialLoadFuture;

    if (pending == null) {
      _controller.dispose();
    } else {
      unawaited(
        pending.whenComplete(
              () => _controller.dispose(),
        ),
      );
    }

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
    if (_suppressSearchListener) return;

    setState(() {});

    _searchDebounce?.cancel();
    _searchDebounce = Timer(
      const Duration(milliseconds: 420),
          () {
        if (!mounted) return;
        _controller.updateSearch(
          _searchController.text.trim(),
        );
      },
    );
  }

  void _submitSearch(String value) {
    _searchDebounce?.cancel();
    _controller.updateSearch(value.trim());
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

    _suppressSearchListener = true;
    _searchController.clear();
    _suppressSearchListener = false;

    if (mounted) {
      setState(() {});
    }

    await _controller.applyFilters(
      const PilotJobFilters(),
    );
  }

  Future<void> _openJob(PilotJobModel job) async {
    HapticFeedback.selectionClick();

    // Start the authoritative detail request before route transition.
    // The transition time becomes useful loading time and the detail screen
    // never needs to paint list/demo data as if it were fresh details.
    final detailsFuture = _jobService.getJobDetails(job.id);

    await Navigator.of(context).push(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 330),
        reverseTransitionDuration: const Duration(milliseconds: 250),
        pageBuilder: (_, animation, __) => JobDetailsScreen(
          jobId: job.id,
          detailsFuture: detailsFuture,
        ),
        transitionsBuilder: (_, animation, __, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          );

          return FadeTransition(
            opacity: curved,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.025, 0),
                end: Offset.zero,
              ).animate(curved),
              child: child,
            ),
          );
        },
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
          backgroundColor: const Color(0xFFF8FBFC),
          body: Stack(
            children: [
              _backgroundGlow(),
              SafeArea(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        16,
                        16,
                        16,
                        0,
                      ),
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          _animatedEntry(
                            index: 0,
                            child: _header(),
                          ),
                          const SizedBox(height: 14),
                          _animatedEntry(
                            index: 1,
                            child: _searchAndFilter(),
                          ),
                          if (_controller
                              .filters
                              .hasAdvancedFilters) ...[
                            const SizedBox(height: 9),
                            _activeFilters(),
                          ],
                          const SizedBox(height: 13),
                          _resultsRow(),
                          const SizedBox(height: 9),
                        ],
                      ),
                    ),
                    Expanded(
                      child: _body(),
                    ),
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
          top: -145,
          right: -135,
          child: IgnorePointer(
            child: Container(
              width: 315,
              height: 315,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF12B8C0)
                        .withOpacity(.075),
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
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFFE9F8F8),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(
            Icons.travel_explore_rounded,
            color: Color(0xFF078FA5),
            size: 21,
          ),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              Text(
                AppLanguage.text(
                  'Find Drone Jobs',
                ),
                style: const TextStyle(
                  color: Color(0xFF0A2D46),
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -.35,
                  height: 1.04,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                AppLanguage.text(
                  'Published opportunities ready for pilots',
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF7F91A0),
                  fontSize: 9.9,
                  height: 1.15,
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
          child: SizedBox(
            height: 49,
            child: TextField(
              controller: _searchController,
              textInputAction:
              TextInputAction.search,
              onSubmitted: _submitSearch,
              style: const TextStyle(
                color: Color(0xFF0A2D46),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
              decoration: InputDecoration(
                hintText: AppLanguage.text(
                  'Search job title or description...',
                ),
                hintStyle: const TextStyle(
                  color: Color(0xFF91A0AA),
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
                prefixIcon: Container(
                  margin:
                  const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color:
                    const Color(0xFFE8F8F8),
                    borderRadius:
                    BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.search_rounded,
                    color: Color(0xFF078FA5),
                    size: 18,
                  ),
                ),
                suffixIcon:
                _searchController.text.isEmpty
                    ? null
                    : IconButton(
                  tooltip:
                  AppLanguage.text(
                    'Clear search',
                  ),
                  onPressed: () {
                    HapticFeedback
                        .selectionClick();
                    _searchDebounce
                        ?.cancel();

                    _suppressSearchListener =
                    true;
                    _searchController
                        .clear();
                    _suppressSearchListener =
                    false;

                    setState(() {});
                    _controller
                        .updateSearch('');
                  },
                  icon:
                  const Icon(
                    Icons
                        .close_rounded,
                    color: Color(
                        0xFF7F91A0),
                    size: 17,
                  ),
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding:
                const EdgeInsets.symmetric(
                  vertical: 12,
                ),
                border: _inputBorder(
                  const Color(0xFFDDE7EB),
                ),
                enabledBorder: _inputBorder(
                  const Color(0xFFDDE7EB),
                ),
                focusedBorder: _inputBorder(
                  const Color(0xFF11AEBB),
                  width: 1.15,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 9),
        _filterButton(),
      ],
    );
  }

  Widget _filterButton() {
    final count =
        _controller.filters.activeFilterCount;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(15),
      child: InkWell(
        onTap: _openFilters,
        borderRadius:
        BorderRadius.circular(15),
        child: Container(
          width: 49,
          height: 49,
          decoration: BoxDecoration(
            borderRadius:
            BorderRadius.circular(15),
            border: Border.all(
              color: count > 0
                  ? const Color(0xFF11AEBB)
                  : const Color(0xFFDDE7EB),
              width: count > 0 ? 1.15 : .85,
            ),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(
                Icons.tune_rounded,
                color: count > 0
                    ? const Color(0xFF078FA5)
                    : const Color(0xFF0A2D46),
                size: 19,
              ),
              if (count > 0)
                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    width: 15,
                    height: 15,
                    alignment: Alignment.center,
                    decoration:
                    const BoxDecoration(
                      color:
                      Color(0xFF11AEBB),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$count',
                      style:
                      const TextStyle(
                        color: Colors.white,
                        fontSize: 7.5,
                        fontWeight:
                        FontWeight.w800,
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
      if (f.category.isNotEmpty)
        _pretty(f.category),
      if (f.country.isNotEmpty) f.country,
      if (f.state.isNotEmpty) f.state,
      if (f.city.isNotEmpty) f.city,
      if (f.region.isNotEmpty) f.region,
      if (f.paymentMin != null ||
          f.paymentMax != null)
        'Budget',
      if (f.dateFrom != null ||
          f.dateTo != null)
        'Dates',
      if (f.capabilities.isNotEmpty)
        '${f.capabilities.length} ${f.capabilities.length == 1 ? 'capability' : 'capabilities'}',
      if (f.sort != 'newest')
        'Sort: ${_sortLabel(f.sort)}',
    ];

    return SizedBox(
      height: 29,
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics:
        const BouncingScrollPhysics(),
        children: [
          ...labels.map(
                (label) => Padding(
              padding:
              const EdgeInsets.only(
                right: 6,
              ),
              child: Container(
                padding:
                const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color:
                  const Color(0xFFE9F8F8),
                  borderRadius:
                  BorderRadius.circular(20),
                ),
                child: Text(
                  label,
                  style:
                  const TextStyle(
                    color:
                    Color(0xFF078FA5),
                    fontSize: 8.4,
                    fontWeight:
                    FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
          TextButton(
            onPressed:
            _controller
                .clearAdvancedFilters,
            style: TextButton.styleFrom(
              padding:
              const EdgeInsets.symmetric(
                horizontal: 5,
              ),
              visualDensity:
              VisualDensity.compact,
            ),
            child: Text(
              AppLanguage.text('Clear'),
              style:
              const TextStyle(
                color:
                Color(0xFF078FA5),
                fontSize: 8.5,
                fontWeight:
                FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _resultsRow() {
    if (_controller.isInitialLoading &&
        _controller.jobs.isEmpty) {
      return const Row(
        children: [
          _ReferenceMiniSkeleton(
            width: 82,
            height: 15,
          ),
          Spacer(),
          _ReferenceMiniSkeleton(
            width: 76,
            height: 30,
            radius: 16,
          ),
        ],
      );
    }

    final count =
    _controller.total > 0
        ? _controller.total
        : _controller.jobs.length;

    return Row(
      children: [
        Text(
          '$count jobs found',
          style: const TextStyle(
            color: Color(0xFF0A2D46),
            fontSize: 11.2,
            fontWeight: FontWeight.w800,
          ),
        ),
        const Spacer(),
        Material(
          color: Colors.white,
          borderRadius:
          BorderRadius.circular(18),
          child: InkWell(
            onTap: _openFilters,
            borderRadius:
            BorderRadius.circular(18),
            child: Container(
              height: 31,
              padding:
              const EdgeInsets.symmetric(
                horizontal: 11,
              ),
              decoration: BoxDecoration(
                borderRadius:
                BorderRadius.circular(18),
                border: Border.all(
                  color:
                  const Color(0xFFDDE7EB),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons
                        .swap_vert_rounded,
                    color:
                    Color(0xFF078FA5),
                    size: 13,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    _sortLabel(
                      _controller
                          .filters.sort,
                    ),
                    style:
                    const TextStyle(
                      color:
                      Color(0xFF0A2D46),
                      fontSize: 9.5,
                      fontWeight:
                      FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons
                        .keyboard_arrow_down_rounded,
                    color:
                    Color(0xFF078FA5),
                    size: 15,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _body() {
    if (_controller.isInitialLoading &&
        _controller.jobs.isEmpty) {
      return const _JobsShimmer();
    }

    if (_controller.errorMessage != null &&
        _controller.jobs.isEmpty) {
      return _JobsError(
        message:
        _controller.errorMessage!,
        onRetry:
        _controller.loadInitial,
      );
    }

    if (_controller.jobs.isEmpty) {
      return _NoResults(
        onClear: _clearAll,
      );
    }

    return RefreshIndicator(
      color: const Color(0xFF11AEBB),
      onRefresh:
      _controller.refresh,
      child: ListView.separated(
        controller: _scrollController,
        physics:
        const AlwaysScrollableScrollPhysics(
          parent:
          BouncingScrollPhysics(),
        ),
        keyboardDismissBehavior:
        ScrollViewKeyboardDismissBehavior
            .onDrag,
        padding:
        const EdgeInsets.fromLTRB(
          16,
          0,
          16,
          120,
        ),
        itemCount:
        _controller.jobs.length +
            (_controller.isLoadingMore
                ? 1
                : 0),
        separatorBuilder:
            (_, __) =>
        const SizedBox(height: 8),
        itemBuilder: (context, index) {
          if (index >=
              _controller.jobs.length) {
            return const _InlineShimmer();
          }

          final job =
          _controller.jobs[index];

          return _animatedEntry(
            index:
            3 +
                (index > 6
                    ? 6
                    : index),
            child: _JobListCard(
              job: job,
              onTap: () =>
                  _openJob(job),
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
  State<_JobListCard> createState() =>
      _JobListCardState();
}

class _JobListCardState
    extends State<_JobListCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final job = widget.job;

    return AnimatedScale(
      duration:
      const Duration(milliseconds: 110),
      scale: _pressed ? .987 : 1,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius:
          BorderRadius.circular(17),
          onTapDown: (_) =>
              setState(
                    () => _pressed = true,
              ),
          onTapCancel: () =>
              setState(
                    () => _pressed = false,
              ),
          onTapUp: (_) =>
              setState(
                    () => _pressed = false,
              ),
          onTap: widget.onTap,
          child: Ink(
            padding:
            const EdgeInsets.fromLTRB(
              10,
              10,
              10,
              10,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius:
              BorderRadius.circular(17),
              border: Border.all(
                color:
                const Color(0xFFDDE7EB),
                width: .8,
              ),
              boxShadow: [
                BoxShadow(
                  color:
                  const Color(
                      0xFF0A2D46)
                      .withOpacity(.025),
                  blurRadius: 14,
                  offset:
                  const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    _JobPreviewImage(
                      job: job,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: SizedBox(
                        height: 88,
                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment
                              .start,
                          children: [
                            Row(
                              crossAxisAlignment:
                              CrossAxisAlignment
                                  .start,
                              children: [
                                Expanded(
                                  child: Text(
                                    job.title
                                        .trim()
                                        .isEmpty
                                        ? 'Untitled Job'
                                        : job.title
                                        .trim(),
                                    maxLines: 2,
                                    overflow:
                                    TextOverflow
                                        .ellipsis,
                                    style:
                                    const TextStyle(
                                      color:
                                      Color(
                                          0xFF0A2D46),
                                      fontSize:
                                      12.2,
                                      fontWeight:
                                      FontWeight
                                          .w900,
                                      height: 1.13,
                                      letterSpacing:
                                      -.15,
                                    ),
                                  ),
                                ),
                                const SizedBox(
                                    width: 5),
                                Container(
                                  width: 28,
                                  height: 28,
                                  decoration:
                                  const BoxDecoration(
                                    color:
                                    Color(
                                        0xFFE9F8F8),
                                    shape:
                                    BoxShape
                                        .circle,
                                  ),
                                  child:
                                  const Icon(
                                    Icons
                                        .chevron_right_rounded,
                                    color:
                                    Color(
                                        0xFF078FA5),
                                    size: 18,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              job.categoryLabel,
                              maxLines: 1,
                              overflow:
                              TextOverflow
                                  .ellipsis,
                              style:
                              const TextStyle(
                                color:
                                Color(
                                    0xFF7F91A0),
                                fontSize: 9.1,
                                height: 1.2,
                                fontWeight:
                                FontWeight
                                    .w500,
                              ),
                            ),
                            const SizedBox(height: 7),
                            Row(
                              children: [
                                Expanded(
                                  child:
                                  _ReferenceJobInfo(
                                    icon: Icons
                                        .location_on_outlined,
                                    text: job
                                        .locationLabel,
                                  ),
                                ),
                                const SizedBox(
                                    width: 7),
                                Flexible(
                                  child:
                                  _ReferenceJobInfo(
                                    icon: Icons
                                        .calendar_today_outlined,
                                    text: job
                                        .dateLabel,
                                  ),
                                ),
                              ],
                            ),
                            if (job
                                .requiredCapabilities
                                .isNotEmpty) ...[
                              const Spacer(),
                              Wrap(
                                spacing: 5,
                                runSpacing: 4,
                                children: job
                                    .requiredCapabilities
                                    .take(2)
                                    .map(
                                      (item) =>
                                      _CapabilityPill(
                                        label:
                                        item,
                                      ),
                                )
                                    .toList(
                                  growable:
                                  false,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 36,
                        padding:
                        const EdgeInsets
                            .symmetric(
                          horizontal: 10,
                        ),
                        alignment:
                        Alignment
                            .centerLeft,
                        decoration:
                        BoxDecoration(
                          color:
                          const Color(
                              0xFFE8F8F7),
                          borderRadius:
                          BorderRadius
                              .circular(
                              10),
                        ),
                        child: Text(
                          job.payLabel,
                          maxLines: 1,
                          overflow:
                          TextOverflow
                              .ellipsis,
                          style:
                          const TextStyle(
                            color:
                            Color(
                                0xFF079D9A),
                            fontSize: 10.4,
                            fontWeight:
                            FontWeight
                                .w900,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 9),
                    SizedBox(
                      width: 126,
                      height: 36,
                      child: FilledButton(
                        onPressed:
                        widget.onTap,
                        style:
                        FilledButton
                            .styleFrom(
                          elevation: 0,
                          backgroundColor:
                          const Color(
                              0xFF08A5B5),
                          foregroundColor:
                          Colors.white,
                          padding:
                          const EdgeInsets
                              .symmetric(
                            horizontal: 10,
                          ),
                          shape:
                          RoundedRectangleBorder(
                            borderRadius:
                            BorderRadius
                                .circular(
                                10),
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment:
                          MainAxisAlignment
                              .center,
                          children: [
                            Text(
                              'View job',
                              style:
                              TextStyle(
                                fontSize:
                                9.9,
                                fontWeight:
                                FontWeight
                                    .w700,
                              ),
                            ),
                            SizedBox(width: 6),
                            Icon(
                              Icons
                                  .arrow_forward_rounded,
                              size: 14,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _JobPreviewImage extends StatelessWidget {
  const _JobPreviewImage({
    required this.job,
  });

  final PilotJobModel job;

  @override
  Widget build(BuildContext context) {
    final assetPath = _jobCategoryAsset(job.serviceCategory);

    return Container(
      width: 94,
      height: 88,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xFFF1F7F8),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(
          color: const Color(0xFFE0E9EC),
          width: .7,
        ),
      ),
      child: Image.asset(
        assetPath,
        width: 94,
        height: 88,
        fit: BoxFit.cover,
        filterQuality: FilterQuality.high,
        errorBuilder: (_, __, ___) {
          return _JobImageFallback(
            category: job.serviceCategory,
          );
        },
      ),
    );
  }
}

String _jobCategoryAsset(String rawCategory) {
  final value = rawCategory.trim().toLowerCase();

  if (value.contains('inspection')) {
    return 'assets/images/Inspection.png';
  }

  if (value.contains('mapping')) {
    return 'assets/images/Mapping.png';
  }

  if (value.contains('photography') ||
      value.contains('photo')) {
    return 'assets/images/Photography.png';
  }

  if (value.contains('construction')) {
    return 'assets/images/Construction.png';
  }

  if (value.contains('surveying') ||
      value.contains('survey')) {
    return 'assets/images/Surveying.png';
  }

  return 'assets/images/Other.png';
}

class _JobImageFallback extends StatelessWidget {
  const _JobImageFallback({
    required this.category,
  });

  final String category;

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFF1FBFB),
            Color(0xFFEAF4F6),
          ],
        ),
      ),
      child: Icon(
        _jobCategoryFallbackIcon(category),
        color: const Color(0xFF078FA5),
        size: 27,
      ),
    );
  }
}

IconData _jobCategoryFallbackIcon(String rawCategory) {
  final value = rawCategory.trim().toLowerCase();

  if (value.contains('inspection')) {
    return Icons.manage_search_rounded;
  }

  if (value.contains('mapping')) {
    return Icons.map_outlined;
  }

  if (value.contains('photography') ||
      value.contains('photo')) {
    return Icons.photo_camera_outlined;
  }

  if (value.contains('construction')) {
    return Icons.construction_outlined;
  }

  if (value.contains('surveying') ||
      value.contains('survey')) {
    return Icons.straighten_rounded;
  }

  return Icons.flight_takeoff_rounded;
}

class _ReferenceJobInfo
    extends StatelessWidget {
  const _ReferenceJobInfo({
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 11,
          color:
          const Color(0xFF758B9A),
        ),
        const SizedBox(width: 3),
        Flexible(
          child: Text(
            text,
            maxLines: 1,
            overflow:
            TextOverflow.ellipsis,
            style: const TextStyle(
              color:
              Color(0xFF758B9A),
              fontSize: 8.1,
              height: 1.1,
              fontWeight:
              FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

class _CapabilityPill
    extends StatelessWidget {
  const _CapabilityPill({
    required this.label,
  });

  final String label;

  @override
  Widget build(BuildContext context) {
    final clean =
    label.trim().isEmpty
        ? 'Capability'
        : label.trim();

    return Container(
      padding:
      const EdgeInsets.symmetric(
        horizontal: 7,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color:
        const Color(0xFFE9F8F8),
        borderRadius:
        BorderRadius.circular(20),
      ),
      child: Text(
        clean,
        maxLines: 1,
        overflow:
        TextOverflow.ellipsis,
        style: const TextStyle(
          color: Color(0xFF078FA5),
          fontSize: 7.5,
          height: 1.05,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ReferenceMiniSkeleton
    extends StatelessWidget {
  const _ReferenceMiniSkeleton({
    required this.width,
    required this.height,
    this.radius = 5,
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
        color:
        const Color(0xFFE8EFF1),
        borderRadius:
        BorderRadius.circular(radius),
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
        Text(
          AppLanguage.text('No jobs match your search'),
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.navy,
            fontSize: 14.5,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          AppLanguage.text('Try changing the search or clearing the filters.'),
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
            label: Text(AppLanguage.text('Clear search & filters')),
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
            Text(
              AppLanguage.text('Couldn’t load jobs'),
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
              label: Text(AppLanguage.text('Try Again')),
            ),
          ],
        ),
      ),
    );
  }
}

class _JobFilterSheet extends StatefulWidget {
  const _JobFilterSheet({
    required this.initial,
  });

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
  late final TextEditingController _customCapability;

  late String _category;
  late String _sort;
  late Set<String> _capabilities;

  DateTime? _dateFrom;
  DateTime? _dateTo;

  static const List<String> categories = [
    'inspection',
    'mapping',
    'photography',
    'construction',
    'surveying',
    'other',
  ];

  // Quick suggestions only. The backend now accepts free-text capabilities,
  // so pilots are not limited to this list.
  static const List<String> suggestedCapabilities = [
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
    _customCapability = TextEditingController();

    _category = f.category;
    _sort = f.sort;
    _capabilities = f.capabilities
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toSet();

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
    _customCapability.dispose();
    super.dispose();
  }

  Future<void> _pickDates() async {
    HapticFeedback.selectionClick();

    final now = DateTime.now();

    final result = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
      initialDateRange: _dateFrom != null && _dateTo != null
          ? DateTimeRange(
        start: _dateFrom!,
        end: _dateTo!,
      )
          : null,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: AppColors.blue,
            ),
          ),
          child: child!,
        );
      },
    );

    if (result == null || !mounted) return;

    setState(() {
      _dateFrom = result.start;
      _dateTo = result.end;
    });
  }

  void _addCapability(String raw) {
    final value = raw.trim();

    if (value.isEmpty) return;

    if (value.length > 60) {
      _snack('Capability must be 60 characters or fewer.');
      return;
    }

    final exists = _capabilities.any(
          (item) => item.toLowerCase() == value.toLowerCase(),
    );

    if (exists) {
      _customCapability.clear();
      return;
    }

    setState(() {
      _capabilities.add(value);
      _customCapability.clear();
    });

    HapticFeedback.selectionClick();
  }

  void _toggleSuggestedCapability(String value, bool selected) {
    if (selected) {
      _addCapability(value);
      return;
    }

    setState(() {
      _capabilities.removeWhere(
            (item) => item.toLowerCase() == value.toLowerCase(),
      );
    });
  }

  bool _containsCapability(String value) {
    return _capabilities.any(
          (item) => item.toLowerCase() == value.toLowerCase(),
    );
  }

  void _removeCapability(String value) {
    setState(() {
      _capabilities.remove(value);
    });
  }

  void _apply() {
    FocusScope.of(context).unfocus();

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

    if (min != null && min < 0) {
      _snack('Minimum payment cannot be negative.');
      return;
    }

    if (max != null && max < 0) {
      _snack('Maximum payment cannot be negative.');
      return;
    }

    if (min != null && max != null && max < min) {
      _snack(
        'Maximum payment must be greater than or equal to minimum.',
      );
      return;
    }

    final cleanCapabilities = _capabilities
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty && item.length <= 60)
        .toList();

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
        capabilities: cleanCapabilities,
        sort: _sort,
      ),
    );
  }

  void _reset() {
    HapticFeedback.selectionClick();

    setState(() {
      _country.clear();
      _state.clear();
      _city.clear();
      _region.clear();
      _paymentMin.clear();
      _paymentMax.clear();
      _customCapability.clear();

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
        maxHeight: MediaQuery.of(context).size.height * 0.92,
      ),
      padding: EdgeInsets.fromLTRB(
        18,
        9,
        18,
        16 + bottom,
      ),
      decoration: const BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(28),
        ),
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
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.blue.withOpacity(0.065),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons.tune_rounded,
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
                      AppLanguage.text('Refine Jobs'),
                      style: TextStyle(
                        color: AppColors.navy,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.3,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      AppLanguage.text('Narrow opportunities to the missions that fit you'),
                      style: TextStyle(
                        color: AppColors.grey,
                        fontSize: 9.8,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: _reset,
                child: Text(
                  AppLanguage.text('Reset'),
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView(
              keyboardDismissBehavior:
              ScrollViewKeyboardDismissBehavior.onDrag,
              physics: const BouncingScrollPhysics(),
              children: [
                _sectionLabel(
                  'Location',
                  'Country, state, city or a more specific region',
                ),
                _field(
                  _country,
                  'Country',
                  Icons.public_rounded,
                ),
                const SizedBox(height: 9),
                Row(
                  children: [
                    Expanded(
                      child: _field(
                        _state,
                        'State',
                        Icons.map_outlined,
                      ),
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
                _field(
                  _region,
                  'Region / Area',
                  Icons.place_outlined,
                ),
                _sectionLabel(
                  'Service Category',
                  'Choose one primary mission type',
                ),
                Wrap(
                  spacing: 7,
                  runSpacing: 7,
                  children: categories.map(
                        (item) {
                      final selected = _category == item;

                      return ChoiceChip(
                        label: Text(_pretty(item)),
                        selected: selected,
                        showCheckmark: false,
                        onSelected: (value) {
                          HapticFeedback.selectionClick();
                          setState(
                                () => _category = value ? item : '',
                          );
                        },
                        selectedColor: AppColors.blueBg,
                        backgroundColor: Colors.white,
                        labelStyle: TextStyle(
                          color: selected
                              ? AppColors.blue
                              : AppColors.navy,
                          fontSize: 10.7,
                          fontWeight: selected
                              ? FontWeight.w800
                              : FontWeight.w600,
                        ),
                        side: BorderSide(
                          color: selected
                              ? AppColors.blue.withOpacity(0.42)
                              : AppColors.cardBorder,
                        ),
                      );
                    },
                  ).toList(),
                ),
                _sectionLabel(
                  'Mission Dates',
                  'Filter opportunities by the mission window',
                ),
                Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    onTap: _pickDates,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(
                        13,
                        12,
                        10,
                        12,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.cardBorder,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: AppColors.blue.withOpacity(0.06),
                              borderRadius: BorderRadius.circular(11),
                            ),
                            child: const Icon(
                              Icons.calendar_month_outlined,
                              color: AppColors.blue,
                              size: 17,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  AppLanguage.text('Mission window'),
                                  style: TextStyle(
                                    color: AppColors.grey,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  _dateFrom == null || _dateTo == null
                                      ? 'Any date'
                                      : '${_date(_dateFrom!)}  –  ${_date(_dateTo!)}',
                                  style: TextStyle(
                                    color: _dateFrom == null
                                        ? AppColors.grey
                                        : AppColors.navy,
                                    fontSize: 11.7,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (_dateFrom != null)
                            IconButton(
                              tooltip: AppLanguage.text('Clear dates'),
                              visualDensity: VisualDensity.compact,
                              onPressed: () {
                                setState(() {
                                  _dateFrom = null;
                                  _dateTo = null;
                                });
                              },
                              icon: const Icon(
                                Icons.close_rounded,
                                size: 17,
                              ),
                            )
                          else
                            const Icon(
                              Icons.chevron_right_rounded,
                              color: AppColors.grey,
                              size: 19,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                _sectionLabel(
                  'Payment',
                  'Optional budget range',
                ),
                Row(
                  children: [
                    Expanded(
                      child: _field(
                        _paymentMin,
                        'Minimum',
                        Icons.payments_outlined,
                        keyboardType:
                        const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: _field(
                        _paymentMax,
                        'Maximum',
                        Icons.payments_outlined,
                        keyboardType:
                        const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                      ),
                    ),
                  ],
                ),
                _sectionLabel(
                  'Drone Capabilities',
                  'Pick suggestions or add any capability required by the mission',
                ),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _customCapability,
                        maxLength: 60,
                        textInputAction: TextInputAction.done,
                        onSubmitted: _addCapability,
                        style: const TextStyle(
                          color: AppColors.navy,
                          fontSize: 12.2,
                          fontWeight: FontWeight.w600,
                        ),
                        decoration: InputDecoration(
                          hintText: AppLanguage.text('Add capability...'),
                          counterText: '',
                          hintStyle: const TextStyle(
                            color: AppColors.grey,
                            fontSize: 11.5,
                          ),
                          prefixIcon: const Icon(
                            Icons.memory_rounded,
                            color: AppColors.blue,
                            size: 17,
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          border: _border(AppColors.cardBorder),
                          enabledBorder: _border(AppColors.cardBorder),
                          focusedBorder: _border(
                            AppColors.blue,
                            width: 1.2,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 48,
                      height: 48,
                      child: FilledButton(
                        onPressed: () =>
                            _addCapability(_customCapability.text),
                        style: FilledButton.styleFrom(
                          padding: EdgeInsets.zero,
                          backgroundColor: AppColors.navy,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Icon(
                          Icons.add_rounded,
                          size: 19,
                        ),
                      ),
                    ),
                  ],
                ),
                if (_capabilities.isNotEmpty) ...[
                  const SizedBox(height: 11),
                  Wrap(
                    spacing: 7,
                    runSpacing: 7,
                    children: _capabilities
                        .map(
                          (item) => InputChip(
                        label: Text(item),
                        onDeleted: () => _removeCapability(item),
                        deleteIcon: const Icon(
                          Icons.close_rounded,
                          size: 14,
                        ),
                        backgroundColor:
                        AppColors.green.withOpacity(0.06),
                        side: BorderSide(
                          color:
                          AppColors.green.withOpacity(0.13),
                        ),
                        labelStyle: const TextStyle(
                          color: AppColors.green,
                          fontSize: 9.8,
                          fontWeight: FontWeight.w800,
                        ),
                        deleteIconColor: AppColors.green,
                      ),
                    )
                        .toList(),
                  ),
                ],
                const SizedBox(height: 11),
                Text(
                  AppLanguage.text('Quick suggestions'),
                  style: TextStyle(
                    color: AppColors.grey,
                    fontSize: 9.3,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 7,
                  runSpacing: 7,
                  children: suggestedCapabilities.map(
                        (item) {
                      final selected = _containsCapability(item);

                      return FilterChip(
                        label: Text(item),
                        selected: selected,
                        showCheckmark: false,
                        onSelected: (value) =>
                            _toggleSuggestedCapability(item, value),
                        selectedColor:
                        AppColors.green.withOpacity(0.07),
                        backgroundColor: Colors.white,
                        side: BorderSide(
                          color: selected
                              ? AppColors.green.withOpacity(0.38)
                              : AppColors.cardBorder,
                        ),
                        labelStyle: TextStyle(
                          color: selected
                              ? AppColors.green
                              : AppColors.navy,
                          fontSize: 9.8,
                          fontWeight: selected
                              ? FontWeight.w800
                              : FontWeight.w600,
                        ),
                      );
                    },
                  ).toList(),
                ),
                _sectionLabel(
                  'Sort',
                  'Choose how results should be ordered',
                ),
                _sortTile(
                  'newest',
                  'Newest first',
                  'Recently published missions first',
                  Icons.auto_awesome_outlined,
                ),
                _sortTile(
                  'pay',
                  'Highest pay',
                  'Prioritize stronger budgets',
                  Icons.payments_outlined,
                ),
                _sortTile(
                  'date',
                  'Mission date',
                  'Prioritize the upcoming mission schedule',
                  Icons.calendar_today_outlined,
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
          const SizedBox(height: 11),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton(
              onPressed: _apply,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.blue,
                foregroundColor: Colors.white,
                disabledBackgroundColor:
                AppColors.blue.withOpacity(.45),
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                ),
                shape: const StadiumBorder(),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.tune_rounded,
                    size: 17,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    AppLanguage.text('Apply Filters'),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(
      String title,
      String subtitle,
      ) {
    return Padding(
      padding: const EdgeInsets.only(
        top: 21,
        bottom: 9,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.navy,
              fontSize: 12.6,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            subtitle,
            style: const TextStyle(
              color: AppColors.grey,
              fontSize: 9.3,
              height: 1.3,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
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
      style: const TextStyle(
        color: AppColors.navy,
        fontSize: 12.2,
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
          color: AppColors.grey,
          fontSize: 11.5,
        ),
        prefixIcon: Icon(
          icon,
          color: AppColors.blue,
          size: 17,
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 13),
        border: _border(AppColors.cardBorder),
        enabledBorder: _border(AppColors.cardBorder),
        focusedBorder: _border(
          AppColors.blue,
          width: 1.2,
        ),
      ),
    );
  }

  Widget _sortTile(
      String value,
      String title,
      String subtitle,
      IconData icon,
      ) {
    final selected = _sort == value;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _sort = value);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: selected
                  ? AppColors.blue.withOpacity(0.48)
                  : AppColors.cardBorder,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 37,
                height: 37,
                decoration: BoxDecoration(
                  color: selected
                      ? AppColors.blue.withOpacity(0.07)
                      : AppColors.bg,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(
                  icon,
                  color: selected
                      ? AppColors.blue
                      : AppColors.grey,
                  size: 17,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: selected
                            ? AppColors.navy
                            : AppColors.grey,
                        fontSize: 11.8,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: AppColors.grey,
                        fontSize: 8.9,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 21,
                height: 21,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected
                      ? AppColors.blue
                      : Colors.transparent,
                  border: Border.all(
                    color: selected
                        ? AppColors.blue
                        : AppColors.cardBorder,
                    width: 1.2,
                  ),
                ),
                child: selected
                    ? const Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 13,
                )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  OutlineInputBorder _border(
      Color color, {
        double width = 0.8,
      }) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(
        color: color,
        width: width,
      ),
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

  String _date(DateTime value) {
    return '${value.year}-'
        '${value.month.toString().padLeft(2, '0')}-'
        '${value.day.toString().padLeft(2, '0')}';
  }

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
          backgroundColor: AppColors.navy,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
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
