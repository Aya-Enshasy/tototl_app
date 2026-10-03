import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tototl_app/features/pilot/models/pilot_home_snapshot.dart';

class RecentApplicationsSection extends StatelessWidget {
  const RecentApplicationsSection({
    super.key,
    required this.applications,
    required this.loading,
    required this.errorMessage,
    required this.onRetry,
    required this.onSeeAll,
    required this.onExploreJobs,
    required this.onOpenApplication,
  });

  final List<PilotHomeApplicationItem> applications;
  final bool loading;
  final String? errorMessage;
  final VoidCallback onRetry;
  final VoidCallback onSeeAll;
  final VoidCallback onExploreJobs;
  final ValueChanged<PilotHomeApplicationItem>
  onOpenApplication;

  @override
  Widget build(BuildContext context) {
    if (loading && applications.isEmpty) {
      return const _RecentShimmer();
    }

    if (errorMessage != null &&
        applications.isEmpty) {
      return _SimpleState(
        title: 'Recent application',
        message:
        'Applications could not be refreshed.',
        action: 'Retry',
        onTap: onRetry,
      );
    }

    if (applications.isEmpty) {
      return _SimpleState(
        title: 'Recent application',
        message:
        'No applications yet. Explore published jobs when you are ready.',
        action: 'Explore jobs',
        onTap: onExploreJobs,
      );
    }

    final application = applications.first;

    return Container(
      padding:
      const EdgeInsets.fromLTRB(
        11,
        10,
        9,
        10,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(17),
        border: Border.all(
          color:
          const Color(0xFFDDE8EC),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 31,
                height: 31,
                decoration:
                BoxDecoration(
                  color:
                  const Color(
                      0xFFE8F8F8),
                  borderRadius:
                  BorderRadius.circular(
                      9),
                ),
                child: const Icon(
                  Icons
                      .assignment_outlined,
                  color:
                  Color(0xFF078FA5),
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Recent application',
                  style: TextStyle(
                    color:
                    Color(0xFF0A2D46),
                    fontSize: 11.5,
                    fontWeight:
                    FontWeight.w800,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () {
                  HapticFeedback
                      .selectionClick();
                  onSeeAll();
                },
                child: const Padding(
                  padding:
                  EdgeInsets.all(4),
                  child: Text(
                    'View all',
                    style: TextStyle(
                      color:
                      Color(0xFF078FA5),
                      fontSize: 8.9,
                      fontWeight:
                      FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                HapticFeedback
                    .selectionClick();
                onOpenApplication(
                    application);
              },
              borderRadius:
              BorderRadius.circular(
                  11),
              child: Padding(
                padding:
                const EdgeInsets
                    .symmetric(
                  vertical: 2,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 54,
                      height: 48,
                      clipBehavior: Clip.antiAlias,
                      decoration:
                      BoxDecoration(
                        color:
                        const Color(
                            0xFFF0F7F8),
                        borderRadius:
                        BorderRadius
                            .circular(9),
                        border: Border.all(
                          color:
                          const Color(
                              0xFFE0E9EC),
                        ),
                      ),
                      child: application
                          .companyPhoto
                          .trim()
                          .isNotEmpty
                          ? Image.network(
                        application
                            .companyPhoto
                            .trim(),
                        fit: BoxFit.cover,
                        gaplessPlayback:
                        true,
                        filterQuality:
                        FilterQuality
                            .high,
                        errorBuilder:
                            (_, __, ___) =>
                        const Icon(
                          Icons
                              .business_outlined,
                          color:
                          Color(
                              0xFF078FA5),
                          size: 20,
                        ),
                      )
                          : const Icon(
                        Icons
                            .business_outlined,
                        color:
                        Color(
                            0xFF078FA5),
                        size: 20,
                      ),
                    ),
                    const SizedBox(
                        width: 9),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment
                            .start,
                        children: [
                          Text(
                            application
                                .jobTitle
                                .trim()
                                .isEmpty
                                ? 'Job application'
                                : application
                                .jobTitle
                                .trim(),
                            maxLines: 1,
                            overflow:
                            TextOverflow
                                .ellipsis,
                            style:
                            const TextStyle(
                              color:
                              Color(
                                  0xFF0A2D46),
                              fontSize: 10.7,
                              fontWeight:
                              FontWeight
                                  .w800,
                            ),
                          ),
                          const SizedBox(
                              height: 2),
                          Text(
                            [
                              if (application
                                  .company
                                  .trim()
                                  .isNotEmpty)
                                application
                                    .company
                                    .trim(),
                              if (application
                                  .location
                                  .trim()
                                  .isNotEmpty)
                                application
                                    .location
                                    .trim(),
                            ].join('  ·  '),
                            maxLines: 1,
                            overflow:
                            TextOverflow
                                .ellipsis,
                            style:
                            const TextStyle(
                              color:
                              Color(
                                  0xFF7F91A0),
                              fontSize: 8.5,
                            ),
                          ),
                          if (application
                              .submittedLabel
                              .trim()
                              .isNotEmpty) ...[
                            const SizedBox(
                                height: 3),
                            Row(
                              children: [
                                const Icon(
                                  Icons
                                      .schedule_rounded,
                                  size: 10,
                                  color:
                                  Color(
                                      0xFF7F91A0),
                                ),
                                const SizedBox(
                                    width: 3),
                                Flexible(
                                  child: Text(
                                    application
                                        .submittedLabel
                                        .trim(),
                                    maxLines: 1,
                                    overflow:
                                    TextOverflow
                                        .ellipsis,
                                    style:
                                    const TextStyle(
                                      color:
                                      Color(
                                          0xFF7F91A0),
                                      fontSize:
                                      8.1,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      width: 27,
                      height: 27,
                      decoration:
                      const BoxDecoration(
                        color:
                        Color(
                            0xFFE8F8F8),
                        shape:
                        BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons
                            .chevron_right_rounded,
                        color:
                        Color(
                            0xFF078FA5),
                        size: 17,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SimpleState extends StatelessWidget {
  const _SimpleState({
    required this.title,
    required this.message,
    required this.action,
    required this.onTap,
  });

  final String title;
  final String message;
  final String action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
      const EdgeInsets.fromLTRB(
        11,
        10,
        9,
        10,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(17),
        border: Border.all(
          color:
          const Color(0xFFDDE8EC),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 35,
            height: 35,
            decoration:
            BoxDecoration(
              color:
              const Color(
                  0xFFE8F8F8),
              borderRadius:
              BorderRadius.circular(
                  10),
            ),
            child: const Icon(
              Icons.assignment_outlined,
              color:
              Color(0xFF078FA5),
              size: 17,
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style:
                  const TextStyle(
                    color:
                    Color(0xFF0A2D46),
                    fontSize: 10.8,
                    fontWeight:
                    FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  message,
                  style:
                  const TextStyle(
                    color:
                    Color(0xFF7F91A0),
                    fontSize: 8.7,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onTap,
            style: TextButton.styleFrom(
              foregroundColor:
              const Color(
                  0xFF078FA5),
              visualDensity:
              VisualDensity.compact,
            ),
            child: Text(
              action,
              style:
              const TextStyle(
                fontSize: 8.7,
                fontWeight:
                FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentShimmer extends StatelessWidget {
  const _RecentShimmer();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 102,
      decoration: BoxDecoration(
        color:
        const Color(0xFFE9F0F2),
        borderRadius:
        BorderRadius.circular(17),
      ),
    );
  }
}
