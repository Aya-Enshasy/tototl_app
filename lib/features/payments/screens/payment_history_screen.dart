import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../controllers/payment_controller.dart';
import '../models/payment_model.dart';
import '../services/payment_service.dart';

class PaymentHistoryScreen extends StatefulWidget {
  const PaymentHistoryScreen({
    super.key,
    required this.audience,
    this.contractId,
  });

  final PaymentAudience audience;
  final int? contractId;

  @override
  State<PaymentHistoryScreen> createState() =>
      _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState
    extends State<PaymentHistoryScreen> {
  late final PaymentController _controller;

  String _filter = 'all';
  bool _loading = true;

  static const _filters = <String>[
    'all',
    'pending',
    'funded',
    'held',
    'release_pending',
    'released',
    'failed',
    'refunded',
    'partially_refunded',
    'cancelled',
  ];

  bool get _isCompany =>
      widget.audience == PaymentAudience.company;

  bool get _contractOnly =>
      widget.contractId != null;

  @override
  void initState() {
    super.initState();

    _controller = PaymentController(
      PaymentService(ApiClient()),
    );

    _load();
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() => _loading = true);
    }

    await _controller.loadPayments(
      audience: widget.audience,
      status:
      _filter == 'all' ? null : _filter,
    );

    if (!mounted) return;

