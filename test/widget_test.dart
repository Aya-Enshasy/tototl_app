import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tototl_app/core/localization/app_language.dart';
import 'package:tototl_app/features/subscriptions/models/subscription_models.dart';
import 'package:tototl_app/features/subscriptions/models/subscription_plan_catalog.dart';

void main() {
  tearDown(() {
    AppLanguage.locale.value = const Locale('en');
  });

  test('upgrade mode must never offer the free plan', () {
    const free = SubscriptionPlanModel(
      id: 1,
      name: 'Free',
      price: '0',
      isActive: true,
    );
    final plans = SubscriptionPlanCatalog.visiblePlans(
      [free],
      upgradeOnly: true,
    );
    expect(plans.every((plan) => !plan.isFree), isTrue);
    expect(plans.any((plan) => plan.billingPeriod == 'monthly'), isTrue);
    expect(plans.any((plan) => plan.billingPeriod == 'annual'), isTrue);
    expect(plans.where(SubscriptionPlanCatalog.isPreview).length, 2);
  });

  test('paid placeholders have negative IDs and are never active', () {
    final plans = SubscriptionPlanCatalog.visiblePlans(const []);
    expect(plans.length, 2);
    expect(plans.every(SubscriptionPlanCatalog.isPreview), isTrue);
    expect(plans.every((plan) => plan.id < 0 && !plan.isActive), isTrue);
  });

  test('language mapping switches and retains English fallback', () {
    AppLanguage.locale.value = const Locale('ar');
    expect(AppLanguage.t('settings'), 'الإعدادات');
    expect(AppLanguage.text('My Contracts'), 'عقودي');
    expect(AppLanguage.text('Server-provided name'), 'Server-provided name');
    AppLanguage.locale.value = const Locale('en');
    expect(AppLanguage.t('settings'), 'Settings');
  });
}
