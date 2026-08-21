import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../core/theme/app_colors.dart';
import '../shared/pilot_data.dart';
import 'job_details.dart';

// ============================================================================
// FIND DRONE JOBS
// ============================================================================

class FindDroneJobsScreen extends StatefulWidget {
  const FindDroneJobsScreen({
    super.key,
  });

  @override
  State<FindDroneJobsScreen> createState() =>
      _FindDroneJobsScreenState();
}

class _FindDroneJobsScreenState extends State<FindDroneJobsScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController =
  TextEditingController();

  late final AnimationController _pageAnimationController;

  @override
  void initState() {
    super.initState();

    _searchController.addListener(
      _onSearchChanged,
    );

    _pageAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(
        milliseconds: 850,
      ),
    );

    _pageAnimationController.forward();
  }

  @override
  void dispose() {
    _searchController.removeListener(
      _onSearchChanged,
    );

    _searchController.dispose();

    _pageAnimationController.dispose();

    super.dispose();
  }

  void _onSearchChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  // ==========================================================================
  // FILTERED JOBS
  // ==========================================================================

  List<PilotJob> get _filteredJobs {
    final query =
    _searchController.text.trim().toLowerCase();

    final jobs =
        PilotJobsStore.instance.jobs;

    if (query.isEmpty) {
      return jobs;
    }

    return jobs
        .where(
          (job) =>
          '${job.title} ${job.company} ${job.location}'
              .toLowerCase()
              .contains(query),
    )
        .toList();
  }

  // ==========================================================================
  // PAGE ANIMATION
  // ==========================================================================

  Widget _animatedEntry({
    required int index,
    required Widget child,
  }) {
    final start =
    (index * 0.08)
        .clamp(
      0.0,
      0.65,
    )
        .toDouble();

    final end =
    (start + 0.36)
        .clamp(
      0.0,
      1.0,
    )
        .toDouble();

    final animation = CurvedAnimation(
      parent:
      _pageAnimationController,
      curve: Interval(
        start,
        end,
        curve:
        Curves.easeOutCubic,
      ),
    );

    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position:
        Tween<Offset>(
          begin:
          const Offset(
            0,
            0.04,
          ),
          end:
          Offset.zero,
        ).animate(
          animation,
        ),
        child:
        child,
      ),
    );
  }

  // ==========================================================================
  // BUILD
  // ==========================================================================

  @override
  Widget build(
      BuildContext context,
      ) {
    return AnimatedBuilder(
      animation:
      PilotJobsStore.instance,
      builder:
          (
          context,
          _,
          ) {
        final jobs =
            _filteredJobs;

        return Scaffold(
          backgroundColor:
          AppColors.bg,
          body:
          Stack(
            children: [
              // ============================================================
              // BACKGROUND GLOW
              // ============================================================

              Positioned(
                top:
                -160,
                right:
                -130,
                child:
                IgnorePointer(
                  child:
                  Container(
                    width:
                    330,
                    height:
                    330,
                    decoration:
                    BoxDecoration(
                      shape:
                      BoxShape.circle,
                      gradient:
                      RadialGradient(
                        colors: [
                          AppColors.blue.withOpacity(
                            0.10,
                          ),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              Positioned(
                top:
                470,
                left:
                -150,
                child:
                IgnorePointer(
                  child:
                  Container(
                    width:
                    280,
                    height:
                    280,
                    decoration:
                    BoxDecoration(
                      shape:
                      BoxShape.circle,
                      gradient:
                      RadialGradient(
                        colors: [
                          const Color(
                            0xFF16C6C7,
                          ).withOpacity(
                            0.035,
                          ),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // ============================================================
              // CONTENT
              // ============================================================

              SafeArea(
                child:
                Column(
                  children: [
                    // ======================================================
                    // HEADER AREA
                    // ======================================================

                    Padding(
                      padding:
                      const EdgeInsets.fromLTRB(
                        16,
                        24,
                        16,
                        0,
                      ),
                      child:
                      Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          _animatedEntry(
                            index:
                            0,
                            child:
                            _buildHeader(),
                          ),

                          const SizedBox(
                            height:
                            20,
                          ),

                          _animatedEntry(
                            index:
                            1,
                            child:
                            _buildSearchField(),
                          ),

                          const SizedBox(
                            height:
                            15,
                          ),

                          _animatedEntry(
                            index:
                            2,
                            child:
                            _buildResultsRow(
                              jobs.length,
                            ),
                          ),

                          const SizedBox(
                            height:
                            14,
                          ),
                        ],
                      ),
                    ),

                    // ======================================================
                    // JOBS LIST
                    // ======================================================

                    Expanded(
                      child:
                      jobs.isEmpty
                          ? _animatedEntry(
                        index:
                        3,
                        child:
                        const _NoResults(),
                      )
                          : ListView.separated(
                        physics:
                        const BouncingScrollPhysics(),
                        keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                        padding:
                        const EdgeInsets.fromLTRB(
                          16,
                          0,
                          16,
                          120,
                        ),
                        itemCount:
                        jobs.length,
                        separatorBuilder:
                            (
                            _,
                            __,
                            ) =>
                        const SizedBox(
                          height:
                          12,
                        ),
                        itemBuilder:
                            (
                            context,
                            index,
                            ) {
                          return _animatedEntry(
                            index:
                            3 + index,
                            child:
                            _JobListCard(
                              job:
                              jobs[index],
                            ),
                          );
                        },
                      ),
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

  // ==========================================================================
  // HEADER
  // ==========================================================================

  Widget _buildHeader() {
    return Row(
      crossAxisAlignment:
      CrossAxisAlignment.center,
      children: [
        Container(
          width:
          42,
          height:
          42,
          decoration:
          BoxDecoration(
            color:
            AppColors.blue.withOpacity(
              0.08,
            ),
            borderRadius:
            BorderRadius.circular(
              13,
            ),
          ),
          child:
          const Icon(
            Icons.work_outline_rounded,
            color:
            AppColors.blue,
            size:
            20,
          ),
        ),

        const SizedBox(
          width:
          12,
        ),

        const Expanded(
          child:
          Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              Text(
                'Find Drone Jobs',
                style:
                TextStyle(
                  color:
                  AppColors.navy,
                  fontSize:
                  18,
                  fontWeight:
                  FontWeight.w800,
                  letterSpacing:
                  -0.5,
                  height:
                  1.1,
                ),
              ),

              SizedBox(
                height:
                4,
              ),

              Text(
                'Discover opportunities that match your skills',
                style:
                TextStyle(
                  color:
                  AppColors.grey,
                  fontSize:
                  11.5,
                  height:
                  1.3,
                  fontWeight:
                  FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ==========================================================================
  // SEARCH
  // ==========================================================================

  Widget _buildSearchField() {
    return Container(
      decoration:
      BoxDecoration(
        borderRadius:
        BorderRadius.circular(
          17,
        ),
        boxShadow: [
          BoxShadow(
            color:
            AppColors.navy.withOpacity(
              0.028,
            ),
            blurRadius:
            14,
            offset:
            const Offset(
              0,
              5,
            ),
          ),
        ],
      ),
      child:
      TextField(
        controller:
        _searchController,
        textInputAction:
        TextInputAction.search,
        style:
        const TextStyle(
          color:
          AppColors.navy,
          fontSize:
          13.5,
          fontWeight:
          FontWeight.w500,
        ),
        decoration:
        InputDecoration(
          hintText:
          'Search jobs, company, location...',

          hintStyle:
          TextStyle(
            color:
            AppColors.grey.withOpacity(
              0.78,
            ),
            fontSize:
            12.5,
            fontWeight:
            FontWeight.w400,
          ),

          prefixIcon:
          Container(
            margin:
            const EdgeInsets.all(
              11,
            ),
            decoration:
            BoxDecoration(
              color:
              AppColors.blue.withOpacity(
                0.07,
              ),
              borderRadius:
              BorderRadius.circular(
                10,
              ),
            ),
            child:
            const Icon(
              Icons.search_rounded,
              color:
              AppColors.blue,
              size:
              18,
            ),
          ),

          suffixIcon:
          _searchController.text.isEmpty
              ? null
              : IconButton(
            tooltip:
            'Clear search',
            onPressed:
                () {
              HapticFeedback.selectionClick();

              _searchController.clear();
            },
            icon:
            Container(
              width:
              28,
              height:
              28,
              decoration:
              BoxDecoration(
                color:
                AppColors.grey.withOpacity(
                  0.07,
                ),
                shape:
                BoxShape.circle,
              ),
              child:
              const Icon(
                Icons.close_rounded,
                color:
                AppColors.grey,
                size:
                15,
              ),
            ),
          ),

          filled:
          true,

          fillColor:
          Colors.white,

          contentPadding:
          const EdgeInsets.symmetric(
            vertical:
            15,
          ),

          border:
          OutlineInputBorder(
            borderRadius:
            BorderRadius.circular(
              17,
            ),
            borderSide:
            const BorderSide(
              color:
              AppColors.cardBorder,
              width:
              0.8,
            ),
          ),

          enabledBorder:
          OutlineInputBorder(
            borderRadius:
            BorderRadius.circular(
              17,
            ),
            borderSide:
            const BorderSide(
              color:
              AppColors.cardBorder,
              width:
              0.8,
            ),
          ),

          focusedBorder:
          OutlineInputBorder(
            borderRadius:
            BorderRadius.circular(
              17,
            ),
            borderSide:
            const BorderSide(
              color:
              AppColors.blue,
              width:
              1.25,
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================================================
  // RESULTS ROW
  // ==========================================================================

  Widget _buildResultsRow(
      int count,
      ) {
    return Row(
      children: [
        Container(
          padding:
          const EdgeInsets.symmetric(
            horizontal:
            9,
            vertical:
            5,
          ),
          decoration:
          BoxDecoration(
            color:
            AppColors.blue.withOpacity(
              0.06,
            ),
            borderRadius:
            BorderRadius.circular(
              20,
            ),
          ),
          child:
          Row(
            mainAxisSize:
            MainAxisSize.min,
            children: [
              const Icon(
                Icons
                    .work_history_outlined,
                color:
                AppColors.blue,
                size:
                13,
              ),

              const SizedBox(
                width:
                5,
              ),

              Text(
                '$count jobs found',
                style:
                const TextStyle(
                  color:
                  AppColors.navy,
                  fontSize:
                  11.5,
                  fontWeight:
                  FontWeight.w600,
                ),
              ),
            ],
          ),
        ),

        const Spacer(),

        const _FilterPill(
          label:
          'Closest first',
          icon:
          Icons.tune_rounded,
        ),
      ],
    );
  }
}

// ============================================================================
// JOB CARD
// ============================================================================

class _JobListCard extends StatefulWidget {
  const _JobListCard({
    required this.job,
  });

  final PilotJob job;

  @override
  State<_JobListCard> createState() =>
      _JobListCardState();
}

class _JobListCardState extends State<_JobListCard> {
  bool _pressed = false;

  @override
  Widget build(
      BuildContext context,
      ) {
    final job =
        widget.job;

    final bool isSolar =
        job.id ==
            solarFarmJob.id;

    return AnimatedScale(
      duration:
      const Duration(
        milliseconds:
        120,
      ),
      scale:
      _pressed
          ? 0.985
          : 1,
      child:
      Material(
        color:
        Colors.transparent,
        child:
        InkWell(
          borderRadius:
          BorderRadius.circular(
            20,
          ),
          onTapDown:
              (_) {
            setState(() {
              _pressed =
              true;
            });
          },
          onTapCancel:
              () {
            setState(() {
              _pressed =
              false;
            });
          },
          onTapUp:
              (_) {
            setState(() {
              _pressed =
              false;
            });
          },
          onTap:
              () {
            HapticFeedback.selectionClick();

            Navigator.of(
              context,
            ).push(
              MaterialPageRoute(
                builder:
                    (_) =>
                    JobDetailsScreen(
                      job:
                      job,
                    ),
              ),
            );
          },
          child:
          Ink(
            padding:
            const EdgeInsets.all(
              16,
            ),
            decoration:
            BoxDecoration(
              color:
              Colors.white,
              borderRadius:
              BorderRadius.circular(
                20,
              ),
              border:
              Border.all(
                color:
                AppColors.cardBorder.withOpacity(
                  0.9,
                ),
                width:
                0.8,
              ),
              boxShadow: [
                BoxShadow(
                  color:
                  AppColors.navy.withOpacity(
                    0.035,
                  ),
                  blurRadius:
                  18,
                  offset:
                  const Offset(
                    0,
                    7,
                  ),
                ),
              ],
            ),
            child:
            Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                // ==========================================================
                // TOP
                // ==========================================================

                Row(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Container(
                      width:
                      48,
                      height:
                      48,
                      decoration:
                      BoxDecoration(
                        color:
                        isSolar
                            ? AppColors.orangeBg
                            : AppColors.blueBg,
                        borderRadius:
                        BorderRadius.circular(
                          14,
                        ),
                      ),
                      child:
                      Icon(
                        isSolar
                            ? Icons.solar_power_rounded
                            : Icons.flight_takeoff_rounded,
                        color:
                        isSolar
                            ? AppColors.orange
                            : AppColors.blue,
                        size:
                        22,
                      ),
                    ),

                    const SizedBox(
                      width:
                      12,
                    ),

                    Expanded(
                      child:
                      Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          Text(
                            job.title,
                            maxLines:
                            2,
                            overflow:
                            TextOverflow.ellipsis,
                            style:
                            const TextStyle(
                              color:
                              AppColors.navy,
                              fontSize:
                              15.5,
                              fontWeight:
                              FontWeight.w800,
                              height:
                              1.25,
                              letterSpacing:
                              -0.15,
                            ),
                          ),

                          const SizedBox(
                            height:
                            4,
                          ),

                          Text(
                            job.company,
                            maxLines:
                            1,
                            overflow:
                            TextOverflow.ellipsis,
                            style:
                            TextStyle(
                              color:
                              AppColors.grey.withOpacity(
                                0.92,
                              ),
                              fontSize:
                              12,
                              fontWeight:
                              FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(
                      width:
                      7,
                    ),

                    Container(
                      width:
                      31,
                      height:
                      31,
                      decoration:
                      BoxDecoration(
                        color:
                        AppColors.blue.withOpacity(
                          0.055,
                        ),
                        shape:
                        BoxShape.circle,
                      ),
                      child:
                      const Icon(
                        Icons.chevron_right_rounded,
                        color:
                        AppColors.blue,
                        size:
                        19,
                      ),
                    ),
                  ],
                ),

                const SizedBox(
                  height:
                  14,
                ),

                // ==========================================================
                // LOCATION + DATE
                // ==========================================================

                Row(
                  children: [
                    Expanded(
                      child:
                      _InfoItem(
                        icon:
                        Icons.location_on_outlined,
                        text:
                        '${job.location} · ${job.distance}',
                      ),
                    ),

                    const SizedBox(
                      width:
                      9,
                    ),

                    _InfoItem(
                      icon:
                      Icons.calendar_today_outlined,
                      text:
                      job.date,
                    ),
                  ],
                ),

                const Padding(
                  padding:
                  EdgeInsets.symmetric(
                    vertical:
                    14,
                  ),
                  child:
                  Divider(
                    height:
                    1,
                    color:
                    AppColors.cardBorder,
                  ),
                ),

                // ==========================================================
                // PAY + CAPABILITIES
                // ==========================================================

                Row(
                  crossAxisAlignment:
                  CrossAxisAlignment.center,
                  children: [
                    Container(
                      padding:
                      const EdgeInsets.symmetric(
                        horizontal:
                        10,
                        vertical:
                        7,
                      ),
                      decoration:
                      BoxDecoration(
                        color:
                        AppColors.green.withOpacity(
                          0.075,
                        ),
                        borderRadius:
                        BorderRadius.circular(
                          11,
                        ),
                      ),
                      child:
                      Text(
                        job.pay,
                        style:
                        const TextStyle(
                          color:
                          AppColors.green,
                          fontSize:
                          14,
                          fontWeight:
                          FontWeight.w800,
                          letterSpacing:
                          -0.15,
                        ),
                      ),
                    ),

                    const SizedBox(
                      width:
                      8,
                    ),

                    Expanded(
                      child:
                      Wrap(
                        alignment:
                        WrapAlignment.end,
                        spacing:
                        6,
                        runSpacing:
                        5,
                        children:
                        job.capabilities
                            .take(
                          2,
                        )
                            .map(
                              (
                              capability,
                              ) =>
                              _CapabilityPill(
                                label:
                                capability,
                              ),
                        )
                            .toList(),
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

// ============================================================================
// INFO ITEM
// ============================================================================

class _InfoItem extends StatelessWidget {
  const _InfoItem({
    required this.icon,
    required this.text,
  });

  final IconData icon;

  final String text;

  @override
  Widget build(
      BuildContext context,
      ) {
    return Row(
      mainAxisSize:
      MainAxisSize.min,
      children: [
        Icon(
          icon,
          size:
          14,
          color:
          AppColors.grey,
        ),

        const SizedBox(
          width:
          4,
        ),

        Flexible(
          child:
          Text(
            text,
            maxLines:
            1,
            overflow:
            TextOverflow.ellipsis,
            style:
            TextStyle(
              color:
              AppColors.grey.withOpacity(
                0.9,
              ),
              fontSize:
              11.5,
              fontWeight:
              FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// CAPABILITY
// ============================================================================

class _CapabilityPill extends StatelessWidget {
  const _CapabilityPill({
    required this.label,
  });

  final String label;

  @override
  Widget build(
      BuildContext context,
      ) {
    return Container(
      padding:
      const EdgeInsets.symmetric(
        horizontal:
        8,
        vertical:
        5,
      ),
      decoration:
      BoxDecoration(
        color:
        AppColors.blue.withOpacity(
          0.055,
        ),
        borderRadius:
        BorderRadius.circular(
          9,
        ),
        border:
        Border.all(
          color:
          AppColors.blue.withOpacity(
            0.08,
          ),
        ),
      ),
      child:
      Text(
        label,
        maxLines:
        1,
        overflow:
        TextOverflow.ellipsis,
        style:
        const TextStyle(
          color:
          AppColors.navy,
          fontSize:
          9.5,
          fontWeight:
          FontWeight.w600,
        ),
      ),
    );
  }
}

// ============================================================================
// FILTER
// ============================================================================

class _FilterPill extends StatelessWidget {
  const _FilterPill({
    required this.label,
    required this.icon,
  });

  final String label;

  final IconData icon;

  @override
  Widget build(
      BuildContext context,
      ) {
    return Material(
      color:
      Colors.white,
      borderRadius:
      BorderRadius.circular(
        20,
      ),
      child:
      InkWell(
        borderRadius:
        BorderRadius.circular(
          20,
        ),
        onTap:
            () {},
        child:
        Container(
          padding:
          const EdgeInsets.symmetric(
            horizontal:
            10,
            vertical:
            6,
          ),
          decoration:
          BoxDecoration(
            borderRadius:
            BorderRadius.circular(
              20,
            ),
            border:
            Border.all(
              color:
              AppColors.cardBorder,
            ),
          ),
          child:
          Row(
            mainAxisSize:
            MainAxisSize.min,
            children: [
              Icon(
                icon,
                color:
                AppColors.blue,
                size:
                13,
              ),

              const SizedBox(
                width:
                5,
              ),

              Text(
                label,
                style:
                const TextStyle(
                  color:
                  AppColors.navy,
                  fontSize:
                  10.5,
                  fontWeight:
                  FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// NO RESULTS
// ============================================================================

class _NoResults extends StatelessWidget {
  const _NoResults();

  @override
  Widget build(
      BuildContext context,
      ) {
    return Center(
      child:
      Padding(
        padding:
        const EdgeInsets.symmetric(
          horizontal:
          30,
        ),
        child:
        Column(
          mainAxisSize:
          MainAxisSize.min,
          children: [
            Container(
              width:
              66,
              height:
              66,
              decoration:
              BoxDecoration(
                color:
                AppColors.blue.withOpacity(
                  0.06,
                ),
                shape:
                BoxShape.circle,
              ),
              child:
              const Icon(
                Icons.search_off_rounded,
                color:
                AppColors.blue,
                size:
                27,
              ),
            ),

            const SizedBox(
              height:
              14,
            ),

            const Text(
              'No jobs match this search',
              textAlign:
              TextAlign.center,
              style:
              TextStyle(
                color:
                AppColors.navy,
                fontSize:
                14,
                fontWeight:
                FontWeight.w700,
              ),
            ),

            const SizedBox(
              height:
              5,
            ),

            Text(
              'Try another job title, company, or location.',
              textAlign:
              TextAlign.center,
              style:
              TextStyle(
                color:
                AppColors.grey.withOpacity(
                  0.8,
                ),
                fontSize:
                11.5,
                height:
                1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}