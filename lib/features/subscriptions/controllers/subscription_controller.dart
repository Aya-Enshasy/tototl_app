import '../models/subscription_models.dart';
import '../services/subscription_service.dart';

class SubscriptionController {
  final SubscriptionService service;
  SubscriptionController(this.service);

  bool isLoading = false;
  bool isActing = false;
  bool currentLoaded = false;
  String? errorMessage;
  String? actionErrorMessage;

  List<SubscriptionPlanModel> plans = const [];
  UserSubscriptionModel? current;
  List<UserSubscriptionModel> history = const [];
  List<SubscriptionPaymentModel> payments = const [];

  Future<bool> loadAll() async {
    if (isLoading) return plans.isNotEmpty && currentLoaded;
    isLoading = true;
    // A failed refresh must never leave an old authorization state marked as fresh.
    currentLoaded = false;
    errorMessage = null;
    try {
      // Start independent requests together. History and payments must never
      // block the plan picker from opening (especially after a quota hit).
      final currentRequest = _loadCurrentSafe();
      plans = List.unmodifiable(await service.getPlans());
      await currentRequest;
      // Fetch history/payments only when Manage is opened, to avoid
      // unnecessary API bursts and Cloudflare rate limiting.
      return plans.isNotEmpty && currentLoaded;
    } catch (e) {
      errorMessage = e.toString();
      return false;
    } finally {
      isLoading = false;
    }
  }

  Future<void> _loadCurrentSafe() async {
    try {
      current = await service.getCurrent();
      currentLoaded = true;
    } catch (e) {
      errorMessage = 'Could not verify current subscription: $e';
    }
  }

  Future<void> loadOptionalDetails() async {
    await Future.wait<void>([_loadHistorySafe(), _loadPaymentsSafe()]);
  }

  Future<bool> choosePlan(SubscriptionPlanModel plan) async {
    if (isActing || !currentLoaded) return false;
    isActing = true;
    actionErrorMessage = null;
    try {
      if (!plan.isActive || !plans.any((available) => available.id == plan.id)) {
        throw const SubscriptionException('This plan is no longer available. Please refresh.');
      }
      final active = current;
      if (active != null && active.isActive && active.subscriptionPlanId == plan.id) {
        return true;
      }
      // The backend does not yet expose Stripe checkout/verification.
      // Never create a paid subscription through the simulated gateway.
      if (!plan.isFree) {
        throw const SubscriptionException(
          'Secure Stripe checkout is not available yet. No payment was made.',
        );
      }
      if (active != null && active.isActive) {
        current = await service.changePlan(subscriptionId: active.id, planId: plan.id);
      } else {
        current = await service.subscribe(plan.id);
      }
      await refreshAfterAction();
      if (currentLoaded && current?.isActive == true && current?.subscriptionPlanId == plan.id) {
        return true;
      }
      actionErrorMessage = 'Subscription submitted, but activation is not confirmed. Refresh to check its status.';
      return false;
    } catch (e) {
      actionErrorMessage = e.toString();
      return false;
    } finally {
      isActing = false;
    }
  }

  Future<bool> cancelCurrent() async {
    final active = current;
    if (active == null || !active.isActive || isActing) return false;
    isActing = true;
    actionErrorMessage = null;
    try {
      current = await service.cancel(active.id);
      await refreshAfterAction();
      if (currentLoaded && current?.isActive != true) return true;
      actionErrorMessage ??= 'Cancellation has not been confirmed yet. Please refresh your subscription.';
      return false;
    } catch (e) {
      actionErrorMessage = e.toString();
      return false;
    } finally {
      isActing = false;
    }
  }

  Future<void> refreshAfterAction() async {
    currentLoaded = false;
    try {
      current = await service.getCurrent();
      currentLoaded = true;
    } catch (e) {
      actionErrorMessage = 'Could not confirm the latest subscription state: $e';
    }
    await Future.wait<void>([_loadHistorySafe(), _loadPaymentsSafe()]);
  }

  Future<void> _loadHistorySafe() async {
    try {
      history = List.unmodifiable(await service.getHistory());
    } catch (_) {
      // History must not hide available plans or prevent free activation.
    }
  }

  Future<void> _loadPaymentsSafe() async {
    try {
      payments = List.unmodifiable(await service.getPayments());
    } catch (_) {
      // Payment history can be retried separately.
    }
  }

  SubscriptionPlanModel? planById(int id) {
    for (final plan in plans) {
      if (plan.id == id) return plan;
    }
    return null;
  }
}
