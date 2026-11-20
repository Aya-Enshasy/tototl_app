import 'package:tototl_app/core/localization/localized_text.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:tototl_app/core/localization/app_language.dart';
import 'package:tototl_app/core/theme/app_colors.dart';
import 'package:tototl_app/core/network/api_client.dart';
import 'package:tototl_app/core/navigation/company_shell_screen.dart';
import 'package:tototl_app/features/company/services/CompanyProfileSync.dart';

import '../controllers/subscription_controller.dart';
import '../controllers/subscription_entitlements_controller.dart';
import '../models/subscription_models.dart';
import '../models/subscription_plan_catalog.dart';
import '../services/subscription_service.dart';
import '../services/subscription_entitlements_service.dart';

class PlanSelectionScreen extends StatefulWidget {
  const PlanSelectionScreen({
    super.key,
    this.onboarding = false,
    this.upgradeOnly = false,
  });

  final bool onboarding;
  final bool upgradeOnly;

  @override
  State<PlanSelectionScreen> createState() =>
      _PlanSelectionScreenState();
}

class _PlanSelectionScreenState extends State<PlanSelectionScreen> {
  static const Color primary = AppColors.primary;
  static const Color dark = AppColors.text;
  static const Color muted = AppColors.grey;
  static const Color border = AppColors.border;

  late final SubscriptionController _subscription;
  late final SubscriptionEntitlementsController _entitlements;

  String _selectedId = '';
  bool _loading = true;
  bool _working = false;
  String? _error;

  List<SubscriptionPlanModel> get _plans =>
      SubscriptionPlanCatalog.visiblePlans(
        _subscription.plans,
        upgradeOnly: widget.upgradeOnly,
      );

  SubscriptionPlanModel? get _selected {
    for (final plan in _plans) {
      if (plan.id.toString() == _selectedId) {
        return plan;
      }
    }
    return null;
  }

  @override
  void initState() {
    super.initState();

    final api = ApiClient();

    _subscription = SubscriptionController(
      SubscriptionService(api),
    );

    _entitlements = SubscriptionEntitlementsController(
      SubscriptionEntitlementsService(api),
    );
    _entitlements.addListener(_entitlementsChanged);

    _loadPlans();
  }

