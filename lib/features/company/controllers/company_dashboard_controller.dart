import 'package:flutter/foundation.dart';

import '../../pilot/services/company_dashboard_service.dart';
import '../models/company_dashboard_model.dart';

class CompanyDashboardController extends ChangeNotifier {
  CompanyDashboardController(this.service);

  final CompanyDashboardService service;

  CompanyDashboardModel? dashboard;
  bool isLoading = false;
  bool isRefreshing = false;
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
    if (isRefreshing) return;

    isRefreshing = true;
    notifyListeners();

    try {
      dashboard = await service.getDashboard();
      errorMessage = null;
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isRefreshing = false;
      notifyListeners();
    }
  }
}
