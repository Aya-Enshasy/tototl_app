import 'package:tototl_app/core/localization/localized_text.dart';
import 'package:flutter/material.dart';
import 'package:tototl_app/core/localization/app_language.dart';
import 'package:flutter/services.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/request_error_message.dart';
import '../../../core/theme/app_colors.dart';
import '../controllers/review_controller.dart';
import '../models/review_model.dart';
import '../services/review_service.dart';

class ReviewsScreen extends StatefulWidget {
  const ReviewsScreen({
    super.key,
    required this.profileId,
    required this.targetType,
    this.targetName = '',
  });

  final int profileId;
  final ReviewTargetType targetType;
  final String targetName;

  @override
  State<ReviewsScreen> createState() =>
      _ReviewsScreenState();
}

class _ReviewsScreenState
    extends State<ReviewsScreen> {
  late final ReviewController _controller;
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();

    _controller = ReviewController(
      ReviewService(
        ApiClient(),
      ),
    );

    _scrollController =
    ScrollController()
      ..addListener(
        _onScroll,
      );

    _controller.addListener(
      _onControllerChanged,
    );

    WidgetsBinding.instance.addPostFrameCallback(
          (_) {
        _load();
      },
    );
  }

  @override
  void dispose() {
    _controller.removeListener(
      _onControllerChanged,
    );

    _scrollController
      ..removeListener(
        _onScroll,
      )
      ..dispose();

    _controller.dispose();

    super.dispose();
  }

  void _onControllerChanged() {
    if (!mounted) {
      return;
    }

    setState(() {});
  }

  void _onScroll() {
    if (!_scrollController.hasClients ||
        !_controller.canLoadMore) {
      return;
    }

    final position =
        _scrollController.position;

    if (position.pixels >=
        position.maxScrollExtent - 260) {
      _controller.loadMore();
    }
  }

  Future<void> _load({
    bool refresh = false,
  }) async {
    if (widget.targetType ==
        ReviewTargetType.pilot) {
      await _controller.loadPilotReviews(
        widget.profileId,
        refresh: refresh,
      );
    } else {
      await _controller.loadCompanyReviews(
        widget.profileId,
        refresh: refresh,
      );
    }
  }

  Future<void> _refresh() async {
    HapticFeedback.selectionClick();

    await _load(
      refresh: true,
    );
  }

  String get _targetName {
    final value =
    widget.targetName.trim();

    if (value.isNotEmpty) {
      return value;
    }

    return widget.targetType ==
        ReviewTargetType.pilot
        ? 'Pilot'
        : 'Company';
  }

  String get _screenTitle {
    return widget.targetType ==
        ReviewTargetType.pilot
        ? 'Pilot Reviews'
        : 'Company Reviews';
  }

  String get _subtitle {
    return widget.targetType ==
        ReviewTargetType.pilot
        ? 'Feedback from companies who completed missions with this pilot.'
        : 'Feedback from pilots who completed missions with this company.';
  }

  @override
  Widget build(
      BuildContext context,
      ) {
    return Scaffold(
      backgroundColor:
      AppColors.bg,
      body: Stack(
        children: [
          const _ReviewsBackdrop(),
          SafeArea(
            child: Column(
              children: [
                _topBar(),
                Expanded(
                  child: _body(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _topBar() {
    return Padding(
      padding:
      const EdgeInsets
          .fromLTRB(
        14,
        10,
        14,
        8,
      ),
      child: Row(
        children: [
          _RoundButton(
            icon: Icons
                .arrow_back_ios_new_rounded,
            onTap: () {
              HapticFeedback
                  .selectionClick();

              Navigator.of(
                context,
              ).pop();
            },
          ),
          const SizedBox(
            width: 11,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment
                  .start,
              children: [
                Text(
                  _screenTitle,
                  style:
                  const TextStyle(
                    color:
                    AppColors.navy,
                    fontSize: 17.5,
                    height: 1,
                    fontWeight:
                    FontWeight.w900,
                    letterSpacing:
                    -.4,
                  ),
                ),
                const SizedBox(
                  height: 5,
                ),
                Text(
                  _targetName,
                  maxLines: 1,
                  overflow:
                  TextOverflow
                      .ellipsis,
                  style:
                  const TextStyle(
                    color:
                    AppColors.grey,
                    fontSize: 9.8,
                    fontWeight:
                    FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          if (_controller.isLoading &&
              _controller.reviews.isNotEmpty)
            const SizedBox(
              width: 18,
              height: 18,
              child:
              CircularProgressIndicator(
                strokeWidth: 2,
                color:
                AppColors.blue,
              ),
            ),
        ],
      ),
    );
  }

  Widget _body() {
    if (_controller.isLoading &&
        _controller.data == null) {
      return const _ReviewsShimmer();
    }

    if (_controller.errorMessage != null &&
        _controller.data == null) {
      return _ErrorState(
        message: RequestErrorMessage.from(
          StateError(_controller.errorMessage!),
          fallback: 'Could not load reviews. Please retry.',
        ),
        onRetry: () {
          _load();
        },
      );
    }

    return RefreshIndicator(
      color: AppColors.blue,
      onRefresh: _refresh,
      child: ListView(
        controller:
        _scrollController,
        physics:
        const AlwaysScrollableScrollPhysics(
          parent:
          BouncingScrollPhysics(),
        ),
        padding:
        const EdgeInsets
            .fromLTRB(
          16,
          8,
          16,
          34,
        ),
        children: [
          _summaryCard(),
          const SizedBox(
            height: 14,
          ),
          _sectionHeader(),
          const SizedBox(
            height: 10,
          ),
          if (_controller.reviews.isEmpty)
            _emptyState()
          else
            ..._controller.reviews.map(
                  (review) => Padding(
                padding:
                const EdgeInsets
                    .only(
                  bottom: 10,
                ),
                child:
                _reviewCard(
                  review,
                ),
              ),
            ),
          if (_controller.isLoadingMore)
            const Padding(
              padding:
              EdgeInsets
                  .symmetric(
                vertical: 16,
              ),
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child:
                  CircularProgressIndicator(
                    strokeWidth: 2.3,
                    color:
                    AppColors.blue,
                  ),
                ),
              ),
            ),
          if (_controller.errorMessage != null &&
              _controller.reviews.isNotEmpty)
            _loadMoreError(),
        ],
      ),
    );
  }

  Widget _summaryCard() {
    final summary =
        _controller.summary;

    final average =
        summary.averageValue;

    final averageLabel =
    average == null
        ? '—'
        : average
        .toStringAsFixed(
      1,
    );

    return Container(
      width:
      double.infinity,
      padding:
      const EdgeInsets
          .fromLTRB(
        20,
        20,
        20,
        19,
      ),
      decoration:
      BoxDecoration(
        gradient:
        const LinearGradient(
          begin:
          Alignment.topLeft,
          end:
          Alignment.bottomRight,
          colors: [
            Color(
              0xFF061827,
            ),
            Color(
              0xFF07394B,
            ),
            Color(
              0xFF087E88,
            ),
          ],
          stops: [
            0,
            .58,
            1,
          ],
        ),
        borderRadius:
        BorderRadius.circular(
          27,
        ),
        boxShadow: [
          BoxShadow(
            color:
            const Color(
              0xFF087D88,
            ).withOpacity(
              .18,
            ),
            blurRadius: 30,
            offset:
            const Offset(
              0,
              14,
            ),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -42,
            top: -55,
            child:
            Container(
              width: 150,
              height: 150,
              decoration:
              BoxDecoration(
                shape:
                BoxShape.circle,
                border:
                Border.all(
                  color: Colors
                      .white
                      .withOpacity(
                    .07,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            right: 28,
            bottom: -58,
            child:
            Container(
              width: 115,
              height: 115,
              decoration:
              BoxDecoration(
                shape:
                BoxShape.circle,
                color:
                const Color(
                  0xFF50E2D1,
                ).withOpacity(
                  .055,
                ),
              ),
            ),
          ),
          Row(
            crossAxisAlignment:
            CrossAxisAlignment
                .center,
            children: [
              Container(
                width: 76,
                height: 76,
                decoration:
                BoxDecoration(
                  color: Colors
                      .white
                      .withOpacity(
                    .10,
                  ),
                  borderRadius:
                  BorderRadius
                      .circular(
                    22,
                  ),
                  border:
                  Border.all(
                    color: Colors
                        .white
                        .withOpacity(
                      .11,
                    ),
                  ),
                ),
                child: Column(
                  mainAxisAlignment:
                  MainAxisAlignment
                      .center,
                  children: [
                    const Icon(
                      Icons
                          .star_rounded,
                      color:
                      Color(
                        0xFFFFC94A,
                      ),
                      size: 25,
                    ),
                    const SizedBox(
                      height: 3,
                    ),
                    Text(
                      averageLabel,
                      style:
                      const TextStyle(
                        color:
                        Colors.white,
                        fontSize: 21,
                        height: 1,
                        fontWeight:
                        FontWeight
                            .w900,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(
                width: 15,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
                  children: [
                    const LocalizedText(
                      'Community Rating',
                      style:
                      TextStyle(
                        color:
                        Colors.white,
                        fontSize: 16,
                        fontWeight:
                        FontWeight
                            .w900,
                        letterSpacing:
                        -.25,
                      ),
                    ),
                    const SizedBox(
                      height: 6,
                    ),
                    _starRow(
                      average ?? 0,
                    ),
                    const SizedBox(
                      height: 7,
                    ),
                    Text(
                      summary.count == 0
                          ? 'No reviews yet'
                          : summary.count == 1
                          ? 'Based on 1 verified review'
                          : 'Based on ${summary.count} verified reviews',
                      style:
                      TextStyle(
                        color: Colors
                            .white
                            .withOpacity(
                          .67,
                        ),
                        fontSize:
                        10.3,
                        fontWeight:
                        FontWeight.w600
                        ,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader() {
    return Row(
      children: [
        Container(
          width: 33,
          height: 33,
          decoration:
          BoxDecoration(
            color: AppColors.blue
                .withOpacity(
              .08,
            ),
            borderRadius:
            BorderRadius
                .circular(
              10,
            ),
          ),
          child:
          const Icon(
            Icons
                .reviews_outlined,
            color:
            AppColors.blue,
            size: 17,
          ),
        ),
        const SizedBox(
          width: 9,
        ),
        Expanded(
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment
                .start,
            children: [
              const LocalizedText(
                'Reviews',
                style:
                TextStyle(
                  color:
                  AppColors.navy,
                  fontSize: 13,
                  fontWeight:
                  FontWeight
                      .w900,
                ),
              ),
              const SizedBox(
                height: 2,
              ),
              Text(
                _subtitle,
                maxLines: 2,
                style:
                const TextStyle(
                  color:
                  AppColors.grey,
                  fontSize: 9.5,
                  height: 1.35,
                  fontWeight:
                  FontWeight.w600
                 ),
              ),
            ],
          ),
        ),
        if (_controller.pagination.total >
            0)
          Container(
            padding:
            const EdgeInsets
                .symmetric(
              horizontal: 9,
              vertical: 5,
            ),
            decoration:
            BoxDecoration(
              color:
              Colors.white,
              borderRadius:
              BorderRadius
                  .circular(
                30,
              ),
              border:
              Border.all(
                color:
                AppColors
                    .cardBorder,
              ),
            ),
            child: Text(
              '${_controller.pagination.total}',
              style:
              const TextStyle(
                color:
                AppColors.navy,
                fontSize: 9.5,
                fontWeight:
                FontWeight
                    .w900,
              ),
            ),
          ),
      ],
    );
  }

  Widget _reviewCard(
      ReviewModel review,
      ) {
    final reviewer =
        review.reviewer;

    final photo =
        reviewer?.profilePhoto
            .trim() ??
            '';

    return Container(
      width:
      double.infinity,
      padding:
      const EdgeInsets.all(
        15,
      ),
      decoration:
      BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(
          20,
        ),
        border:
        Border.all(
          color:
          AppColors.cardBorder,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy
                .withOpacity(
              .025,
            ),
            blurRadius: 16,
            offset:
            const Offset(
              0,
              6,
            ),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment
            .start,
        children: [
          Row(
            children: [
              _avatar(
                photo,
                review
                    .reviewerName,
              ),
              const SizedBox(
                width: 10,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
                  children: [
                    Text(
                      review
                          .reviewerName,
                      maxLines: 1,
                      overflow:
                      TextOverflow
                          .ellipsis,
                      style:
                      const TextStyle(
                        color:
                        AppColors.navy,
                        fontSize: 12,
                        fontWeight:
                        FontWeight
                            .w900,
                      ),
                    ),
                    const SizedBox(
                      height: 3,
                    ),
                    Row(
                      children: [
                        if (review
                            .reviewerRole
                            .isNotEmpty) ...[
                          Text(
                            reviewer
                                ?.roleLabel ??
                                '',
                            style:
                            const TextStyle(
                              color:
                              AppColors
                                  .grey,
                              fontSize:
                              9.3,
                              fontWeight:
                              FontWeight.w700
                             ),
                          ),
                           Padding(
                            padding:
                            EdgeInsets
                                .symmetric(
                              horizontal:
                              5,
                            ),
                            child:
                            Text(AppLanguage.text(
                              '•'),
                              style:
                              TextStyle(
                                color:
                                AppColors
                                    .lightGrey,
                                fontSize:
                                9,
                              ),
                            ),
                          ),
                        ],
                        Flexible(
                          child: Text(
                            review
                                .createdLabel,
                            maxLines: 1,
                            overflow:
                            TextOverflow
                                .ellipsis,
                            style:
                            const TextStyle(
                              color:
                              AppColors
                                  .grey,
                              fontSize:
                              9.3,
                              fontWeight:
                              FontWeight.w600
                             ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                const EdgeInsets
                    .symmetric(
                  horizontal: 9,
                  vertical: 6,
                ),
                decoration:
                BoxDecoration(
                  color:
                  const Color(
                    0xFFFFF8E1,
                  ),
                  borderRadius:
                  BorderRadius
                      .circular(
                    30,
                  ),
                  border:
                  Border.all(
                    color:
                    const Color(
                      0xFFFFC94A,
                    ).withOpacity(
                      .22,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisSize:
                  MainAxisSize
                      .min,
                  children: [
                    const Icon(
                      Icons
                          .star_rounded,
                      color:
                      Color(
                        0xFFFFB600,
                      ),
                      size: 14,
                    ),
                    const SizedBox(
                      width: 3,
                    ),
                    Text(
                      '${review.rating}.0',
                      style:
                      const TextStyle(
                        color:
                        Color(
                          0xFF9A7200,
                        ),
                        fontSize: 10,
                        fontWeight:
                        FontWeight
                            .w900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(
            height: 12,
          ),
          Row(
            children: List.generate(
              5,
                  (index) {
                return Padding(
                  padding:
                  const EdgeInsets
                      .only(
                    right: 2,
                  ),
                  child: Icon(
                    index <
                        review
                            .rating
                        ? Icons
                        .star_rounded
                        : Icons
                        .star_border_rounded,
                    size: 16,
                    color: index <
                        review
                            .rating
                        ? const Color(
                      0xFFFFB600,
                    )
                        : const Color(
                      0xFFD9DFE6,
                    ),
                  ),
                );
              },
            ),
          ),
          if (review.hasComment) ...[
            const SizedBox(
              height: 11,
            ),
            Text(
              review.comment,
              style:
              const TextStyle(
                color:
                AppColors.text,
                fontSize: 11,
                height: 1.55,
                fontWeight:
                FontWeight.w600
               ),
            ),
          ],
          const SizedBox(
            height: 12,
          ),
          Container(
            width:
            double.infinity,
            padding:
            const EdgeInsets
                .fromLTRB(
              11,
              9,
              11,
              9,
            ),
            decoration:
            BoxDecoration(
              color:
              AppColors.bg,
              borderRadius:
              BorderRadius
                  .circular(
                12,
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons
                      .work_outline_rounded,
                  size: 14,
                  color:
                  AppColors.grey,
                ),
                const SizedBox(
                  width: 7,
                ),
                Expanded(
                  child: Text(
                    review
                        .jobTitle,
                    maxLines: 1,
                    overflow:
                    TextOverflow
                        .ellipsis,
                    style:
                    const TextStyle(
                      color:
                      AppColors
                          .navy,
                      fontSize:
                      9.8,
                      fontWeight:
                      FontWeight.w800

                    ),
                  ),
                ),
                if (review
                    .contractId >
                    0) ...[
                  const SizedBox(
                    width: 8,
                  ),
                  Text(
                    '#${review.contractId}',
                    style:
                    const TextStyle(
                      color:
                      AppColors
                          .grey,
                      fontSize:
                      9.2,
                      fontWeight:
                      FontWeight.w700

                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _avatar(
      String photo,
      String name,
      ) {
    final cleanName =
    name.trim();

    final initial =
    cleanName.isEmpty
        ? '?'
        : cleanName
        .substring(
      0,
      1,
    )
        .toUpperCase();

    return Container(
      width: 43,
      height: 43,
      decoration:
      BoxDecoration(
        shape:
        BoxShape.circle,
        gradient:
        const LinearGradient(
          begin:
          Alignment.topLeft,
          end:
          Alignment.bottomRight,
          colors: [
            Color(
              0xFF083A53,
            ),
            Color(
              0xFF0A8791,
            ),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color:
            AppColors.navy
                .withOpacity(
              .08,
            ),
            blurRadius: 10,
            offset:
            const Offset(
              0,
              4,
            ),
          ),
        ],
      ),
      padding:
      const EdgeInsets.all(
        2,
      ),
      child:
      ClipOval(
        child: photo.isNotEmpty
            ? Image.network(
          photo,
          fit:
          BoxFit.cover,
          errorBuilder:
              (
              context,
              error,
              stackTrace,
              ) {
            return _avatarFallback(
              initial,
            );
          },
        )
            : _avatarFallback(
          initial,
        ),
      ),
    );
  }

  Widget _avatarFallback(
      String initial,
      ) {
    return Container(
      alignment:
      Alignment.center,
      decoration:
      const BoxDecoration(
        gradient:
        LinearGradient(
          colors: [
            Color(
              0xFF0B3850,
            ),
            Color(
              0xFF087F88,
            ),
          ],
        ),
      ),
      child: Text(
        initial,
        style:
        const TextStyle(
          color: Colors.white,
          fontSize: 15,
          fontWeight:
          FontWeight.w900,
        ),
      ),
    );
  }

  Widget _starRow(
      double average,
      ) {
    return Row(
      children: List.generate(
        5,
            (index) {
          final position =
              index + 1;

          final filled =
              average >= position;

          final half =
              !filled &&
                  average >=
                      position -
                          .5;

          return Padding(
            padding:
            const EdgeInsets
                .only(
              right: 2,
            ),
            child: Icon(
              filled
                  ? Icons
                  .star_rounded
                  : half
                  ? Icons
                  .star_half_rounded
                  : Icons
                  .star_border_rounded,
              size: 17,
              color:
              const Color(
                0xFFFFC94A,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _emptyState() {
    return Container(
      width:
      double.infinity,
      padding:
      const EdgeInsets
          .fromLTRB(
        22,
        30,
        22,
        30,
      ),
      decoration:
      BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(
          22,
        ),
        border:
        Border.all(
          color:
          AppColors.cardBorder,
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration:
            BoxDecoration(
              color:
              const Color(
                0xFFFFF8E4,
              ),
              borderRadius:
              BorderRadius
                  .circular(
                19,
              ),
            ),
            child:
            const Icon(
              Icons
                  .star_outline_rounded,
              color:
              Color(
                0xFFFFB600,
              ),
              size: 30,
            ),
          ),
          const SizedBox(
            height: 14,
          ),
          const LocalizedText(
            'No reviews yet',
            style:
            TextStyle(
              color:
              AppColors.navy,
              fontSize: 14,
              fontWeight:
              FontWeight
                  .w900,
            ),
          ),
          const SizedBox(
            height: 6,
          ),
          Text(
            widget.targetType ==
                ReviewTargetType
                    .pilot
                ? 'Completed missions will build this pilot’s reputation over time.'
                : 'Completed missions will build this company’s reputation over time.',
            textAlign:
            TextAlign.center,
            style:
            const TextStyle(
              color:
              AppColors.grey,
              fontSize: 10.5,
              height: 1.45,
              fontWeight:
              FontWeight.w600

            ),
          ),
        ],
      ),
    );
  }

  Widget _loadMoreError() {
    return Padding(
      padding:
      const EdgeInsets
          .only(
        top: 6,
      ),
      child:
      OutlinedButton.icon(
        onPressed: () {
          _controller
              .clearError();

          _controller
              .loadMore();
        },
        icon:
        const Icon(
          Icons
              .refresh_rounded,
          size: 17,
        ),
        label:
        const LocalizedText(
          'Try again',
        ),
      ),
    );
  }
}

class _ReviewsBackdrop
    extends StatelessWidget {
  const _ReviewsBackdrop();

  @override
  Widget build(
      BuildContext context,
      ) {
    return Stack(
      children: [
        Positioned(
          top: -110,
          right: -90,
          child:
          Container(
            width: 260,
            height: 260,
            decoration:
            BoxDecoration(
              shape:
              BoxShape.circle,
              color:
              const Color(
                0xFF0B8D92,
              ).withOpacity(
                .045,
              ),
            ),
          ),
        ),
        Positioned(
          top: 190,
          left: -120,
          child:
          Container(
            width: 250,
            height: 250,
            decoration:
            BoxDecoration(
              shape:
              BoxShape.circle,
              color:
              AppColors.blue
                  .withOpacity(
                .035,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _RoundButton
    extends StatelessWidget {
  const _RoundButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(
      BuildContext context,
      ) {
    return Material(
      color:
      Colors.white,
      shape:
      const CircleBorder(),
      child: InkWell(
        customBorder:
        const CircleBorder(),
        onTap: onTap,
        child:
        Container(
          width: 40,
          height: 40,
          decoration:
          BoxDecoration(
            shape:
            BoxShape.circle,
            border:
            Border.all(
              color:
              AppColors
                  .cardBorder,
            ),
            boxShadow: [
              BoxShadow(
                color:
                AppColors
                    .navy
                    .withOpacity(
                  .03,
                ),
                blurRadius: 12,
                offset:
                const Offset(
                  0,
                  4,
                ),
              ),
            ],
          ),
          alignment:
          Alignment.center,
          child: Icon(
            icon,
            color:
            AppColors.navy,
            size: 17,
          ),
        ),
      ),
    );
  }
}

class _ErrorState
    extends StatelessWidget {
  const _ErrorState({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(
      BuildContext context,
      ) {
    return ListView(
      physics:
      const AlwaysScrollableScrollPhysics(),
      padding:
      const EdgeInsets.all(
        22,
      ),
      children: [
        const SizedBox(
          height: 90,
        ),
        Container(
          padding:
          const EdgeInsets
              .all(
            22,
          ),
          decoration:
          BoxDecoration(
            color:
            Colors.white,
            borderRadius:
            BorderRadius
                .circular(
              22,
            ),
            border:
            Border.all(
              color:
              AppColors
                  .cardBorder,
            ),
          ),
          child: Column(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration:
                BoxDecoration(
                  color:
                  AppColors
                      .redBg,
                  borderRadius:
                  BorderRadius
                      .circular(
                    18,
                  ),
                ),
                child:
                const Icon(
                  Icons
                      .error_outline_rounded,
                  color:
                  AppColors.red,
                  size: 28,
                ),
              ),
              const SizedBox(
                height: 14,
              ),
              const LocalizedText(
                'Unable to load reviews',
                textAlign:
                TextAlign.center,
                style:
                TextStyle(
                  color:
                  AppColors.navy,
                  fontSize: 14,
                  fontWeight:
                  FontWeight
                      .w900,
                ),
              ),
              const SizedBox(
                height: 7,
              ),
              Text(AppLanguage.text(
                message),
                textAlign:
                TextAlign.center,
                style:
                const TextStyle(
                  color:
                  AppColors.grey,
                  fontSize: 10.5,
                  height: 1.45,
                ),
              ),
              const SizedBox(
                height: 16,
              ),
              FilledButton.icon(
                onPressed:
                onRetry,
                style:
                FilledButton
                    .styleFrom(
                  backgroundColor:
                  AppColors.blue,
                  minimumSize:
                  const Size(
                    double.infinity,
                    48,
                  ),
                  shape:
                  RoundedRectangleBorder(
                    borderRadius:
                    BorderRadius
                        .circular(
                      15,
                    ),
                  ),
                ),
                icon:
                const Icon(
                  Icons
                      .refresh_rounded,
                  size: 18,
                ),
                label:
                const LocalizedText(
                  'Try Again',
                  style:
                  TextStyle(
                    fontWeight:
                    FontWeight
                        .w900,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ReviewsShimmer
    extends StatefulWidget {
  const _ReviewsShimmer();

  @override
  State<_ReviewsShimmer>
  createState() =>
      _ReviewsShimmerState();
}

class _ReviewsShimmerState
    extends State<_ReviewsShimmer>
    with
        SingleTickerProviderStateMixin {
  late final AnimationController
  _animationController;

  @override
  void initState() {
    super.initState();

    _animationController =
    AnimationController(
      vsync: this,
      duration:
      const Duration(
        milliseconds: 1100,
      ),
    )..repeat();
  }

  @override
  void dispose() {
    _animationController
        .dispose();

    super.dispose();
  }

  @override
  Widget build(
      BuildContext context,
      ) {
    return AnimatedBuilder(
      animation:
      _animationController,
      builder:
          (context, child) {
        Widget shimmer({
          required double height,
          double? width,
          double radius = 18,
        }) {
          final value =
              _animationController
                  .value;

          return Container(
            width: width,
            height: height,
            decoration:
            BoxDecoration(
              borderRadius:
              BorderRadius
                  .circular(
                radius,
              ),
              gradient:
              LinearGradient(
                begin: Alignment(
                  -1.8 +
                      3.6 *
                          value,
                  0,
                ),
                end: Alignment(
                  -.8 +
                      3.6 *
                          value,
                  0,
                ),
                colors:
                const [
                  Color(
                    0xFFE7EDF1,
                  ),
                  Color(
                    0xFFF8FAFB,
                  ),
                  Color(
                    0xFFE2E9ED,
                  ),
                  Color(
                    0xFFF8FAFB,
                  ),
                  Color(
                    0xFFE7EDF1,
                  ),
                ],
              ),
            ),
          );
        }

        return ListView(
          physics:
          const NeverScrollableScrollPhysics(),
          padding:
          const EdgeInsets
              .fromLTRB(
            16,
            8,
            16,
            30,
          ),
          children: [
            shimmer(
              height: 130,
              radius: 27,
            ),
            const SizedBox(
              height: 18,
            ),
            Row(
              children: [
                shimmer(
                  width: 34,
                  height: 34,
                  radius: 10,
                ),
                const SizedBox(
                  width: 10,
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment
                        .start,
                    children: [
                      shimmer(
                        width: 110,
                        height: 12,
                        radius: 7,
                      ),
                      const SizedBox(
                        height: 6,
                      ),
                      shimmer(
                        width: 190,
                        height: 8,
                        radius: 6,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(
              height: 13,
            ),
            shimmer(
              height: 155,
              radius: 20,
            ),
            const SizedBox(
              height: 10,
            ),
            shimmer(
              height: 155,
              radius: 20,
            ),
            const SizedBox(
              height: 10,
            ),
            shimmer(
              height: 155,
              radius: 20,
            ),
          ],
        );
      },
    );
  }
}