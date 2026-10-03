import '../models/subscription_models.dart';
import '../services/subscription_service.dart';

class SubscriptionController {
  final SubscriptionService service;
  SubscriptionController(this.service);

  bool isLoading = false;
  bool isActing = false;
  String? errorMessage;
  String? actionErrorMessage;

  List<SubscriptionPlanModel> plans = const [];
  UserSubscriptionModel? current;
  List<UserSubscriptionModel> history = const [];
  List<SubscriptionPaymentModel> payments = const [];

  Future<bool> loadAll() async {
    if (isLoading) return true;
    isLoading = true;
    errorMessage = null;
    try {
      final result = await Future.wait<dynamic>([
        service.getPlans(),
        service.getCurrent(),
        service.getHistory(),
        service.getPayments(),
      ]);
      plans = List.unmodifiable(result[0] as List<SubscriptionPlanModel>);
      current = result[1] as UserSubscriptionModel?;
      history = List.unmodifiable(result[2] as List<UserSubscriptionModel>);
      payments = List.unmodifiable(result[3] as List<SubscriptionPaymentModel>);
      return true;
    } catch (e) {
      errorMessage = e.toString();
      return false;
    } finally {
      isLoading = false;
    }
  }

  Future<bool> choosePlan(SubscriptionPlanModel plan) async {
    if (isActing) return false;
    isActing = true;
    actionErrorMessage = null;
    try {
      final active = current;
      if (active != null && active.isActive) {
        if (active.subscriptionPlanId == plan.id) return true;
        current = await service.changePlan(subscriptionId: active.id, planId: plan.id);
      } else {
        current = await service.subscribe(plan.id);
      }
      await _reloadHistory();
      return true;
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
      await _reloadHistory();
      return true;
    } catch (e) {
      actionErrorMessage = e.toString();
      return false;
    } finally {
      isActing = false;
    }
  }

  Future<void> _reloadHistory() async {
    final result = await Future.wait<dynamic>([
      service.getHistory(),
      service.getPayments(),
    ]);
    history = List.unmodifiable(result[0] as List<UserSubscriptionModel>);
    payments = List.unmodifiable(result[1] as List<SubscriptionPaymentModel>);
  }

  SubscriptionPlanModel? planById(int id) {
    for (final plan in plans) {
      if (plan.id == id) return plan;
    }
    return null;
  }
}
