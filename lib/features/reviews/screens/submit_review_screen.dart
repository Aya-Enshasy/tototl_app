import 'package:tototl_app/core/localization/localized_text.dart';
import 'package:flutter/material.dart';
import 'package:tototl_app/core/localization/app_language.dart';
import 'package:flutter/services.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../company/controllers/company_contract_controller.dart';
import '../../company/services/company_contract_service.dart';
import '../../pilot/controllers/pilot_contract_controller.dart';
import '../../pilot/services/pilot_contract_service.dart';

enum ReviewAuthorType {
  pilot,
  company,
}

class SubmitReviewScreen extends StatefulWidget {
  const SubmitReviewScreen({
    super.key,
    required this.contractId,
    required this.authorType,
    required this.targetName,
  });

  final int contractId;
  final ReviewAuthorType authorType;
  final String targetName;

  @override
  State<SubmitReviewScreen> createState() =>
      _SubmitReviewScreenState();
}

class _SubmitReviewScreenState
    extends State<SubmitReviewScreen> {
  final TextEditingController _commentController =
  TextEditingController();

  PilotContractController? _pilotController;
  CompanyContractController? _companyController;

  int _rating = 0;
  bool _submitted = false;

  bool get _isPilot =>
      widget.authorType ==
          ReviewAuthorType.pilot;

  bool get _isSubmitting {
    if (_isPilot) {
      return _pilotController
          ?.isSubmittingReview ??
          false;
    }

    return _companyController
        ?.isSubmittingReview ??
        false;
  }

  String? get _errorMessage {
    if (_isPilot) {
      return _pilotController
          ?.reviewErrorMessage;
    }

    return _companyController
        ?.reviewErrorMessage;
  }

  @override
  void initState() {
    super.initState();

    final apiClient = ApiClient();

    if (_isPilot) {
      _pilotController =
          PilotContractController(
            PilotContractService(
              apiClient,
            ),
          );
    } else {
      _companyController =
          CompanyContractController(
            CompanyContractService(
              apiClient,
            ),
          );
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSubmitting ||
        _submitted) {
      return;
    }

    if (_rating < 1 ||
        _rating > 5) {
      _snack(
        'Choose a rating from 1 to 5 stars.',
        error: true,
      );

      return;
    }

    final comment =
    _commentController.text.trim();

    if (comment.length > 2000) {
      _snack(
        'Comment cannot exceed 2000 characters.',
        error: true,
      );

      return;
    }

    HapticFeedback.mediumImpact();

    setState(() {});

    String? message;

    if (_isPilot) {
      message =
      await _pilotController!
          .submitReview(
        widget.contractId,
        rating: _rating,
        comment:
        comment.isEmpty
            ? null
            : comment,
      );
    } else {
      message =
      await _companyController!
          .submitReview(
        widget.contractId,
        rating: _rating,
        comment:
        comment.isEmpty
            ? null
            : comment,
      );
    }

    if (!mounted) {
      return;
    }

    if (message == null) {
      setState(() {});

      _snack(
        _errorMessage ??
            'Unable to submit your review.',
        error: true,
      );

      return;
    }

    setState(() {
      _submitted = true;
    });

    HapticFeedback.mediumImpact();

    _snack(
      message.isEmpty
          ? 'Review submitted.'
          : message,
      success: true,
    );

    await Future<void>.delayed(
      const Duration(
        milliseconds: 450,
      ),
    );

    if (!mounted) {
      return;
    }

    Navigator.of(context).pop(true);
  }

  void _selectRating(
      int value,
      ) {
    if (_isSubmitting ||
        _submitted) {
      return;
    }

    HapticFeedback.selectionClick();

    setState(() {
      _rating = value;
    });
  }

  void _snack(
      String message, {
        bool error = false,
        bool success = false,
      }) {
    if (!mounted) {
      return;
    }

    final color = error
        ? AppColors.red
        : success
        ? AppColors.green
        : AppColors.navy;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(AppLanguage.text(
            message),
            style: const TextStyle(
              color: Colors.white,
              fontWeight:
              FontWeight.w700,
            ),
          ),
          backgroundColor: color,
          behavior:
          SnackBarBehavior.floating,
          shape:
          RoundedRectangleBorder(
            borderRadius:
            BorderRadius.circular(
              14,
            ),
          ),
        ),
      );
  }

  @override
  Widget build(
      BuildContext context,
      ) {
    final target =
    widget.targetName.trim().isEmpty
        ? (_isPilot
        ? 'Company'
        : 'Pilot')
        : widget.targetName.trim();

    return PopScope(
      canPop:
      !_isSubmitting,
      child: Scaffold(
        backgroundColor:
        AppColors.bg,
        appBar: AppBar(
          backgroundColor:
          AppColors.bg,
          surfaceTintColor:
          Colors.transparent,
          elevation: 0,
          leading:
          IconButton(
            onPressed:
            _isSubmitting
                ? null
                : () =>
                Navigator.of(
                  context,
                ).pop(),
            icon: const Icon(
              Icons
                  .arrow_back_ios_new_rounded,
              color:
              AppColors.navy,
              size: 20,
            ),
          ),
          title: const LocalizedText(
            'Leave a Review',
            style: TextStyle(
              color: AppColors.navy,
              fontSize: 18,
              fontWeight:
              FontWeight.w900,
            ),
          ),
        ),
        body:
        SafeArea(
          top: false,
          child:
          SingleChildScrollView(
            physics:
            const BouncingScrollPhysics(),
            padding:
            const EdgeInsets
                .fromLTRB(
              18,
              10,
              18,
              30,
            ),
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment
                  .stretch,
              children: [
                _header(
                  target,
                ),
                const SizedBox(
                  height: 18,
                ),
                _ratingCard(),
                const SizedBox(
                  height: 14,
                ),
                _commentCard(),
                const SizedBox(
                  height: 18,
                ),
                _submitButton(),
                const SizedBox(
                  height: 12,
                ),
                const LocalizedText(
                  'A review can only be submitted once for this contract.',
                  textAlign:
                  TextAlign.center,
                  style: TextStyle(
                    color:
                    AppColors.grey,
                    fontSize: 11,
                    height: 1.4,
                    fontWeight:
                    FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _header(
      String target,
      ) {
    return Container(
      padding:
      const EdgeInsets.all(
        20,
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
              0xFF071B2F,
            ),
            Color(
              0xFF07485C,
            ),
            Color(
              0xFF078A91,
            ),
          ],
        ),
        borderRadius:
        BorderRadius.circular(
          26,
        ),
        boxShadow: [
          BoxShadow(
            color:
            const Color(
              0xFF078A91,
            ).withOpacity(
              .16,
            ),
            blurRadius: 28,
            offset:
            const Offset(
              0,
              12,
            ),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration:
            BoxDecoration(
              color:
              Colors.white
                  .withOpacity(
                .12,
              ),
              shape:
              BoxShape.circle,
              border:
              Border.all(
                color: Colors
                    .white
                    .withOpacity(
                  .18,
                ),
              ),
            ),
            child:
            const Icon(
              Icons
                  .star_rounded,
              color:
              Color(
                0xFFFFD76A,
              ),
              size: 34,
            ),
          ),
          const SizedBox(
            height: 13,
          ),
          Text(AppLanguage.text(
            'How was your experience?'),
            textAlign:
            TextAlign.center,
            style:
            const TextStyle(
              color:
              Colors.white,
              fontSize: 20,
              fontWeight:
              FontWeight.w900,
              letterSpacing:
              -.4,
            ),
          ),
          const SizedBox(
            height: 7,
          ),
          Text(
            'Rate $target based on your completed contract.',
            textAlign:
            TextAlign.center,
            style:
            TextStyle(
              color:
              Colors.white
                  .withOpacity(
                .76,
              ),
              fontSize: 12,
              height: 1.45,
              fontWeight:
              FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _ratingCard() {
    return Container(
      padding:
      const EdgeInsets
          .fromLTRB(
        18,
        18,
        18,
        20,
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
          const LocalizedText(
            'Your rating',
            style: TextStyle(
              color:
              AppColors.navy,
              fontSize: 14,
              fontWeight:
              FontWeight.w900,
            ),
          ),
          const SizedBox(
            height: 5,
          ),
          Text(
            _ratingText,
            style:
            const TextStyle(
              color:
              AppColors.grey,
              fontSize: 11,
              fontWeight:
              FontWeight.w600,
            ),
          ),
          const SizedBox(
            height: 14,
          ),
          Row(
            mainAxisAlignment:
            MainAxisAlignment
                .center,
            children:
            List.generate(
              5,
                  (index) {
                final value =
                    index + 1;

                final selected =
                    value <=
                        _rating;

                return IconButton(
                  onPressed:
                  _isSubmitting
                      ? null
                      : () =>
                      _selectRating(
                        value,
                      ),
                  splashRadius:
                  24,
                  iconSize: 40,
                  padding:
                  const EdgeInsets
                      .symmetric(
                    horizontal: 3,
                  ),
                  icon:
                  Icon(
                    selected
                        ? Icons
                        .star_rounded
                        : Icons
                        .star_border_rounded,
                    color: selected
                        ? const Color(
                      0xFFFFB800,
                    )
                        : const Color(
                      0xFFD5DBE3,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _commentCard() {
    return Container(
      padding:
      const EdgeInsets.all(
        18,
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
        crossAxisAlignment:
        CrossAxisAlignment
            .start,
        children: [
          const LocalizedText(
            'Comment',
            style: TextStyle(
              color:
              AppColors.navy,
              fontSize: 14,
              fontWeight:
              FontWeight.w900,
            ),
          ),
          const SizedBox(
            height: 5,
          ),
          const LocalizedText(
            'Optional · Maximum 2000 characters',
            style: TextStyle(
              color:
              AppColors.grey,
              fontSize: 10.5,
              fontWeight:
              FontWeight.w600,
            ),
          ),
          const SizedBox(
            height: 13,
          ),
          TextField(
            controller:
            _commentController,
            enabled:
            !_isSubmitting &&
                !_submitted,
            minLines: 5,
            maxLines: 8,
            maxLength: 2000,
            textCapitalization:
            TextCapitalization
                .sentences,
            decoration:
            InputDecoration(
              hintText:
              AppLanguage.text('Share your experience...'),
              hintStyle:
              const TextStyle(
                color:
                Color(
                  0xFF9DA7B4,
                ),
                fontSize: 12,
              ),
              filled: true,
              fillColor:
              AppColors.bg,
              contentPadding:
              const EdgeInsets
                  .all(
                15,
              ),
              border:
              OutlineInputBorder(
                borderRadius:
                BorderRadius
                    .circular(
                  16,
                ),
                borderSide:
                const BorderSide(
                  color: AppColors
                      .cardBorder,
                ),
              ),
              enabledBorder:
              OutlineInputBorder(
                borderRadius:
                BorderRadius
                    .circular(
                  16,
                ),
                borderSide:
                const BorderSide(
                  color: AppColors
                      .cardBorder,
                ),
              ),
              focusedBorder:
              OutlineInputBorder(
                borderRadius:
                BorderRadius
                    .circular(
                  16,
                ),
                borderSide:
                const BorderSide(
                  color:
                  AppColors.blue,
                  width: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _submitButton() {
    return SizedBox(
      height: 54,
      child:
      FilledButton(
        onPressed:
        _isSubmitting ||
            _submitted
            ? null
            : _submit,
        style:
        FilledButton.styleFrom(
          backgroundColor:
          AppColors.blue,
          disabledBackgroundColor:
          const Color(
            0xFFCBD5E1,
          ),
          shape:
          RoundedRectangleBorder(
            borderRadius:
            BorderRadius.circular(
              17,
            ),
          ),
        ),
        child:
        _isSubmitting
            ? const SizedBox(
          width: 22,
          height: 22,
          child:
          CircularProgressIndicator(
            strokeWidth:
            2.4,
            color:
            Colors.white,
          ),
        )
            : _submitted
            ?  Row(
          mainAxisAlignment:
          MainAxisAlignment
              .center,
          children: [
            Icon(
              Icons
                  .check_circle_rounded,
              size: 20,
            ),
            SizedBox(
              width: 8,
            ),
            Text(AppLanguage.text(
              'Review Submitted'),
              style:
              TextStyle(
                fontSize:
                13,
                fontWeight:
                FontWeight
                    .w900,
              ),
            ),
          ],
        )
            :  Row(
          mainAxisAlignment:
          MainAxisAlignment
              .center,
          children: [
            Icon(
              Icons
                  .star_rounded,
              size: 21,
            ),
            SizedBox(
              width: 8,
            ),
            Text(AppLanguage.text(
              'Submit Review'),
              style:
              TextStyle(
                fontSize:
                13,
                fontWeight:
                FontWeight
                    .w900,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String get _ratingText {
    switch (_rating) {
      case 1:
        return 'Poor';

      case 2:
        return 'Fair';

      case 3:
        return 'Good';

      case 4:
        return 'Very good';

      case 5:
        return 'Excellent';

      default:
        return 'Tap a star to rate';
    }
  }
}