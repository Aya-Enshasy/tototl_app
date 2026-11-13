import 'package:flutter/foundation.dart';

import '../models/subscription_entitlements_model.dart';
import '../services/subscription_entitlements_service.dart';

class SubscriptionEntitlementsController extends ChangeNotifier {
  final SubscriptionEntitlementsService service;

  SubscriptionEntitlementsController(
      this.service,
      );

  SubscriptionEntitlementsModel? _entitlements;

  SubscriptionEntitlementsModel? get entitlements =>
      _entitlements;

  SubscriptionLimitsModel get limits =>
      _entitlements?.limits ??
          const SubscriptionLimitsModel();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  bool get hasData =>
      _entitlements != null;

  bool get hasError =>
      _errorMessage != null;

  Future<bool> load({
    bool force = false,
  }) async {
    if (_isLoading) {
      return false;
    }

    if (!force && _entitlements != null) {
      return true;
    }

    _isLoading = true;
    _errorMessage = null;

    notifyListeners();

    try {
      _entitlements =
      await service.getEntitlements();

      _isLoading = false;

      notifyListeners();

      return true;
    } on SubscriptionEntitlementsException catch (e) {
      _isLoading = false;
      _errorMessage = e.message;

      notifyListeners();

      return false;
    } catch (_) {
      _isLoading = false;
      _errorMessage =
      'Unable to load subscription entitlements.';

      notifyListeners();

      return false;
    }
  }

  Future<bool> refresh() {
    return load(
      force: true,
    );
  }

  bool canCreateCompanyJob({
    required int activeCount,
  }) {
    if (_entitlements == null) {
      return true;
    }

    return limits.canCreateCompanyJob(
      activeCount: activeCount,
    );
  }

  bool canCreatePilotApplication({
    required int activeCount,
  }) {
    if (_entitlements == null) {
      return true;
    }

    return limits.canCreatePilotApplication(
      activeCount: activeCount,
    );
  }

  void clearError() {
    if (_errorMessage == null) {
      return;
    }

    _errorMessage = null;
    notifyListeners();
  }

  void clear() {
    _entitlements = null;
    _isLoading = false;
    _errorMessage = null;

    notifyListeners();
  }
}
