import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/network/api_client.dart';
import '../../../core/storage/user_session_storage.dart';
import '../../../core/theme/app_colors.dart';

import '../../company/screens/applications/company_application_screen.dart';
import '../../payments/services/payment_service.dart';
import '../../reviews/controllers/review_controller.dart';
import '../controllers/notification_controller.dart';
import '../models/notification_model.dart';
import '../services/notification_service.dart';

import '../../pilot/screens/applications/application_details_screen.dart';
import '../../pilot/screens/contract/pilot_contract_detail_screen.dart';
import '../../pilot/screens/contract/pilot_contracts_screen.dart';

 import '../../company/screens/contract/company_contract_detail_screen.dart';
import '../../company/screens/contract/company_contracts_screen.dart';

import '../../payments/models/payment_model.dart';
import '../../payments/screens/payment_history_screen.dart';

import '../../subscriptions/screens/subscription_center_screen.dart';

import '../../reviews/screens/reviews_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({
    super.key,
  });

  @override
  State<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState
    extends State<NotificationsScreen> {
  late final NotificationController _controller;
  late final ScrollController _scrollController;

  String _role = '';
  bool _openingRelated = false;

  @override
  void initState() {
    super.initState();

    _controller = NotificationController(
      NotificationService(
        ApiClient(),
      ),
    );

    _scrollController = ScrollController()
      ..addListener(
        _onScroll,
      );

    _controller.addListener(
      _onControllerChanged,
    );

    _loadRole();

    WidgetsBinding.instance.addPostFrameCallback(
          (_) {
        _controller.loadNotifications();
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

  // ===========================================================================
  // ROLE
  // ===========================================================================

  Future<void> _loadRole() async {
    final role =
    await UserSessionStorage.getRole();

    if (!mounted) return;

    setState(() {
      _role =
          role
              ?.trim()
              .toLowerCase() ??
              '';
    });
  }

  bool get _isCompany =>
      _role == 'company';

  bool get _isPilot =>
      _role == 'pilot';

  // ===========================================================================
  // CONTROLLER
  // ===========================================================================

  void _onControllerChanged() {
    if (!mounted) return;

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

  // ===========================================================================
  // REFRESH
  // ===========================================================================

  Future<void> _refresh() async {
    HapticFeedback.selectionClick();

    await _controller.refresh();
  }

  // ===========================================================================
  // FILTER
  // ===========================================================================

  Future<void> _setFilter(
      bool unreadOnly,
      ) async {
    if (_controller.unreadOnly ==
        unreadOnly) {
      return;
    }

    HapticFeedback.selectionClick();

    await _controller.setUnreadOnly(
      unreadOnly,
    );
  }

  // ===========================================================================
  // MARK ALL
  // ===========================================================================

  Future<void> _markAllRead() async {
    if (_controller.isMarkingAllRead ||
        _controller.unreadCount <= 0) {
      return;
    }

    HapticFeedback.mediumImpact();

    final result =
    await _controller.markAllAsRead();

    if (!mounted ||
        result == null) {
      return;
    }

    _showSnack(
      result.markedRead > 0
          ? '${result.markedRead} notification${result.markedRead == 1 ? '' : 's'} marked as read.'
          : result.message,
      success: true,
    );
  }

  // ===========================================================================
  // OPEN NOTIFICATION
  // ===========================================================================

  Future<void> _openNotification(
      AppNotificationModel notification,
      ) async {
    if (_openingRelated) {
      return;
    }

    HapticFeedback.selectionClick();

    if (notification.isUnread) {
      final success =
      await _controller.markAsRead(
        notification,
      );

      if (!mounted) {
        return;
      }

      if (!success &&
          _controller.errorMessage != null) {
        _showSnack(
          _controller.errorMessage!,
          error: true,
        );

        return;
      }
    }

    if (!mounted) return;

    await _openRelatedEntity(
      notification,
    );
  }

  // ===========================================================================
  // DEEP LINK
  // ===========================================================================

  Future<void> _openRelatedEntity(
      AppNotificationModel notification,
      ) async {
    if (_openingRelated) return;

    final relatedType =
    notification.relatedType
        .trim()
        .toLowerCase();

    final relatedId =
        notification.relatedId;

    setState(() {
      _openingRelated = true;
    });

    try {
      switch (relatedType) {
      // =====================================================================
      // CONTRACT
      // =====================================================================

        case 'contract':
          if (relatedId == null ||
              relatedId <= 0) {
            await _openContractsList();
            return;
          }

          if (_isCompany) {
            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) =>
                    CompanyContractDetailScreen(
                      contractId: relatedId,
                    ),
              ),
            );

            return;
          }

          if (_isPilot) {
            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) =>
                    PilotContractDetailScreen(
                      contractId: relatedId,
                    ),
              ),
            );

            return;
          }

          await _openContractsList();
          return;

      // =====================================================================
      // JOB APPLICATION
      // =====================================================================

        case 'job_application':
          if (_isPilot &&
              relatedId != null &&
              relatedId > 0) {
            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) =>
                    ApplicationDetailsScreen(
                      applicationId:
                      relatedId,
                    ),
              ),
            );

            return;
          }

          if (_isCompany) {
            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) =>
                const CompanyApplicationsScreen(),
              ),
            );

            return;
          }

          _showSnack(
            'Application details are available from the Applications screen.',
          );

          return;

      // =====================================================================
      // CONTRACT SUBMISSION
      //
      // Backend notification related_id here is submission ID,
      // not contract ID.
      //
      // There is no standalone:
      // GET /work-submissions/{submission}
      //
      // in the current Phase 4 API.
      //
      // So we open the contracts area instead of guessing a wrong contract.
      // =====================================================================

        case 'contract_submission':
          await _openContractsList();

          _showSnack(
            notification.isWorkSubmitted
                ? 'Open the related mission to review the latest work submission.'
                : 'Open the related mission to view the latest work review.',
          );

          return;

      // =====================================================================
      // PAYMENT
      //
      // The notification carries payment ID.
      // Current mobile UI uses Payment History rather than a standalone
      // PaymentDetailsScreen, so route to the authoritative payment list.
      // =====================================================================

        case 'payment':
          await _openPayments();
          return;

      // =====================================================================
      // SUBSCRIPTION
      // =====================================================================

        case 'user_subscription':
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) =>
              const SubscriptionCenterScreen(),
            ),
          );

          return;

      // =====================================================================
      // REVIEW
      //
      // related_id = review ID.
      // Public review endpoints are profile-based, not review-id based.
      // Open the current user's reviews safely.
      // =====================================================================

        case 'review':
          await _openMyReviews();
          return;

      // =====================================================================
      // USER / ACCOUNT STATUS
      // =====================================================================

        case 'user':
          _showSnack(
            notification.displayBody,
            success:
            notification
                .isAccountStatusChanged,
          );

          return;

        default:
          await _fallbackForType(
            notification,
          );

          return;
      }
    } catch (e) {
      if (!mounted) return;

      _showSnack(
        'Unable to open this notification right now.',
        error: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _openingRelated = false;
        });
      }
    }
  }

  // ===========================================================================
  // TYPE FALLBACK
  // ===========================================================================

  Future<void> _fallbackForType(
      AppNotificationModel notification,
      ) async {
    if (notification.isContractCreated ||
        notification.isContractStatusChanged ||
        notification.isWorkSubmitted ||
        notification.isWorkReviewed) {
      await _openContractsList();
      return;
    }

    if (notification.isPaymentStatusChanged) {
      await _openPayments();
      return;
    }

    if (notification.isSubscriptionStatusChanged) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) =>
          const SubscriptionCenterScreen(),
        ),
      );

      return;
    }

    if (notification.isReviewReceived) {
      await _openMyReviews();
      return;
    }

    if (notification.isApplicationReceived) {
      if (_isCompany) {
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) =>
            const CompanyApplicationsScreen(),
          ),
        );
      }

      return;
    }

    if (notification.isApplicationStatusChanged) {
      if (_isCompany) {
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) =>
            const CompanyApplicationsScreen(),
          ),
        );
      }

      return;
    }

    _showSnack(
      notification.displayBody,
    );
  }

  // ===========================================================================
  // CONTRACT LIST
  // ===========================================================================

  Future<void> _openContractsList() async {
    if (_isCompany) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) =>
          const CompanyContractsScreen(),
        ),
      );

      return;
    }

    if (_isPilot) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) =>
          const PilotContractsScreen(),
        ),
      );

      return;
    }

    _showSnack(
      'Contract details are not available for this account.',
    );
  }

  // ===========================================================================
  // PAYMENTS
  // ===========================================================================

  Future<void> _openPayments() async {
    if (!_isCompany &&
        !_isPilot) {
      _showSnack(
        'Payment history is not available for this account.',
      );

      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            PaymentHistoryScreen(
              audience: _isCompany
                  ? PaymentAudience.company
                  : PaymentAudience.pilot,
            ),
      ),
    );
  }

  // ===========================================================================
  // MY REVIEWS
  // ===========================================================================

  Future<void> _openMyReviews() async {
    final profile =
    await UserSessionStorage.getProfile();

    if (!mounted) return;

    final rawId =
    profile?['id'];

    final profileId =
    rawId is int
        ? rawId
        : int.tryParse(
      rawId?.toString() ?? '',
    );

    if (profileId == null ||
        profileId <= 0) {
      _showSnack(
        'Refresh your profile to view this review.',
      );

      return;
    }

    String targetName = '';

    if (_isCompany) {
      targetName =
          profile?['company_name']
              ?.toString()
              .trim() ??
              '';
    } else {
      targetName =
          profile?['name']
              ?.toString()
              .trim() ??
              '';
    }

    if (targetName.isEmpty) {
      targetName =
      _isCompany
          ? 'Company'
          : 'Pilot';
    }

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            ReviewsScreen(
              profileId:
              profileId,
              targetType:
              _isCompany
                  ? ReviewTargetType.company
                  : ReviewTargetType.pilot,
              targetName:
              targetName,
            ),
      ),
    );
  }

  // ===========================================================================
  // SNACK
  // ===========================================================================

  void _showSnack(
      String message, {
        bool error = false,
        bool success = false,
      }) {
    if (!mounted ||
        message.trim().isEmpty) {
      return;
    }

    final color =
    error
        ? const Color(
      0xFFE45858,
    )
        : success
        ? const Color(
      0xFF11A875,
    )
        : const Color(
      0xFF0C3048,
    );

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: const TextStyle(
              color:
              Colors.white,
              fontWeight:
              FontWeight.w700,
            ),
          ),
          backgroundColor:
          color,
          behavior:
          SnackBarBehavior.floating,
          margin:
          const EdgeInsets.all(
            16,
          ),
          shape:
          RoundedRectangleBorder(
            borderRadius:
            BorderRadius.circular(
              16,
            ),
          ),
        ),
      );
  }

  // ===========================================================================
  // BUILD
  // ===========================================================================

  @override
  Widget build(
      BuildContext context,
      ) {
    return Scaffold(
      backgroundColor:
      AppColors.bg,
      body: Stack(
        children: [
          const _NotificationBackdrop(),

          SafeArea(
            child: Column(
              children: [
                _header(),
                _filters(),

                Expanded(
                  child: _body(),
                ),
              ],
            ),
          ),

          if (_openingRelated)
            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  color:
                  Colors.black
                      .withOpacity(
                    .035,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ===========================================================================
  // HEADER
  // ===========================================================================

  Widget _header() {
    return Padding(
      padding:
      const EdgeInsets.fromLTRB(
        18,
        14,
        18,
        12,
      ),
      child: Row(
        children: [
          Container(
            width: 47,
            height: 47,
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
                    0xFF071C2F,
                  ),
                  Color(
                    0xFF0C5D6A,
                  ),
                ],
              ),
              borderRadius:
              BorderRadius.circular(
                15,
              ),
              boxShadow: [
                BoxShadow(
                  color:
                  const Color(
                    0xFF087E88,
                  ).withOpacity(
                    .15,
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
            child: Stack(
              clipBehavior:
              Clip.none,
              children: [
                const Center(
                  child: Icon(
                    Icons
                        .notifications_none_rounded,
                    color:
                    Colors.white,
                    size:
                    24,
                  ),
                ),

                if (_controller
                    .unreadCount >
                    0)
                  Positioned(
                    right: -4,
                    top: -5,
                    child: Container(
                      constraints:
                      const BoxConstraints(
                        minWidth:
                        19,
                        minHeight:
                        19,
                      ),
                      padding:
                      const EdgeInsets
                          .symmetric(
                        horizontal:
                        5,
                      ),
                      alignment:
                      Alignment.center,
                      decoration:
                      BoxDecoration(
                        color:
                        const Color(
                          0xFFFFB339,
                        ),
                        borderRadius:
                        BorderRadius
                            .circular(
                          20,
                        ),
                        border:
                        Border.all(
                          color:
                          AppColors.bg,
                          width:
                          2,
                        ),
                      ),
                      child: Text(
                        _controller
                            .unreadCount >
                            99
                            ? '99+'
                            : '${_controller.unreadCount}',
                        style:
                        const TextStyle(
                          color:
                          Color(
                            0xFF533600,
                          ),
                          fontSize:
                          8.5,
                          height:
                          1,
                          fontWeight:
                          FontWeight
                              .w900,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(
            width: 12,
          ),

          const Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment
                  .start,
              children: [
                Text(
                  'Notifications',
                  style:
                  TextStyle(
                    color:
                    Color(
                      0xFF071C2F,
                    ),
                    fontSize:
                    21,
                    height:
                    1,
                    fontWeight:
                    FontWeight
                        .w900,
                    letterSpacing:
                    -.45,
                  ),
                ),
                SizedBox(
                  height: 6,
                ),
                Text(
                  'Stay updated on your activity',
                  style:
                  TextStyle(
                    color:
                    Color(
                      0xFF718092,
                    ),
                    fontSize:
                    10.5,
                    fontWeight:
                    FontWeight
                        .w600,
                  ),
                ),
              ],
            ),
          ),

          if (_controller
              .unreadCount >
              0)
            Material(
              color:
              Colors.transparent,
              child: InkWell(
                onTap:
                _controller
                    .isMarkingAllRead
                    ? null
                    : _markAllRead,
                borderRadius:
                BorderRadius.circular(
                  14,
                ),
                child: Container(
                  height:
                  39,
                  padding:
                  const EdgeInsets
                      .symmetric(
                    horizontal:
                    11,
                  ),
                  decoration:
                  BoxDecoration(
                    color:
                    Colors.white,
                    borderRadius:
                    BorderRadius
                        .circular(
                      14,
                    ),
                    border:
                    Border.all(
                      color:
                      const Color(
                        0xFFE5EBF0,
                      ),
                    ),
                  ),
                  alignment:
                  Alignment.center,
                  child:
                  _controller
                      .isMarkingAllRead
                      ? const SizedBox(
                    width:
                    16,
                    height:
                    16,
                    child:
                    CircularProgressIndicator(
                      strokeWidth:
                      2,
                      color:
                      Color(
                        0xFF0D8AA5,
                      ),
                    ),
                  )
                      : const Row(
                    mainAxisSize:
                    MainAxisSize
                        .min,
                    children: [
                      Icon(
                        Icons
                            .done_all_rounded,
                        size:
                        15,
                        color:
                        Color(
                          0xFF0D8AA5,
                        ),
                      ),
                      SizedBox(
                        width:
                        5,
                      ),
                      Text(
                        'Read all',
                        style:
                        TextStyle(
                          color:
                          Color(
                            0xFF0C3048,
                          ),
                          fontSize:
                          9.5,
                          fontWeight:
                          FontWeight
                              .w800,
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

  // ===========================================================================
  // FILTERS
  // ===========================================================================

  Widget _filters() {
    return Padding(
      padding:
      const EdgeInsets.fromLTRB(
        18,
        0,
        18,
        12,
      ),
      child: Container(
        height:
        46,
        padding:
        const EdgeInsets.all(
          4,
        ),
        decoration:
        BoxDecoration(
          color:
          const Color(
            0xFFEAF0F3,
          ),
          borderRadius:
          BorderRadius.circular(
            15,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: _filterButton(
                label:
                'All',
                selected:
                !_controller
                    .unreadOnly,
                onTap: () {
                  _setFilter(
                    false,
                  );
                },
              ),
            ),

            Expanded(
              child: _filterButton(
                label:
                _controller
                    .unreadCount >
                    0
                    ? 'Unread  ${_controller.unreadCount}'
                    : 'Unread',
                selected:
                _controller
                    .unreadOnly,
                onTap: () {
                  _setFilter(
                    true,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterButton({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Material(
      color:
      Colors.transparent,
      child: InkWell(
        onTap:
        _controller.isLoading
            ? null
            : onTap,
        borderRadius:
        BorderRadius.circular(
          12,
        ),
        child:
        AnimatedContainer(
          duration:
          const Duration(
            milliseconds:
            220,
          ),
          curve:
          Curves.easeOutCubic,
          decoration:
          BoxDecoration(
            color:
            selected
                ? Colors.white
                : Colors
                .transparent,
            borderRadius:
            BorderRadius.circular(
              12,
            ),
            boxShadow:
            selected
                ? [
              BoxShadow(
                color:
                const Color(
                  0xFF071C2F,
                ).withOpacity(
                  .06,
                ),
                blurRadius:
                10,
                offset:
                const Offset(
                  0,
                  3,
                ),
              ),
            ]
                : const [],
          ),
          alignment:
          Alignment.center,
          child: Text(
            label,
            style:
            TextStyle(
              color:
              selected
                  ? const Color(
                0xFF0C3048,
              )
                  : const Color(
                0xFF758392,
              ),
              fontSize:
              10.5,
              fontWeight:
              selected
                  ? FontWeight
                  .w900
                  : FontWeight
                  .w700,
            ),
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // BODY
  // ===========================================================================

  Widget _body() {
    if (_controller.isLoading &&
        _controller.data ==
            null) {
      return const _NotificationLoading();
    }

    if (_controller.errorMessage !=
        null &&
        _controller.data ==
            null) {
      return _NotificationError(
        message:
        _controller
            .errorMessage!,
        onRetry: () {
          _controller
              .loadNotifications();
        },
      );
    }

    return RefreshIndicator(
      color:
      const Color(
        0xFF0D8AA5,
      ),
      onRefresh:
      _refresh,
      child: ListView(
        controller:
        _scrollController,
        physics:
        const AlwaysScrollableScrollPhysics(
          parent:
          BouncingScrollPhysics(),
        ),
        padding:
        const EdgeInsets.fromLTRB(
          16,
          3,
          16,
          34,
        ),
        children: [
          if (_controller
              .notifications
              .isEmpty)
            _emptyState()
          else ...[
            _summaryStrip(),

            const SizedBox(
              height:
              12,
            ),

            ..._controller
                .notifications
                .map(
                  (
                  notification,
                  ) =>
                  Padding(
                    padding:
                    const EdgeInsets
                        .only(
                      bottom:
                      9,
                    ),
                    child:
                    _notificationCard(
                      notification,
                    ),
                  ),
            ),
          ],

          if (_controller
              .isLoadingMore)
            const Padding(
              padding:
              EdgeInsets
                  .symmetric(
                vertical:
                18,
              ),
              child:
              Center(
                child:
                SizedBox(
                  width:
                  23,
                  height:
                  23,
                  child:
                  CircularProgressIndicator(
                    strokeWidth:
                    2.2,
                    color:
                    Color(
                      0xFF0D8AA5,
                    ),
                  ),
                ),
              ),
            ),

          if (_controller
              .errorMessage !=
              null &&
              _controller
                  .notifications
                  .isNotEmpty)
            _paginationError(),
        ],
      ),
    );
  }

  // ===========================================================================
  // SUMMARY
  // ===========================================================================

  Widget _summaryStrip() {
    return Container(
      padding:
      const EdgeInsets.fromLTRB(
        14,
        11,
        14,
        11,
      ),
      decoration:
      BoxDecoration(
        color:
        Colors.white,
        borderRadius:
        BorderRadius.circular(
          16,
        ),
        border:
        Border.all(
          color:
          const Color(
            0xFFE6EDF2,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width:
            31,
            height:
            31,
            decoration:
            BoxDecoration(
              color:
              const Color(
                0xFFEAFBFB,
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
                  .auto_awesome_rounded,
              color:
              Color(
                0xFF0D8AA5,
              ),
              size:
              16,
            ),
          ),

          const SizedBox(
            width:
            9,
          ),

          Expanded(
            child: Text(
              _controller
                  .unreadOnly
                  ? 'Showing unread notifications'
                  : 'Your latest activity updates',
              style:
              const TextStyle(
                color:
                Color(
                  0xFF102638,
                ),
                fontSize:
                10.5,
                fontWeight:
                FontWeight
                    .w800,
              ),
            ),
          ),

          Text(
            '${_controller.pagination.total}',
            style:
            const TextStyle(
              color:
              Color(
                0xFF7C8997,
              ),
              fontSize:
              10,
              fontWeight:
              FontWeight
                  .w800,
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // CARD
  // ===========================================================================

  Widget _notificationCard(
      AppNotificationModel notification,
      ) {
    final visual =
    _visualFor(
      notification,
    );

    final marking =
    _controller
        .isMarkingRead(
      notification.id,
    );

    return Material(
      color:
      Colors.transparent,
      child: InkWell(
        onTap:
        marking ||
            _openingRelated
            ? null
            : () {
          _openNotification(
            notification,
          );
        },
        borderRadius:
        BorderRadius.circular(
          20,
        ),
        child:
        AnimatedContainer(
          duration:
          const Duration(
            milliseconds:
            220,
          ),
          padding:
          const EdgeInsets.all(
            14,
          ),
          decoration:
          BoxDecoration(
            color:
            notification.isUnread
                ? Colors.white
                : const Color(
              0xFFFBFCFD,
            ),
            borderRadius:
            BorderRadius.circular(
              20,
            ),
            border:
            Border.all(
              color:
              notification
                  .isUnread
                  ? visual.color
                  .withOpacity(
                .18,
              )
                  : const Color(
                0xFFE7EDF2,
              ),
            ),
            boxShadow:
            notification
                .isUnread
                ? [
              BoxShadow(
                color:
                const Color(
                  0xFF071C2F,
                ).withOpacity(
                  .035,
                ),
                blurRadius:
                16,
                offset:
                const Offset(
                  0,
                  6,
                ),
              ),
            ]
                : const [],
          ),
          child: Row(
            crossAxisAlignment:
            CrossAxisAlignment
                .start,
            children: [
              Stack(
                clipBehavior:
                Clip.none,
                children: [
                  Container(
                    width:
                    46,
                    height:
                    46,
                    decoration:
                    BoxDecoration(
                      color:
                      visual.color
                          .withOpacity(
                        .10,
                      ),
                      borderRadius:
                      BorderRadius
                          .circular(
                        15,
                      ),
                    ),
                    child:
                    Icon(
                      visual.icon,
                      color:
                      visual.color,
                      size:
                      22,
                    ),
                  ),

                  if (notification
                      .isUnread)
                    Positioned(
                      right:
                      -1,
                      top:
                      -1,
                      child:
                      Container(
                        width:
                        10,
                        height:
                        10,
                        decoration:
                        BoxDecoration(
                          color:
                          visual.color,
                          shape:
                          BoxShape
                              .circle,
                          border:
                          Border.all(
                            color:
                            Colors.white,
                            width:
                            2,
                          ),
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(
                width:
                12,
              ),

              Expanded(
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
                          child:
                          Text(
                            notification
                                .displayTitle,
                            maxLines:
                            2,
                            overflow:
                            TextOverflow
                                .ellipsis,
                            style:
                            TextStyle(
                              color:
                              const Color(
                                0xFF102638,
                              ),
                              fontSize:
                              12.3,
                              height:
                              1.25,
                              fontWeight:
                              notification
                                  .isUnread
                                  ? FontWeight
                                  .w900
                                  : FontWeight
                                  .w800,
                            ),
                          ),
                        ),

                        if (marking) ...[
                          const SizedBox(
                            width:
                            8,
                          ),
                          const SizedBox(
                            width:
                            15,
                            height:
                            15,
                            child:
                            CircularProgressIndicator(
                              strokeWidth:
                              1.8,
                              color:
                              Color(
                                0xFF0D8AA5,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),

                    const SizedBox(
                      height:
                      5,
                    ),

                    Text(
                      notification
                          .displayBody,
                      maxLines:
                      3,
                      overflow:
                      TextOverflow
                          .ellipsis,
                      style:
                      const TextStyle(
                        color:
                        Color(
                          0xFF69798A,
                        ),
                        fontSize:
                        10.3,
                        height:
                        1.48,
                        fontWeight:
                        FontWeight
                            .w500,
                      ),
                    ),

                    const SizedBox(
                      height:
                      9,
                    ),

                    Row(
                      children: [
                        Container(
                          padding:
                          const EdgeInsets
                              .symmetric(
                            horizontal:
                            7,
                            vertical:
                            4,
                          ),
                          decoration:
                          BoxDecoration(
                            color:
                            visual
                                .color
                                .withOpacity(
                              .075,
                            ),
                            borderRadius:
                            BorderRadius
                                .circular(
                              20,
                            ),
                          ),
                          child:
                          Text(
                            visual.label,
                            style:
                            TextStyle(
                              color:
                              visual.color,
                              fontSize:
                              8.5,
                              fontWeight:
                              FontWeight
                                  .w800,
                            ),
                          ),
                        ),

                        const SizedBox(
                          width:
                          7,
                        ),

                        Expanded(
                          child:
                          Text(
                            notification
                                .createdLabel,
                            maxLines:
                            1,
                            overflow:
                            TextOverflow
                                .ellipsis,
                            style:
                            const TextStyle(
                              color:
                              Color(
                                0xFF99A5B1,
                              ),
                              fontSize:
                              8.8,
                              fontWeight:
                              FontWeight
                                  .w600,
                            ),
                          ),
                        ),

                        if (notification
                            .hasRelatedEntity ||
                            notification
                                .isPaymentStatusChanged ||
                            notification
                                .isSubscriptionStatusChanged ||
                            notification
                                .isReviewReceived)
                          const Icon(
                            Icons
                                .arrow_forward_ios_rounded,
                            size:
                            11,
                            color:
                            Color(
                              0xFFB1BBC5,
                            ),
                          ),
                      ],
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

  // ===========================================================================
  // VISUAL
  // ===========================================================================

  _NotificationVisual _visualFor(
      AppNotificationModel item,
      ) {
    switch (item.type) {
      case 'application_received':
        return const _NotificationVisual(
          icon:
          Icons.person_add_alt_1_rounded,
          color:
          Color(
            0xFF4E74E8,
          ),
          label:
          'Application',
        );

      case 'application_status_changed':
        return const _NotificationVisual(
          icon:
          Icons.assignment_turned_in_rounded,
          color:
          Color(
            0xFF846BE2,
          ),
          label:
          'Application',
        );

      case 'contract_created':
        return const _NotificationVisual(
          icon:
          Icons.description_rounded,
          color:
          Color(
            0xFF159FA7,
          ),
          label:
          'Contract',
        );

      case 'contract_status_changed':
        return const _NotificationVisual(
          icon:
          Icons.handshake_rounded,
          color:
          Color(
            0xFF0D8AA5,
          ),
          label:
          'Contract',
        );

      case 'work_submitted':
        return const _NotificationVisual(
          icon:
          Icons.cloud_upload_rounded,
          color:
          Color(
            0xFF2678C9,
          ),
          label:
          'Work',
        );

      case 'work_reviewed':
        return const _NotificationVisual(
          icon:
          Icons.fact_check_rounded,
          color:
          Color(
            0xFF765BC9,
          ),
          label:
          'Work',
        );

      case 'payment_status_changed':
        return const _NotificationVisual(
          icon:
          Icons.account_balance_wallet_rounded,
          color:
          Color(
            0xFF11A875,
          ),
          label:
          'Payment',
        );

      case 'subscription_status_changed':
        return const _NotificationVisual(
          icon:
          Icons.workspace_premium_rounded,
          color:
          Color(
            0xFFE59A18,
          ),
          label:
          'Subscription',
        );

      case 'review_received':
        return const _NotificationVisual(
          icon:
          Icons.star_rounded,
          color:
          Color(
            0xFFFFAE22,
          ),
          label:
          'Review',
        );

      case 'account_status_changed':
        return const _NotificationVisual(
          icon:
          Icons.verified_user_rounded,
          color:
          Color(
            0xFF3D71CB,
          ),
          label:
          'Account',
        );

      default:
        return const _NotificationVisual(
          icon:
          Icons.notifications_rounded,
          color:
          Color(
            0xFF0D8AA5,
          ),
          label:
          'Update',
        );
    }
  }

  // ===========================================================================
  // EMPTY
  // ===========================================================================

  Widget _emptyState() {
    return Padding(
      padding:
      const EdgeInsets.only(
        top:
        54,
      ),
      child: Column(
        children: [
          Container(
            width:
            88,
            height:
            88,
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
                    0xFFF0FBFB,
                  ),
                  Color(
                    0xFFE8F6F7,
                  ),
                ],
              ),
              borderRadius:
              BorderRadius.circular(
                28,
              ),
              border:
              Border.all(
                color:
                const Color(
                  0xFFD8EFF0,
                ),
              ),
            ),
            child:
            const Icon(
              Icons
                  .notifications_none_rounded,
              color:
              Color(
                0xFF0D8AA5,
              ),
              size:
              39,
            ),
          ),

          const SizedBox(
            height:
            18,
          ),

          Text(
            _controller
                .unreadOnly
                ? 'You’re all caught up'
                : 'No notifications yet',
            style:
            const TextStyle(
              color:
              Color(
                0xFF102638,
              ),
              fontSize:
              15,
              fontWeight:
              FontWeight
                  .w900,
            ),
          ),

          const SizedBox(
            height:
            7,
          ),

          Padding(
            padding:
            const EdgeInsets
                .symmetric(
              horizontal:
              36,
            ),
            child: Text(
              _controller
                  .unreadOnly
                  ? 'You don’t have any unread notifications right now.'
                  : 'Updates about applications, contracts, payments and reviews will appear here.',
              textAlign:
              TextAlign.center,
              style:
              const TextStyle(
                color:
                Color(
                  0xFF7C8997,
                ),
                fontSize:
                10.5,
                height:
                1.5,
                fontWeight:
                FontWeight
                    .w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // PAGINATION ERROR
  // ===========================================================================

  Widget _paginationError() {
    return Padding(
      padding:
      const EdgeInsets.only(
        top:
        8,
      ),
      child:
      OutlinedButton.icon(
        onPressed: () {
          _controller
              .clearError();

          _controller
              .loadMore();
        },
        style:
        OutlinedButton
            .styleFrom(
          foregroundColor:
          const Color(
            0xFF0D8AA5,
          ),
          side:
          const BorderSide(
            color:
            Color(
              0xFFD8E5E9,
            ),
          ),
          shape:
          RoundedRectangleBorder(
            borderRadius:
            BorderRadius.circular(
              14,
            ),
          ),
        ),
        icon:
        const Icon(
          Icons.refresh_rounded,
          size:
          17,
        ),
        label:
        const Text(
          'Try again',
          style:
          TextStyle(
            fontWeight:
            FontWeight
                .w800,
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// VISUAL MODEL
// =============================================================================

class _NotificationVisual {
  const _NotificationVisual({
    required this.icon,
    required this.color,
    required this.label,
  });

  final IconData icon;
  final Color color;
  final String label;
}

// =============================================================================
// BACKDROP
// =============================================================================

class _NotificationBackdrop
    extends StatelessWidget {
  const _NotificationBackdrop();

  @override
  Widget build(
      BuildContext context,
      ) {
    return Stack(
      children: [
        Positioned(
          top:
          -90,
          right:
          -80,
          child:
          Container(
            width:
            220,
            height:
            220,
            decoration:
            BoxDecoration(
              shape:
              BoxShape.circle,
              color:
              const Color(
                0xFF16C6C7,
              ).withOpacity(
                .045,
              ),
            ),
          ),
        ),

        Positioned(
          left:
          -100,
          top:
          280,
          child:
          Container(
            width:
            240,
            height:
            240,
            decoration:
            BoxDecoration(
              shape:
              BoxShape.circle,
              color:
              const Color(
                0xFF4E74E8,
              ).withOpacity(
                .025,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// LOADING
// =============================================================================

class _NotificationLoading
    extends StatelessWidget {
  const _NotificationLoading();

  @override
  Widget build(
      BuildContext context,
      ) {
    return ListView(
      physics:
      const NeverScrollableScrollPhysics(),
      padding:
      const EdgeInsets.fromLTRB(
        16,
        3,
        16,
        30,
      ),
      children: [
        const _SkeletonBox(
          height:
          53,
          radius:
          16,
        ),

        const SizedBox(
          height:
          12,
        ),

        ...List.generate(
          6,
              (index) =>
          const Padding(
            padding:
            EdgeInsets.only(
              bottom:
              9,
            ),
            child:
            _SkeletonBox(
              height:
              108,
              radius:
              20,
            ),
          ),
        ),
      ],
    );
  }
}

class _SkeletonBox
    extends StatelessWidget {
  const _SkeletonBox({
    required this.height,
    required this.radius,
  });

  final double height;
  final double radius;

  @override
  Widget build(
      BuildContext context,
      ) {
    return Container(
      height:
      height,
      decoration:
      BoxDecoration(
        color:
        const Color(
          0xFFEAF0F3,
        ),
        borderRadius:
        BorderRadius.circular(
          radius,
        ),
      ),
    );
  }
}

// =============================================================================
// ERROR
// =============================================================================

class _NotificationError
    extends StatelessWidget {
  const _NotificationError({
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
          height:
          65,
        ),

        Container(
          padding:
          const EdgeInsets.all(
            22,
          ),
          decoration:
          BoxDecoration(
            color:
            Colors.white,
            borderRadius:
            BorderRadius.circular(
              22,
            ),
            border:
            Border.all(
              color:
              const Color(
                0xFFE6EDF2,
              ),
            ),
          ),
          child: Column(
            children: [
              Container(
                width:
                62,
                height:
                62,
                decoration:
                BoxDecoration(
                  color:
                  const Color(
                    0xFFFFEEEE,
                  ),
                  borderRadius:
                  BorderRadius
                      .circular(
                    20,
                  ),
                ),
                child:
                const Icon(
                  Icons
                      .notifications_off_outlined,
                  color:
                  Color(
                    0xFFE45858,
                  ),
                  size:
                  28,
                ),
              ),

              const SizedBox(
                height:
                15,
              ),

              const Text(
                'Couldn’t load notifications',
                textAlign:
                TextAlign.center,
                style:
                TextStyle(
                  color:
                  Color(
                    0xFF102638,
                  ),
                  fontSize:
                  14,
                  fontWeight:
                  FontWeight
                      .w900,
                ),
              ),

              const SizedBox(
                height:
                7,
              ),

              Text(
                message,
                textAlign:
                TextAlign.center,
                style:
                const TextStyle(
                  color:
                  Color(
                    0xFF7A8795,
                  ),
                  fontSize:
                  10.5,
                  height:
                  1.45,
                ),
              ),

              const SizedBox(
                height:
                17,
              ),

              SizedBox(
                width:
                double.infinity,
                height:
                47,
                child:
                FilledButton.icon(
                  onPressed:
                  onRetry,
                  style:
                  FilledButton
                      .styleFrom(
                    backgroundColor:
                    const Color(
                      0xFF0D8AA5,
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
                    size:
                    18,
                  ),
                  label:
                  const Text(
                    'Try Again',
                    style:
                    TextStyle(
                      fontWeight:
                      FontWeight
                          .w900,
                    ),
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