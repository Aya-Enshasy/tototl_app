import 'package:flutter/material.dart';

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
  State<PaymentHistoryScreen> createState() => _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends State<PaymentHistoryScreen> {
  late final PaymentController _controller;
  String _filter = 'all';
  bool _loading = true;

  static const _filters = <String>[
    'all',
    'funded',
    'release_pending',
    'released',
    'refunded',
  ];

  @override
  void initState() {
    super.initState();
    _controller = PaymentController(PaymentService(ApiClient()));
    _load();
  }

  Future<void> _load() async {
    if (mounted) setState(() => _loading = true);
    await _controller.loadPayments(
      audience: widget.audience,
      status: _filter == 'all' ? null : _filter,
    );
    if (mounted) setState(() => _loading = false);
  }

  List<PaymentModel> get _visible {
    final contractId = widget.contractId;
    if (contractId == null) return _controller.payments;
    return _controller.payments.where((p) => p.contractId == contractId).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        foregroundColor: AppColors.navy,
        title: Text(
          widget.contractId == null ? 'Payment History' : 'Contract Payments',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
        ),
      ),
      body: RefreshIndicator(
        color: AppColors.blue,
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 30),
          children: [
            _header(),
            const SizedBox(height: 14),
            _filterBar(),
            const SizedBox(height: 14),
            if (_loading && _controller.payments.isEmpty)
              ...List.generate(3, (_) => const _PaymentShimmer())
            else if (_controller.errorMessage != null && _controller.payments.isEmpty)
              _errorCard()
            else if (_visible.isEmpty)
              _emptyCard()
            else
              ..._visible.map(_paymentCard),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF071D39), Color(0xFF0A4055), Color(0xFF087E91)],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Row(
        children: [
          Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 28),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Payment lifecycle',
                  style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w900),
                ),
                SizedBox(height: 4),
                Text(
                  'Funding, release eligibility and final release are controlled by the backend.',
                  style: TextStyle(color: Colors.white70, fontSize: 10.7, height: 1.4),
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
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _filters.map((value) {
          final selected = _filter == value;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              selected: selected,
              showCheckmark: false,
              label: Text(_pretty(value)),
              onSelected: (_) {
                if (_filter == value) return;
                setState(() => _filter = value);
                _load();
              },
              selectedColor: AppColors.blueBg,
              backgroundColor: Colors.white,
              side: BorderSide(color: selected ? AppColors.blue : AppColors.cardBorder),
              labelStyle: TextStyle(
                color: selected ? AppColors.blue : AppColors.grey,
                fontSize: 10.3,
                fontWeight: FontWeight.w800,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _paymentCard(PaymentModel payment) {
    final visual = _paymentVisual(payment);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
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
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: visual.$2, borderRadius: BorderRadius.circular(12)),
                child: Icon(visual.$3, color: visual.$1, size: 19),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(payment.amountLabel,
                        style: const TextStyle(color: AppColors.navy, fontSize: 13, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 2),
                    Text('Contract #${payment.contractId}',
                        style: const TextStyle(color: AppColors.grey, fontSize: 9.8, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(color: visual.$2, borderRadius: BorderRadius.circular(20)),
                child: Text(payment.statusLabel,
                    style: TextStyle(color: visual.$1, fontSize: 9.2, fontWeight: FontWeight.w900)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(payment.releaseSummary,
              style: const TextStyle(color: AppColors.text, fontSize: 10.8, fontWeight: FontWeight.w700)),
          if (payment.fundedAt != null) _line('Funded', _dateTime(payment.fundedAt)),
          if (payment.eligibleReleaseAt != null)
            _line('Eligible release', _dateTime(payment.eligibleReleaseAt)),
          if (payment.releasedAt != null) _line('Released', _dateTime(payment.releasedAt)),
          if (payment.provider.isNotEmpty) _line('Provider', payment.provider),
          if (payment.transactionReference.isNotEmpty)
            _line('Reference', payment.transactionReference),
          if (payment.failureReason.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 9),
              child: Text(
                payment.failureReason,
                style: const TextStyle(color: AppColors.red, fontSize: 10.2, height: 1.4),
              ),
            ),
        ],
      ),
    );
  }

  Widget _line(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(top: 7),
      child: Row(
        children: [
          SizedBox(
            width: 94,
            child: Text(label, style: const TextStyle(color: AppColors.grey, fontSize: 9.7)),
          ),
          Expanded(
            child: Text(value,
                textAlign: TextAlign.end,
                style: const TextStyle(color: AppColors.navy, fontSize: 10, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  Widget _errorCard() => _messageCard(
        icon: Icons.cloud_off_outlined,
        title: 'Unable to load payments',
        message: _controller.errorMessage ?? 'Please try again.',
        action: 'Retry',
        onTap: _load,
      );

  Widget _emptyCard() => _messageCard(
        icon: Icons.receipt_long_outlined,
        title: 'No payments found',
        message: widget.contractId == null
            ? 'Payment records will appear here when contracts are funded.'
            : 'No payment record was returned for this contract yet.',
      );

  Widget _messageCard({
    required IconData icon,
    required String title,
    required String message,
    String? action,
    VoidCallback? onTap,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.grey, size: 30),
          const SizedBox(height: 10),
          Text(title,
              style: const TextStyle(color: AppColors.navy, fontSize: 12, fontWeight: FontWeight.w900)),
          const SizedBox(height: 5),
          Text(message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.grey, fontSize: 10.5, height: 1.45)),
          if (action != null && onTap != null) ...[
            const SizedBox(height: 12),
            OutlinedButton(onPressed: onTap, child: Text(action)),
          ],
        ],
      ),
    );
  }
}

class _PaymentShimmer extends StatelessWidget {
  const _PaymentShimmer();
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 138,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF3F6),
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }
}

(Color, Color, IconData) _paymentVisual(PaymentModel payment) {
  if (payment.isReleased) {
    return (AppColors.green, AppColors.greenBg, Icons.check_circle_outline_rounded);
  }
  if (payment.isReleasePending) {
    return (AppColors.orange, AppColors.orangeBg, Icons.schedule_send_outlined);
  }
  if (payment.isFailed || payment.isCancelled) {
    return (AppColors.red, AppColors.redBg, Icons.error_outline_rounded);
  }
  if (payment.isRefunded || payment.isPartiallyRefunded) {
    return (AppColors.orange, AppColors.orangeBg, Icons.undo_rounded);
  }
  return (AppColors.blue, AppColors.blueBg, Icons.account_balance_wallet_outlined);
}

String _pretty(String value) {
  if (value == 'all') return 'All';
  return value
      .split('_')
      .where((part) => part.isNotEmpty)
      .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
      .join(' ');
}

String _dateTime(DateTime? value) {
  if (value == null) return '—';
  final local = value.toLocal();
  final m = local.month.toString().padLeft(2, '0');
  final d = local.day.toString().padLeft(2, '0');
  final h = local.hour.toString().padLeft(2, '0');
  final min = local.minute.toString().padLeft(2, '0');
  return '${local.year}-$m-$d · $h:$min';
}
