import 'package:flutter/foundation.dart';

import '../models/pilot_dashboard_model.dart';
import '../services/pilot_dashboard_service.dart';

class PilotDashboardController extends ChangeNotifier {
  PilotDashboardController(this.service);

  final PilotDashboardService service;

  PilotDashboardModel? dashboard;
  bool isLoading = false;
  String? errorMessage;

  Future<void> load() async {
    if (isLoading) return;

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      dashboard = await service.getDashboard();
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      dashboard = await service.getDashboard();
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
