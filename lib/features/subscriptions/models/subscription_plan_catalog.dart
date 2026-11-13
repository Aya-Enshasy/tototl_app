import 'subscription_models.dart';

/// Plans shown in the UI, including safe display-only placeholders for paid
/// periods that are not yet configured in the API.
///
/// A negative ID identifies a preview. It must NEVER be submitted to Laravel
/// as a subscription_plan_id or treated as an active paid entitlement.
class SubscriptionPlanCatalog {
  const SubscriptionPlanCatalog._();

  static const int _monthlyPreviewId = -101;
  static const int _yearlyPreviewId = -102;

  static bool isPreview(SubscriptionPlanModel plan) => plan.id < 0;

  static List<SubscriptionPlanModel> visiblePlans(
    List<SubscriptionPlanModel> apiPlans, {
    bool upgradeOnly = false,
  }) {
    final activePlans = apiPlans
        .where((plan) => plan.id > 0 && plan.isActive)
        .toList(growable: false);
    final freePlans = activePlans.where((plan) => plan.isFree);
    final paidPlans = activePlans.where((plan) => !plan.isFree).toList();

    final hasMonthly = paidPlans.any(
      (plan) => plan.billingPeriod.toLowerCase() == 'monthly',
    );
    final hasYearly = paidPlans.any((plan) {
      final billingPeriod = plan.billingPeriod.toLowerCase();
      return billingPeriod == 'yearly' || billingPeriod == 'annual';
    });

    return List<SubscriptionPlanModel>.unmodifiable([
      if (!upgradeOnly) ...freePlans,
      ...paidPlans,
      if (!hasMonthly)
        const SubscriptionPlanModel(
          id: _monthlyPreviewId,
          name: 'Monthly Plan',
          price: 'Pricing pending',
          billingPeriod: 'monthly',
          isActive: false,
        ),
      if (!hasYearly)
        const SubscriptionPlanModel(
          id: _yearlyPreviewId,
          name: 'Yearly Plan',
          price: 'Pricing pending',
          billingPeriod: 'annual',
          isActive: false,
        ),
    ]);
  }
}
