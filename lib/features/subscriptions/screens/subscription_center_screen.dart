import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:tototl_app/core/network/api_client.dart';
import 'package:tototl_app/core/theme/app_colors.dart';
import '../controllers/subscription_controller.dart';
import '../models/subscription_models.dart';
import '../services/subscription_service.dart';

class SubscriptionCenterScreen extends StatefulWidget {
  const SubscriptionCenterScreen({super.key});

  @override
  State<SubscriptionCenterScreen> createState() => _SubscriptionCenterScreenState();
}

class _SubscriptionCenterScreenState extends State<SubscriptionCenterScreen> {
  late final SubscriptionController _controller;
  bool _initialLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = SubscriptionController(SubscriptionService(ApiClient()));
    _load();
  }

  Future<void> _load() async {
    if (mounted) setState(() => _initialLoading = _controller.plans.isEmpty);
    await _controller.loadAll();
    if (!mounted) return;
    setState(() => _initialLoading = false);
  }

  Future<void> _choosePlan(SubscriptionPlanModel plan) async {
    final current = _controller.current;
    if (current?.isActive == true && current?.subscriptionPlanId == plan.id) return;

    final changing = current?.isActive == true;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Text(
          changing ? 'Change subscription plan?' : 'Activate this plan?',
          style: const TextStyle(
            color: AppColors.navy,
            fontSize: 16,
            fontWeight: FontWeight.w900,
          ),
        ),
        content: Text(
          changing
              ? 'Your current subscription will be replaced by ${plan.displayName}. Billing and activation rules are handled by the server.'
              : 'Activate ${plan.displayName}. Any payment requirement is handled by the server and configured provider.',
          style: const TextStyle(color: AppColors.grey, fontSize: 11.5, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Not now'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.blue),
            child: Text(changing ? 'Change Plan' : 'Activate'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    HapticFeedback.mediumImpact();
    setState(() {});
    final ok = await _controller.choosePlan(plan);
    if (!mounted) return;
    setState(() {});
    _snack(
      ok ? '${plan.displayName} is now your current plan.' : (_controller.actionErrorMessage ?? 'Unable to update subscription.'),
      success: ok,
    );
  }

  Future<void> _cancelSubscription() async {
    final current = _controller.current;
    if (current == null || !current.isActive) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Text(
          'Cancel subscription?',
          style: TextStyle(
            color: AppColors.navy,
            fontSize: 16,
            fontWeight: FontWeight.w900,
          ),
        ),
        content: const Text(
          'This changes the current subscription to Cancelled. Access and expiration behavior remains controlled by the backend.',
          style: TextStyle(color: AppColors.grey, fontSize: 11.5, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Keep Subscription'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.red),
            child: const Text('Cancel Subscription'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    HapticFeedback.mediumImpact();
    setState(() {});
    final ok = await _controller.cancelCurrent();
    if (!mounted) return;
    setState(() {});
    _snack(
      ok ? 'Subscription cancelled.' : (_controller.actionErrorMessage ?? 'Unable to cancel subscription.'),
      success: ok,
    );
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
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Subscription',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
            ),
            Text(
              'Plan, billing status & history',
              style: TextStyle(color: AppColors.grey, fontSize: 9.5, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _controller.isActing ? null : _load,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.blue,
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 34),
          children: [
            if (_initialLoading)
              ...List.generate(3, (index) => const Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: _Skeleton(height: 150),
                  ))
            else if (_controller.errorMessage != null && _controller.plans.isEmpty)
              _ErrorCard(message: _controller.errorMessage!, onRetry: _load)
            else ...[
              _currentSubscriptionCard(),
              const SizedBox(height: 18),
              _sectionHeader(
                'Available Plans',
                'Plans and prices come directly from the backend.',
                Icons.workspace_premium_outlined,
              ),
              const SizedBox(height: 10),
              if (_controller.plans.isEmpty)
                _emptyCard('No active subscription plans are available right now.')
              else
                ..._controller.plans.map((plan) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _planCard(plan),
                    )),
              const SizedBox(height: 12),
              _sectionHeader(
                'Subscription History',
                'Every plan period recorded for this account.',
                Icons.history_rounded,
              ),
              const SizedBox(height: 10),
              if (_controller.history.isEmpty)
                _emptyCard('No previous subscriptions yet.')
              else
                ..._controller.history.take(8).map((item) => Padding(
                      padding: const EdgeInsets.only(bottom: 9),
                      child: _historyCard(item),
                    )),
              const SizedBox(height: 12),
              _sectionHeader(
                'Subscription Payments',
                'Charges created by subscription activity.',
                Icons.receipt_long_outlined,
              ),
              const SizedBox(height: 10),
              if (_controller.payments.isEmpty)
                _emptyCard('No subscription payments recorded yet.')
              else
                ..._controller.payments.take(10).map((item) => Padding(
                      padding: const EdgeInsets.only(bottom: 9),
                      child: _paymentCard(item),
                    )),
            ],
          ],
        ),
      ),
    );
  }

  Widget _currentSubscriptionCard() {
    final current = _controller.current;
    final plan = current == null ? null : _controller.planById(current.subscriptionPlanId);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF071D39), Color(0xFF0A526C), Color(0xFF0FA6B4)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withOpacity(0.12),
            blurRadius: 22,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: current == null
          ? const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.workspace_premium_outlined, color: Colors.white, size: 28),
                SizedBox(height: 14),
                Text(
                  'No current subscription',
                  style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w900),
                ),
                SizedBox(height: 5),
                Text(
                  'Choose one of the active plans below. The app does not hard-code prices or limits.',
                  style: TextStyle(color: Color(0xFFD3E8EC), fontSize: 10.8, height: 1.5),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Text(
                        current.statusLabel.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8.5,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.7,
                        ),
                      ),
                    ),
                    const Spacer(),
                    const Icon(Icons.workspace_premium_rounded, color: Color(0xFF8BE2DF), size: 24),
                  ],
                ),
                const SizedBox(height: 15),
                Text(
                  plan?.displayName ?? 'Plan #${current.subscriptionPlanId}',
                  style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w900),
                ),
                if (plan != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    '${plan.priceLabel} • ${plan.periodLabel}',
                    style: const TextStyle(color: Color(0xFFD3E8EC), fontSize: 10.8, fontWeight: FontWeight.w700),
                  ),
                ],
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(child: _darkMetric('Started', _date(current.startDate))),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _darkMetric(
                        current.renewalDate != null ? 'Renewal' : 'Expires',
                        _date(current.renewalDate ?? current.expirationDate),
                      ),
                    ),
                  ],
                ),
                if (current.isActive) ...[
                  const SizedBox(height: 14),
                  OutlinedButton.icon(
                    onPressed: _controller.isActing ? null : _cancelSubscription,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 46),
                      foregroundColor: Colors.white,
                      side: BorderSide(color: Colors.white.withOpacity(0.28)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: const Icon(Icons.cancel_outlined, size: 17),
                    label: const Text('Cancel Subscription', style: TextStyle(fontWeight: FontWeight.w800)),
                  ),
                ],
              ],
            ),
    );
  }

  Widget _planCard(SubscriptionPlanModel plan) {
    final current = _controller.current;
    final selected = current?.isActive == true && current?.subscriptionPlanId == plan.id;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: selected ? AppColors.green.withOpacity(0.35) : AppColors.cardBorder,
          width: selected ? 1.4 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withOpacity(0.025),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: selected ? AppColors.greenBg : AppColors.blueBg,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  selected ? Icons.check_circle_rounded : Icons.workspace_premium_outlined,
                  color: selected ? AppColors.green : AppColors.blue,
                  size: 20,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plan.displayName,
                      style: const TextStyle(color: AppColors.navy, fontSize: 14, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${plan.priceLabel} • ${plan.periodLabel}',
                      style: const TextStyle(color: AppColors.grey, fontSize: 10.2, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              if (selected)
                const Text(
                  'CURRENT',
                  style: TextStyle(color: AppColors.green, fontSize: 8.7, fontWeight: FontWeight.w900, letterSpacing: 0.7),
                ),
            ],
          ),
          if (plan.features.isNotEmpty) ...[
            const SizedBox(height: 13),
            ...plan.features.take(6).map((feature) => _bullet(feature, Icons.check_rounded, AppColors.green)),
          ],
          if (plan.limits.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...plan.limits.take(4).map((limit) => _bullet(limit, Icons.tune_rounded, AppColors.blue)),
          ],
          const SizedBox(height: 13),
          FilledButton(
            onPressed: selected || _controller.isActing ? null : () => _choosePlan(plan),
            style: FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
              backgroundColor: AppColors.blue,
              foregroundColor: Colors.white,
              disabledBackgroundColor: selected ? AppColors.greenBg : AppColors.lightGrey.withOpacity(0.35),
              disabledForegroundColor: selected ? AppColors.green : AppColors.grey,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: Text(
              selected
                  ? 'Current Plan'
                  : current?.isActive == true
                      ? 'Change to ${plan.displayName}'
                      : 'Activate ${plan.displayName}',
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }

  Widget _historyCard(UserSubscriptionModel item) {
    final plan = _controller.planById(item.subscriptionPlanId);
    final accent = item.isActive
        ? AppColors.green
        : item.isPastDue
            ? AppColors.orange
            : AppColors.grey;

    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: accent.withOpacity(0.08), borderRadius: BorderRadius.circular(11)),
            child: Icon(Icons.history_rounded, size: 17, color: accent),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  plan?.displayName ?? 'Plan #${item.subscriptionPlanId}',
                  style: const TextStyle(color: AppColors.navy, fontSize: 11.7, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 3),
                Text(
                  '${_date(item.startDate)} → ${_date(item.expirationDate)}',
                  style: const TextStyle(color: AppColors.grey, fontSize: 9.5),
                ),
              ],
            ),
          ),
          Text(
            item.statusLabel,
            style: TextStyle(color: accent, fontSize: 9.3, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }

  Widget _paymentCard(SubscriptionPaymentModel item) {
    final failed = item.status == 'failed';
    final success = const {'funded', 'released'}.contains(item.status);
    final accent = failed ? AppColors.red : success ? AppColors.green : AppColors.blue;

    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: accent.withOpacity(0.08), borderRadius: BorderRadius.circular(11)),
            child: Icon(Icons.receipt_long_outlined, size: 17, color: accent),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.amountLabel,
                        style: const TextStyle(color: AppColors.navy, fontSize: 11.8, fontWeight: FontWeight.w900),
                      ),
                    ),
                    Text(item.statusLabel, style: TextStyle(color: accent, fontSize: 9.2, fontWeight: FontWeight.w900)),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  '${item.provider.trim().isEmpty ? 'Provider not set' : item.provider} • ${_dateTime(item.createdAt)}',
                  style: const TextStyle(color: AppColors.grey, fontSize: 9.3),
                ),
                if (failed && item.failureReason.trim().isNotEmpty) ...[
                  const SizedBox(height: 5),
                  Text(item.failureReason, style: const TextStyle(color: AppColors.red, fontSize: 9.3, height: 1.35)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _darkMetric(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.08), borderRadius: BorderRadius.circular(13)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Color(0xFFBBD8DE), fontSize: 8.8)),
          const SizedBox(height: 3),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }

  Widget _bullet(String text, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 7),
          Expanded(child: Text(text, style: const TextStyle(color: AppColors.text, fontSize: 10.2, height: 1.35))),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title, String subtitle, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(color: AppColors.blueBg, borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: AppColors.blue, size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: AppColors.navy, fontSize: 13, fontWeight: FontWeight.w900)),
              const SizedBox(height: 2),
              Text(subtitle, style: const TextStyle(color: AppColors.grey, fontSize: 9.7, height: 1.35)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _emptyCard(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Text(text, style: const TextStyle(color: AppColors.grey, fontSize: 10.5, height: 1.4)),
    );
  }

  String _date(DateTime? value) {
    if (value == null || value.millisecondsSinceEpoch == 0) return '—';
    final local = value.toLocal();
    return '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')}';
  }

  String _dateTime(DateTime? value) {
    if (value == null) return '—';
    final local = value.toLocal();
    return '${_date(local)} ${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }

  void _snack(String message, {required bool success}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: success ? AppColors.green : AppColors.red,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          content: Text(message),
        ),
      );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message, required this.onRetry});
  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        children: [
          const Icon(Icons.cloud_off_outlined, color: AppColors.orange, size: 30),
          const SizedBox(height: 10),
          Text(message, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.grey, fontSize: 11, height: 1.45)),
          const SizedBox(height: 10),
          FilledButton.icon(
            onPressed: () {
              onRetry();
            },
            icon: const Icon(Icons.refresh_rounded, size: 17),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

class _Skeleton extends StatelessWidget {
  const _Skeleton({required this.height});
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(color: const Color(0xFFEAF2F5), borderRadius: BorderRadius.circular(22)),
    );
  }
}