    setState(() => _loading = false);
  }

  List<PaymentModel> get _visible {
    final contractId =
        widget.contractId;

    if (contractId == null) {
      return _controller.payments;
    }

    return _controller.payments
        .where(
          (payment) =>
      payment.contractId ==
          contractId,
    )
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final payments = _visible;

    return Scaffold(
      backgroundColor:
      _PaymentPalette.background,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor:
        _PaymentPalette.background,
        surfaceTintColor: Colors.transparent,
        foregroundColor:
        _PaymentPalette.navy,
        centerTitle: true,
        title: Text(
          _contractOnly
              ? 'Mission Payment'
              : 'Payments',
          style: const TextStyle(
            color: _PaymentPalette.navy,
            fontSize: 15.5,
            fontWeight: FontWeight.w800,
            letterSpacing: -.2,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed:
            _loading ? null : _load,
            icon: _loading
                ? const SizedBox(
              width: 17,
              height: 17,
              child:
              CircularProgressIndicator(
                strokeWidth: 1.8,
                color:
                _PaymentPalette.teal,
              ),
            )
                : const Icon(
              Icons.refresh_rounded,
              size: 20,
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: RefreshIndicator(
        color: _PaymentPalette.teal,
        onRefresh: _load,
        child: ListView(
          physics:
          const AlwaysScrollableScrollPhysics(
            parent:
            BouncingScrollPhysics(),
          ),
          padding:
          const EdgeInsets.fromLTRB(
            18,
            6,
            18,
            34,
          ),
          children: [
            _summaryCard(),
            const SizedBox(height: 16),

            if (!_contractOnly) ...[
              const _PaymentSectionHeader(
                title: 'Payment activity',
                subtitle:
                'Filter by payment status',
              ),
              const SizedBox(height: 9),
              _filterBar(),
              const SizedBox(height: 16),
            ] else ...[
              const _PaymentSectionHeader(
                title: 'Payment record',
                subtitle:
                'Funding and release details for this mission',
              ),
              const SizedBox(height: 10),
            ],

            if (_loading &&
                _controller
                    .payments.isEmpty)
              ...List.generate(
                3,
                    (_) =>
                const _PaymentShimmer(),
              )
            else if (_controller
                .errorMessage !=
                null &&
                _controller
                    .payments.isEmpty)
              _errorCard()
            else if (payments.isEmpty)
                _emptyCard()
              else
                ...payments.map(
                  _paymentCard,
                ),
          ],
        ),
      ),
    );
  }

  Widget _summaryCard() {
    final title = _contractOnly
        ? 'Mission payment'
        : _isCompany
        ? 'Company payments'
        : 'Pilot payments';

    final subtitle = _contractOnly
        ? 'Follow this mission from funding through final release.'
        : _isCompany
        ? 'Track mission funding, release eligibility and final release.'
        : 'Track mission payments and released funds.';

    return Container(
      width: double.infinity,
      padding:
      const EdgeInsets.fromLTRB(
        14,
        13,
        14,
        13,
      ),
      decoration: BoxDecoration(
        gradient:
        const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFF2FBFB),
            Color(0xFFEAF7F8),
          ],
        ),
        borderRadius:
        BorderRadius.circular(18),
        border: Border.all(
          color:
          _PaymentPalette.border,
        ),
      ),
      child: Row(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color:
              _PaymentPalette.tealSoft,
              borderRadius:
              BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons
                  .account_balance_wallet_outlined,
              color:
              _PaymentPalette.tealDark,
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
                  title,
                  style: const TextStyle(
                    color:
                    _PaymentPalette.navy,
                    fontSize: 12.7,
                    fontWeight:
                    FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color:
                    _PaymentPalette.muted,
                    fontSize: 10,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding:
                  const EdgeInsets
                      .symmetric(
                    horizontal: 9,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white
                        .withOpacity(.78),
                    borderRadius:
                    BorderRadius.circular(
                        10),
                    border: Border.all(
                      color:
                      _PaymentPalette
                          .border,
                    ),
                  ),
                  child: const Row(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons
                            .info_outline_rounded,
                        color:
                        _PaymentPalette
                            .tealDark,
                        size: 14,
                      ),
                      SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Release timing is backend-managed after approved completion. There is no manual release action here.',
                          style: TextStyle(
                            color:
                            _PaymentPalette
                                .text,
                            fontSize: 9.3,
                            height: 1.35,
                            fontWeight:
                            FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterBar() {
    return SingleChildScrollView(
      scrollDirection:
      Axis.horizontal,
      physics:
      const BouncingScrollPhysics(),
      child: Row(
        children:
        _filters.map((value) {
          final selected =
              _filter == value;

          return Padding(
            padding:
            const EdgeInsets.only(
              right: 7,
            ),
            child: Material(
              color: selected
                  ? _PaymentPalette.teal
                  : Colors.white,
              borderRadius:
              BorderRadius.circular(
                  20),
              child: InkWell(
                onTap: _loading
                    ? null
                    : () {
                  if (_filter ==
                      value) {
                    return;
                  }

                  HapticFeedback
                      .selectionClick();

                  setState(
                        () =>
                    _filter =
                        value,
                  );

                  _load();
                },
                borderRadius:
                BorderRadius.circular(
                    20),
                child: Container(
                  height: 36,
                  padding:
                  const EdgeInsets
                      .symmetric(
                    horizontal: 13,
                  ),
                  alignment:
                  Alignment.center,
                  decoration:
                  BoxDecoration(
                    borderRadius:
                    BorderRadius
                        .circular(20),
                    border: Border.all(
                      color: selected
                          ? _PaymentPalette
                          .teal
                          : _PaymentPalette
                          .border,
                    ),
                  ),
                  child: Text(
                    _pretty(value),
                    style: TextStyle(
                      color: selected
                          ? Colors.white
                          : _PaymentPalette
                          .text,
                      fontSize: 9.8,
                      fontWeight:
                      FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(
          growable: false,
        ),
      ),
    );
  }

  Widget _paymentCard(
      PaymentModel payment,
      ) {
    final visual =
    _paymentVisual(payment);

    return Container(
      margin:
      const EdgeInsets.only(
        bottom: 10,
      ),
      padding:
      const EdgeInsets.fromLTRB(
        12,
        11,
        12,
        12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(17),
        border: Border.all(
          color:
          _PaymentPalette.border,
        ),
        boxShadow: [
          BoxShadow(
            color: _PaymentPalette.navy
                .withOpacity(.025),
            blurRadius: 16,
            offset:
            const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment:
            CrossAxisAlignment.center,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration:
                BoxDecoration(
                  color: visual.$2,
                  borderRadius:
                  BorderRadius
                      .circular(11),
                ),
                child: Icon(
                  visual.$3,
                  color: visual.$1,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
                  children: [
                    Text(
                      payment.amountLabel,
                      maxLines: 1,
                      overflow: TextOverflow
                          .ellipsis,
                      style:
                      const TextStyle(
                        color:
                        _PaymentPalette
                            .navy,
                        fontSize: 12.5,
                        fontWeight:
                        FontWeight.w800,
                      ),
                    ),
                    const SizedBox(
                        height: 2),
                    Text(
                      _contractOnly
                          ? 'Mission payment'
                          : 'Contract payment',
                      style:
                      const TextStyle(
                        color:
                        _PaymentPalette
                            .muted,
                        fontSize: 9.4,
                        fontWeight:
                        FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                const EdgeInsets
                    .symmetric(
                  horizontal: 8,
                  vertical: 5,
                ),
                decoration:
                BoxDecoration(
                  color: visual.$2,
                  borderRadius:
                  BorderRadius
                      .circular(18),
                ),
                child: Text(
                  payment.statusLabel,
                  style: TextStyle(
                    color: visual.$1,
                    fontSize: 8.9,
                    fontWeight:
                    FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          Container(
            width: double.infinity,
            padding:
            const EdgeInsets.fromLTRB(
              9,
              8,
              9,
              8,
            ),
            decoration: BoxDecoration(
              color:
              const Color(0xFFF7FAFB),
              borderRadius:
              BorderRadius.circular(
                  11),
            ),
            child: Text(
              payment.releaseSummary,
              style: const TextStyle(
                color:
                _PaymentPalette.text,
                fontSize: 9.8,
                height: 1.35,
                fontWeight:
                FontWeight.w600,
              ),
            ),
          ),

          if (payment.fundedAt !=
              null ||
              payment
                  .eligibleReleaseAt !=
                  null ||
              payment.releasedAt !=
                  null ||
              payment.provider
                  .isNotEmpty ||
              payment
                  .transactionReference
                  .isNotEmpty) ...[
            const SizedBox(height: 10),
            _detailBlock(payment),
          ],

          if (payment.failureReason
              .isNotEmpty) ...[
            const SizedBox(height: 9),
            Container(
              width: double.infinity,
              padding:
              const EdgeInsets.all(
                  9),
              decoration: BoxDecoration(
                color:
                _PaymentPalette.redSoft,
                borderRadius:
                BorderRadius.circular(
                    10),
              ),
              child: Row(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons
                        .error_outline_rounded,
                    color:
                    _PaymentPalette.red,
                    size: 15,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      payment
                          .failureReason,
                      style:
                      const TextStyle(
                        color:
                        _PaymentPalette
                            .red,
                        fontSize: 9.6,
                        height: 1.35,
                        fontWeight:
                        FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _detailBlock(
      PaymentModel payment,
      ) {
    return Container(
      width: double.infinity,
      padding:
      const EdgeInsets.fromLTRB(
        10,
        4,
        10,
        6,
      ),
      decoration: BoxDecoration(
        color:
        _PaymentPalette.surface,
        borderRadius:
        BorderRadius.circular(11),
        border: Border.all(
          color:
          _PaymentPalette.border,
        ),
      ),
      child: Column(
        children: [
          if (payment.fundedAt !=
              null)
            _line(
              'Funded',
              _dateTime(
                  payment.fundedAt),
            ),
          if (payment
              .eligibleReleaseAt !=
              null)
            _line(
              'Eligible release',
              _dateTime(
                payment
                    .eligibleReleaseAt,
              ),
            ),
          if (payment.releasedAt !=
              null)
            _line(
              'Released',
              _dateTime(
                payment.releasedAt,
              ),
            ),
          if (payment.provider
              .isNotEmpty)
            _line(
              'Provider',
              payment.provider,
            ),
          if (payment
              .transactionReference
              .isNotEmpty)
            _line(
              'Reference',
              payment
                  .transactionReference,
            ),
        ],
      ),
    );
  }

  Widget _line(
      String label,
      String value,
      ) {
    return Padding(
      padding:
      const EdgeInsets.symmetric(
        vertical: 5,
      ),
      child: Row(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 94,
            child: Text(
              label,
              style:
              const TextStyle(
                color:
                _PaymentPalette
                    .muted,
                fontSize: 9.2,
                fontWeight:
                FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              textAlign:
              TextAlign.end,
              style:
              const TextStyle(
                color:
                _PaymentPalette
                    .navy,
                fontSize: 9.5,
                fontWeight:
                FontWeight.w700,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _errorCard() {
    return _messageCard(
      icon:
      Icons.cloud_off_outlined,
      title:
      'Unable to load payments',
      message:
      _controller.errorMessage ??
          'Please try again.',
      action: 'Retry',
      onTap: _load,
    );
  }

  Widget _emptyCard() {
    return _messageCard(
      icon:
      Icons.receipt_long_outlined,
      title: 'No payments found',
      message: _contractOnly
          ? 'No payment record was returned for this mission yet.'
          : 'Payment records will appear here when contracts are funded.',
    );
  }

  Widget _messageCard({
    required IconData icon,
    required String title,
    required String message,
    String? action,
    VoidCallback? onTap,
  }) {
    return Container(
      padding:
      const EdgeInsets.fromLTRB(
        18,
        20,
        18,
        20,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(17),
        border: Border.all(
          color:
          _PaymentPalette.border,
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color:
              _PaymentPalette.tealSoft,
              borderRadius:
              BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color:
              _PaymentPalette.tealDark,
              size: 21,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            textAlign:
            TextAlign.center,
            style:
            const TextStyle(
              color:
              _PaymentPalette.navy,
              fontSize: 11.5,
              fontWeight:
              FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            message,
            textAlign:
            TextAlign.center,
            style:
            const TextStyle(
              color:
              _PaymentPalette.muted,
              fontSize: 9.8,
              height: 1.4,
            ),
          ),
          if (action != null &&
              onTap != null) ...[
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: onTap,
              style:
              OutlinedButton.styleFrom(
                foregroundColor:
                _PaymentPalette
                    .tealDark,
                side:
                const BorderSide(
                  color:
                  _PaymentPalette
                      .border,
                ),
                shape:
                RoundedRectangleBorder(
                  borderRadius:
                  BorderRadius.circular(
                      12),
                ),
              ),
              child: Text(
                action,
                style:
                const TextStyle(
                  fontSize: 10,
                  fontWeight:
                  FontWeight.w700,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PaymentSectionHeader
    extends StatelessWidget {
  const _PaymentSectionHeader({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        Container(
          width: 31,
          height: 31,
          decoration: BoxDecoration(
            color:
            _PaymentPalette.tealSoft,
            borderRadius:
            BorderRadius.circular(9),
          ),
          child: const Icon(
            Icons
                .receipt_long_outlined,
            size: 16,
            color:
            _PaymentPalette.tealDark,
          ),
        ),
        const SizedBox(width: 8),
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
                  _PaymentPalette.navy,
                  fontSize: 11.8,
                  fontWeight:
                  FontWeight.w800,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                subtitle,
                style:
                const TextStyle(
                  color:
                  _PaymentPalette.muted,
                  fontSize: 9.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PaymentShimmer
    extends StatelessWidget {
  const _PaymentShimmer();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 148,
      margin:
      const EdgeInsets.only(
        bottom: 10,
      ),
      decoration: BoxDecoration(
        color:
        const Color(0xFFEDF2F4),
        borderRadius:
        BorderRadius.circular(17),
        border: Border.all(
          color:
          _PaymentPalette.border,
        ),
      ),
      child: const _PaymentShimmerAnimator(
        child: SizedBox.expand(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color:
              Color(0xFFE9EFF1),
            ),
          ),
        ),
      ),
    );
  }
}

class _PaymentShimmerAnimator
    extends StatefulWidget {
  const _PaymentShimmerAnimator({
    required this.child,
  });

  final Widget child;

  @override
  State<_PaymentShimmerAnimator>
  createState() =>
      _PaymentShimmerAnimatorState();
}

class _PaymentShimmerAnimatorState
    extends State<_PaymentShimmerAnimator>
    with SingleTickerProviderStateMixin {
  late final AnimationController
  _controller;

  @override
  void initState() {
    super.initState();

    _controller =
    AnimationController(
      vsync: this,
      duration:
      const Duration(
        milliseconds: 900,
      ),
    )..repeat(
      reverse: true,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(
        begin: .50,
        end: .92,
      ).animate(
        CurvedAnimation(
          parent: _controller,
          curve:
          Curves.easeInOut,
        ),
      ),
      child: widget.child,
    );
  }
}

(Color, Color, IconData)
_paymentVisual(
    PaymentModel payment,
    ) {
  if (payment.isReleased) {
    return (
    _PaymentPalette.green,
    _PaymentPalette.greenSoft,
    Icons
        .check_circle_outline_rounded,
    );
  }

  if (payment.isReleasePending) {
    return (
    _PaymentPalette.orange,
    _PaymentPalette.orangeSoft,
    Icons.schedule_send_outlined,
    );
  }

  if (payment.isFailed ||
      payment.isCancelled) {
    return (
    _PaymentPalette.red,
    _PaymentPalette.redSoft,
    Icons.error_outline_rounded,
    );
  }

  if (payment.isRefunded ||
      payment.isPartiallyRefunded) {
    return (
    _PaymentPalette.orange,
    _PaymentPalette.orangeSoft,
    Icons.undo_rounded,
    );
  }

  return (
  _PaymentPalette.tealDark,
  _PaymentPalette.tealSoft,
  Icons
      .account_balance_wallet_outlined,
  );
}

String _pretty(String value) {
  if (value == 'all') {
    return 'All';
  }

  return value
      .split('_')
      .where(
        (part) =>
    part.isNotEmpty,
  )
      .map(
        (part) =>
    '${part[0].toUpperCase()}'
        '${part.substring(1)}',
  )
      .join(' ');
}

String _dateTime(
    DateTime? value,
    ) {
  if (value == null) {
    return '—';
  }

  final local =
  value.toLocal();

  final month =
  local.month
      .toString()
      .padLeft(2, '0');

  final day =
  local.day
      .toString()
      .padLeft(2, '0');

  final hour =
  local.hour
      .toString()
      .padLeft(2, '0');

  final minute =
  local.minute
      .toString()
      .padLeft(2, '0');

  return '${local.year}-$month-$day · $hour:$minute';
}

class _PaymentPalette {
  static const background =
  Color(0xFFF7FAFB);

  static const surface =
  Color(0xFFFAFCFD);

  static const navy =
  Color(0xFF0A2D46);

  static const text =
  Color(0xFF40596A);

  static const muted =
  Color(0xFF8395A1);

  static const border =
  Color(0xFFE0E9EC);

  static const teal =
  Color(0xFF12AEBB);

  static const tealDark =
  Color(0xFF0A91A6);

  static const tealSoft =
  Color(0xFFE7F8F7);

  static const green =
  Color(0xFF12A789);

  static const greenSoft =
  Color(0xFFE9F8F3);

  static const orange =
  Color(0xFFE39B36);

  static const orangeSoft =
  Color(0xFFFFF5E6);

  static const red =
  Color(0xFFE45D55);

  static const redSoft =
  Color(0xFFFFEFED);
}