  void _entitlementsChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _entitlements.removeListener(_entitlementsChanged);
    _entitlements.dispose();
    super.dispose();
  }

  Future<void> _loadPlans() async {
    if (mounted) {
      setState(() => _loading = true);
    }

    // Entitlements refresh in parallel; displaying plans does not wait for it.
    unawaited(_entitlements.load(force: true));
    final loaded = await _subscription.loadAll();

    if (!mounted) return;

    final plans = _plans;

    final activeId = _subscription.currentLoaded &&
        _subscription.current?.isActive == true
        ? _subscription.current!.subscriptionPlanId.toString()
        : '';

    setState(() {
      _loading = false;

      _error = loaded
          ? null
          : (_subscription.errorMessage ??
          'Unable to load subscription details.');

      if (!widget.upgradeOnly &&
          plans.any((p) => p.id.toString() == activeId)) {
        _selectedId = activeId;
      } else if (!plans.any(
            (p) => p.id.toString() == _selectedId,
      )) {
        final freePlans = widget.upgradeOnly
            ? <SubscriptionPlanModel>[]
            : plans.where((p) => p.isFree).toList();

        _selectedId = freePlans.isNotEmpty
            ? freePlans.first.id.toString()
            : plans.isNotEmpty
            ? plans.first.id.toString()
            : '';
      }
    });
  }

  bool _isCurrent(SubscriptionPlanModel plan) {
    return _subscription.currentLoaded &&
        _subscription.current?.isActive == true &&
        _subscription.current?.subscriptionPlanId == plan.id;
  }

  String _period(SubscriptionPlanModel plan) {
    if (plan.isFree) return 'forever';

    if (plan.billingPeriod == 'monthly') {
      return '/ month';
    }

    if (plan.billingPeriod == 'annual' ||
        plan.billingPeriod == 'yearly') {
      return '/ year';
    }

    return '/ ${plan.periodLabel.toLowerCase()}';
  }

  String _description(SubscriptionPlanModel plan) {
    if (SubscriptionPlanCatalog.isPreview(plan)) {
      return 'Plan preview. Pricing and benefits will be available soon.';
    }

    if (plan.isFree) {
      return 'Essential features included in your free plan.';
    }

    if (plan.billingPeriod == 'monthly') {
      return 'Flexible monthly subscription.';
    }

    if (plan.billingPeriod == 'annual' ||
        plan.billingPeriod == 'yearly') {
      return 'Annual subscription with included benefits.';
    }

    return 'Explore the benefits included in this plan.';
  }

  void _snack(String message, {bool error = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLanguage.text(
          message),
          style: const TextStyle(fontSize: 11),
        ),
        backgroundColor: error ? AppColors.red : primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _showPaymentUnavailable(
      SubscriptionPlanModel plan,
      ) async {
    final preview = SubscriptionPlanCatalog.isPreview(plan);

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        title: const LocalizedText(
          'Secure payment coming soon',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
        content: Text(
          preview
              ? '${plan.displayName} is a preview. '
              'The final price and payment setup are not available yet. '
              'No payment or subscription activation has occurred.'
              : '${plan.displayName} is available to choose, '
              'but Stripe checkout is not connected yet. '
              'No payment or activation has occurred.',
          style: const TextStyle(
            fontSize: 11.5,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const LocalizedText(
              'Got it',
              style: TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleContinue() async {
    final plan = _selected;

    if (plan == null || _working || _loading) {
      return;
    }

    // Preview plans never create a subscription.
    if (SubscriptionPlanCatalog.isPreview(plan)) {
      await _showPaymentUnavailable(plan);
      return;
    }

    if (!_subscription.currentLoaded) {
      _snack(
        'Could not verify your current plan. Please retry.',
        error: true,
      );
      return;
    }

    if (_isCurrent(plan)) {
      _snack('This plan is already active.');

      if (widget.onboarding) {
        _goHome();
      }
      return;
    }

    // No paid subscription can activate without verified payment.
    if (!plan.isFree) {
      await _showPaymentUnavailable(plan);
      return;
    }

    final previous = _subscription.current;

    final isDowngrade = previous?.isActive == true &&
        previous?.subscriptionPlanId != plan.id;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        title: Text(
          isDowngrade
              ? 'Switch to Free Plan?'
              : 'Activate Free Plan?',
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
        content: Text(
          isDowngrade
              ? 'Your current subscription will be replaced by the free plan.'
              : 'This plan is free. No payment will be taken.',
          style: const TextStyle(fontSize: 11.5),
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.pop(dialogContext, false),
            child: const LocalizedText(
              'Cancel',
              style: TextStyle(fontSize: 12),
            ),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(dialogContext, true),
            child: const LocalizedText(
              'Confirm',
              style: TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    HapticFeedback.mediumImpact();

    setState(() => _working = true);

    final success = await _subscription.choosePlan(plan);

    if (success) {
      await _entitlements.refresh();
    }

    if (!mounted) return;

    setState(() => _working = false);

    _snack(
      success
          ? '${plan.displayName} is active.'
          : (_subscription.actionErrorMessage ??
          'Unable to confirm subscription.'),
      error: !success,
    );

    if (success && widget.onboarding) {
      _goHome();
    }
  }

  Future<void> _cancelCurrent() async {
    final current = _subscription.current;

    if (!_subscription.currentLoaded ||
        current?.isActive != true ||
        _working) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const LocalizedText(
          'Cancel Subscription?',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
        content: const LocalizedText(
          'Your subscription benefits and limits may change.',
          style: TextStyle(fontSize: 11.5),
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.pop(dialogContext, false),
            child: const LocalizedText('Keep Plan'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(dialogContext, true),
            child: const LocalizedText('Cancel Plan'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _working = true);

    final success = await _subscription.cancelCurrent();

    if (success) {
      await _entitlements.refresh();
    }

    if (!mounted) return;

    setState(() => _working = false);

    _snack(
      success
          ? 'Subscription cancelled.'
          : (_subscription.actionErrorMessage ??
          'Unable to cancel subscription.'),
      error: !success,
    );

    if (success) {
      await _loadPlans();
    }
  }

  Future<void> _showManageSheet() async {
    final detailsFuture = _subscription.loadOptionalDetails();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      builder: (sheetContext) {
        return FutureBuilder<void>(
          future: detailsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const SafeArea(
                child: SizedBox(
                  height: 180,
                  child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                ),
              );
            }
            return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight:
                MediaQuery.sizeOf(sheetContext).height * 0.7,
              ),
              child: ListView(
                shrinkWrap: true,
                children: [
                  const LocalizedText(
                    'Manage Subscription',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: dark,
                    ),
                  ),
                  const SizedBox(height: 12),

                  if (_subscription.current != null)
                    Text(
                      'Status: ${_subscription.current!.statusLabel}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: muted,
                      ),
                    ),

                  const SizedBox(height: 16),

                  const LocalizedText(
                    'Subscription History',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  if (_subscription.history.isEmpty)
                     ListTile(
                      dense: true,
                      title: Text(AppLanguage.text(
                        'No history available.'),
                        style: TextStyle(fontSize: 11),
                      ),
                    ),

                  for (final item
                  in _subscription.history.take(15))
                    ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(
                        Icons.history,
                        size: 19,
                      ),
                      title: Text(
                        _subscription
                            .planById(item.subscriptionPlanId)
                            ?.displayName ??
                            'Plan #${item.subscriptionPlanId}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      subtitle: Text(
                        item.statusLabel,
                        style: const TextStyle(fontSize: 10),
                      ),
                    ),

                  const Divider(height: 20),

                  const LocalizedText(
                    'Payments',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  if (_subscription.payments.isEmpty)
                     ListTile(
                      dense: true,
                      title: Text(AppLanguage.text(
                        'No recorded payments.'),
                        style: TextStyle(fontSize: 11),
                      ),
                    ),

                  for (final payment
                  in _subscription.payments.take(15))
                    ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(
                        Icons.receipt_long_outlined,
                        size: 19,
                      ),
                      title: Text(
                        payment.amountLabel,
                        style: const TextStyle(fontSize: 12),
                      ),
                      subtitle: Text(
                        payment.statusLabel,
                        style: const TextStyle(fontSize: 10),
                      ),
                    ),

                  if (_subscription.current?.isActive == true) ...[
                    const Divider(height: 20),
                    OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(sheetContext);
                        unawaited(_cancelCurrent());
                      },
                      icon: const Icon(
                        Icons.cancel_outlined,
                        size: 17,
                      ),
                      label: const LocalizedText(
                        'Cancel Current Subscription',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
            );
          },
        );
      },
    );
  }

  void _goHome() {
    if (!mounted) return;

    if (!widget.onboarding) {
      Navigator.of(context).maybePop();
      return;
    }

    unawaited(
      CompanyProfileSync.instance.refreshFromApi(),
    );

    Navigator.of(
      context,
      rootNavigator: true,
    ).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => const CompanyShellScreen(),
      ),
          (route) => false,
    );
  }

  Widget _currentPlanCard() {
    final current = _subscription.current!;

    final plan = _subscription.planById(
      current.subscriptionPlanId,
    );

    final jobLimit = _entitlements.hasData
        ? _entitlements.limits.companyJobPostingsLimitLabel
        : 'Unavailable';

    final applicationLimit = _entitlements.hasData
        ? _entitlements.limits.pilotApplicationsLimitLabel
        : 'Unavailable';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: primary.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: primary.withOpacity(0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.verified_outlined,
                color: primary,
                size: 17,
              ),
              const SizedBox(width: 7),

              Expanded(
                child: Text(
                  plan?.displayName ?? 'Current Subscription',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: dark,
                  ),
                ),
              ),

              Text(
                current.statusLabel,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: current.isActive
                      ? primary
                      : AppColors.red,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          Text(
            'Job postings: $jobLimit',
            style: const TextStyle(
              fontSize: 10.5,
              color: muted,
            ),
          ),

          const SizedBox(height: 3),

          Text(
            'Pilot applications: $applicationLimit',
            style: const TextStyle(
              fontSize: 10.5,
              color: muted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _planCard(SubscriptionPlanModel plan) {
    final selected = _selectedId == plan.id.toString();
    final current = _isCurrent(plan);
    final preview = SubscriptionPlanCatalog.isPreview(plan);

    final price = preview ? '—' : plan.priceLabel;
    final period = preview ? 'Price pending' : _period(plan);

    final features = [
      ...plan.features,
      ...plan.limits,
    ];

    final icon = plan.isFree
        ? Icons.rocket_launch_outlined
        : plan.billingPeriod == 'monthly'
        ? Icons.bolt_outlined
        : Icons.workspace_premium_outlined;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _working
            ? null
            : () {
          HapticFeedback.selectionClick();

          setState(() {
            _selectedId = plan.id.toString();
          });
        },
        borderRadius: BorderRadius.circular(17),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: double.infinity,
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: selected
                ? const Color(0xFFEAF8FA)
                : Colors.white,
            borderRadius: BorderRadius.circular(17),
            border: Border.all(
              color: selected ? primary : border,
              width: selected ? 1.4 : 0.8,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.025),
                blurRadius: 9,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: primary.withOpacity(0.09),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      icon,
                      color: primary,
                      size: 18,
                    ),
                  ),

                  const SizedBox(width: 9),

                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLanguage.text(plan.displayName),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                            color: dark,
                          ),
                        ),

                        const SizedBox(height: 3),

                        Text(
                          preview
                              ? 'COMING SOON'
                              : plan.isFree
                              ? 'FREE ACCESS'
                              : plan.periodLabel.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: primary,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ],
                    ),
                  ),

                  Icon(
                    selected
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked_rounded,
                    color: selected ? primary : border,
                    size: 21,
                  ),
                ],
              ),

              const SizedBox(height: 12),

              Divider(
                height: 1,
                color: border.withOpacity(0.7),
              ),

              const SizedBox(height: 11),

              Row(
                children: [
                  Expanded(
                    child: Text(
                      AppLanguage.text(price),
                      maxLines: 2,
                      softWrap: true,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: dark,
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  Text(
                    AppLanguage.text(period),
                    style: const TextStyle(
                      fontSize: 10,
                      color: muted,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 7),

              Text(
                AppLanguage.text(_description(plan)),
                style: const TextStyle(
                  fontSize: 10.5,
                  height: 1.4,
                  color: muted,
                ),
              ),

              if (features.isNotEmpty) ...[
                const SizedBox(height: 10),

                for (final feature in features)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 5),
                    child: Row(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.check_circle_outline_rounded,
                          size: 13,
                          color: primary,
                        ),

                        const SizedBox(width: 6),

                        Expanded(
                          child: Text(
                            AppLanguage.text(feature),
                            style: const TextStyle(
                              fontSize: 10.5,
                              height: 1.35,
                              color: dark,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],

              if (selected) ...[
                const SizedBox(height: 10),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: primary.withOpacity(0.07),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.check_circle_rounded,
                        size: 14,
                        color: primary,
                      ),
                      const SizedBox(width: 6),

                      Expanded(
                        child: Text(
                          current
                              ? 'Current plan · Active'
                              : preview
                              ? 'Preview selected · Not active'
                              : 'Selected plan',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _selectedSummary() {
    final plan = _selected;
    if (plan == null) return const SizedBox.shrink();

    final preview = SubscriptionPlanCatalog.isPreview(plan);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: primary.withOpacity(0.055),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: primary.withOpacity(0.12),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.shopping_bag_outlined,
            size: 19,
            color: primary,
          ),

          const SizedBox(width: 9),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  plan.displayName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: dark,
                  ),
                ),
                Text(
                  preview
                      ? 'Preview only · Not activated'
                      : 'Your current selection',
                  style: const TextStyle(
                    fontSize: 10,
                    color: muted,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          Flexible(
            child: Text(
              preview ? 'Price pending' : plan.priceLabel,
              maxLines: 2,
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _buttonLabel() {
    final plan = _selected;

    if (plan == null) return 'Select a Plan';

    if (SubscriptionPlanCatalog.isPreview(plan)) {
      return 'Payment Setup Pending';
    }

    if (_isCurrent(plan)) return 'Current Plan ✓';

    if (plan.isFree) return 'Activate Free Plan';

    return 'Continue to Payment · Coming Soon';
  }

  Widget _actionButton() {
    final plan = _selected;

    final canPress = !_working &&
        plan != null &&
        (_subscription.currentLoaded ||
            SubscriptionPlanCatalog.isPreview(plan));

    return SizedBox(
      width: double.infinity,
      height: 46,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(13),
          gradient: const LinearGradient(
            colors: [
              Color(0xFF0D8AA5),
              Color(0xFF15C3C2),
            ],
          ),
        ),
        child: ElevatedButton(
          onPressed: canPress ? _handleContinue : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            disabledBackgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(13),
            ),
          ),
          child: _working
              ? const SizedBox(
            width: 19,
            height: 19,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white,
            ),
          )
              : Text(
            AppLanguage.text(_buttonLabel()),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final plans = _plans;

    return PopScope(
      canPop: !widget.onboarding,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFB),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 520,
              ),
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(
                  16,
                  12,
                  16,
                  24,
                ),
                children: [
                  // Top bar
                  Row(
                    children: [
                      SizedBox(
                        width: 34,
                        height: 34,
                        child: IconButton(
                          onPressed:
                          _working ? null : _goHome,
                          icon: const Icon(
                            Icons.close_rounded,
                            size: 18,
                          ),
                          padding: EdgeInsets.zero,
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.white,
                            side: const BorderSide(
                              color: border,
                            ),
                          ),
                        ),
                      ),

                      const Spacer(),

                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: border),
                        ),
                        child: Text(
                          widget.onboarding
                              ? 'STEP 3 OF 3'
                              : 'SUBSCRIPTIONS',
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: muted,
                          ),
                        ),
                      ),
                    ],
                  ),

                  if (widget.onboarding) ...[
                    const SizedBox(height: 13),

                    Row(
                      children: List.generate(
                        3,
                            (index) => Expanded(
                          child: Container(
                            height: 3,
                            margin: EdgeInsets.only(
                              right: index == 2 ? 0 : 5,
                            ),
                            decoration: BoxDecoration(
                              color: primary,
                              borderRadius:
                              BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Badge
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: primary.withOpacity(0.08),
                        borderRadius:
                        BorderRadius.circular(20),
                      ),
                      child:  Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.workspace_premium_outlined,
                            size: 13,
                            color: primary,
                          ),
                          SizedBox(width: 5),
                          Text(AppLanguage.text(
                            'SUBSCRIPTION PLANS'),
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 11),

                  Text(
                    widget.upgradeOnly
                        ? 'Upgrade Your Plan'
                        : 'Choose Your Plan',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: dark,
                    ),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    widget.upgradeOnly
                        ? 'You have reached your current plan limit. Explore the monthly and yearly upgrade options.'
                        : widget.onboarding
                        ? 'Choose a plan to get started. You can change it later.'
                        : 'Compare plans and manage your subscription.',
                    style: const TextStyle(
                      fontSize: 11,
                      height: 1.45,
                      color: muted,
                    ),
                  ),

                  const SizedBox(height: 20),

                  if (_subscription.currentLoaded &&
                      _subscription.current != null) ...[
                    _currentPlanCard(),
                    const SizedBox(height: 18),
                  ],

                  Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: primary.withOpacity(0.09),
                          borderRadius:
                          BorderRadius.circular(9),
                        ),
                        child: const Icon(
                          Icons.credit_card_rounded,
                          size: 17,
                          color: primary,
                        ),
                      ),

                      const SizedBox(width: 9),

                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
                          children: [
                            const LocalizedText(
                              'Available Plans',
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                                color: dark,
                              ),
                            ),

                            const SizedBox(height: 2),

                            Text(
                              widget.upgradeOnly
                                  ? 'Monthly and yearly upgrade options'
                                  : 'Select the plan that suits you',
                              style: const TextStyle(
                                fontSize: 10,
                                color: muted,
                              ),
                            ),
                          ],
                        ),
                      ),

                      if (!_loading)
                        IconButton(
                          onPressed: _loadPlans,
                          icon: const Icon(
                            Icons.refresh_rounded,
                            size: 18,
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 13),

                  if (_loading)
                    const Padding(
                      padding: EdgeInsets.symmetric(
                        vertical: 35,
                      ),
                      child: Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                        ),
                      ),
                    )
                  else ...[
                    for (final plan in plans) ...[
                      _planCard(plan),
                      const SizedBox(height: 11),
                    ],
                  ],

                  if (_error != null) ...[
                    Container(
                      padding: const EdgeInsets.all(11),
                      decoration: BoxDecoration(
                        color: AppColors.redBg,
                        borderRadius:
                        BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          Text(
                            _error!,
                            style: const TextStyle(
                              color: AppColors.red,
                              fontSize: 10.5,
                            ),
                          ),
                          TextButton(
                            onPressed: _loadPlans,
                            child: const LocalizedText(
                              'Try Again',
                              style:
                              TextStyle(fontSize: 11),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  if (!_loading && plans.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    _selectedSummary(),
                    const SizedBox(height: 14),
                    _actionButton(),
                  ],

                  if (_subscription.currentLoaded &&
                      _subscription.current?.isActive == true)
                    TextButton.icon(
                      onPressed:
                      _working ? null : _showManageSheet,
                      icon: const Icon(
                        Icons.settings_outlined,
                        size: 16,
                      ),
                      label: const LocalizedText(
                        'Manage Subscription & Payments',
                        style: TextStyle(fontSize: 11),
                      ),
                    ),

                  if (widget.onboarding)
                    TextButton(
                      onPressed:
                      _working ? null : _goHome,
                      child: const LocalizedText(
                        'Skip for now — Go to Dashboard',
                        style: TextStyle(fontSize: 11),
                      ),
                    ),

                  const SizedBox(height: 15),

                   Row(
                    mainAxisAlignment:
                    MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.lock_outline_rounded,
                        size: 12,
                        color: muted,
                      ),
                      SizedBox(width: 5),
                      Flexible(
                        child: Text(AppLanguage.text(
                          'You can change your subscription later.'),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 10,
                            color: muted,
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
      ),
    );
  }
}