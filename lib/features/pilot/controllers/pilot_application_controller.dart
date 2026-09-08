import 'package:flutter/foundation.dart';
import '../models/pilot_application_model.dart';
import '../services/pilot_application_service.dart';

class PilotApplicationController extends ChangeNotifier {
  final PilotApplicationService service;

  PilotApplicationController(this.service);

  final List<PilotApplicationModel> _applications = [];

  List<PilotApplicationModel> get applications => List.unmodifiable(_applications);

  bool isLoading = false;
  bool isRefreshing = false;
  String? errorMessage;

  int get totalCount => _applications.length;
  int get pendingCount => _applications.where((item) => item.isPending).length;
  int get acceptedCount => _applications.where((item) => item.isAccepted).length;

  Future<void> load() async {
    if (isLoading) return;

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final result = await service.getMyApplications();
      _applications
        ..clear()
        ..addAll(result);
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
    errorMessage = null;
    notifyListeners();

    try {
      final result = await service.getMyApplications();
      _applications
        ..clear()
        ..addAll(result);
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isRefreshing = false;
      notifyListeners();
    }
  }

  void replaceApplication(PilotApplicationModel updated) {
    final index = _applications.indexWhere((item) => item.id == updated.id);
    if (index == -1) {
      _applications.insert(0, updated);
    } else {
      _applications[index] = updated;
    }
    notifyListeners();
  }
}
