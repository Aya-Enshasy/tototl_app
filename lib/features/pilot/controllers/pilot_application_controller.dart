import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/pilot_application_model.dart';
import '../services/pilot_application_service.dart';

class PilotApplicationController extends ChangeNotifier {
  final PilotApplicationService service;

  PilotApplicationController(this.service);

  final List<PilotApplicationModel> _applications =
  <PilotApplicationModel>[];

  List<PilotApplicationModel> get applications =>
      List<PilotApplicationModel>.unmodifiable(_applications);

  bool isLoading = false;
  bool isRefreshing = false;
  String? errorMessage;

  bool get hasData => _applications.isNotEmpty;

  int get totalCount => _applications.length;

  int get pendingCount =>
      _applications.where((item) => item.isPending).length;

  int get acceptedCount =>
      _applications.where((item) => item.isAccepted).length;

  int get rejectedCount => _applications
      .where((item) => item.status.trim().toLowerCase() == 'rejected')
      .length;

  // ---------------------------------------------------------------------------
  // LOCAL-FIRST LOAD
  // ---------------------------------------------------------------------------

  Future<void> load() async {
    if (isLoading) return;

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    final cached = await service.getCachedApplications();

    if (cached != null) {
      _replaceAll(cached);
      isLoading = false;
      notifyListeners();

      // Cached data is already visible. Refresh quietly in the background.
      unawaited(refresh());
      return;
    }

    try {
      final result = await service.getMyApplications();
      _replaceAll(result);
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // ---------------------------------------------------------------------------
  // FRESH NETWORK REFRESH
  // ---------------------------------------------------------------------------

  Future<void> refresh() async {
    if (isRefreshing) return;

    isRefreshing = true;

    // Keep a blocking error only when there is nothing useful to show.
    if (_applications.isEmpty) {
      errorMessage = null;
    }

    notifyListeners();

    try {
      final result = await service.getMyApplications();
      _replaceAll(result);
      errorMessage = null;
    } catch (e) {
      if (_applications.isEmpty) {
        errorMessage = e.toString();
      }
    } finally {
      isRefreshing = false;
      notifyListeners();
    }
  }

  // ---------------------------------------------------------------------------
  // LOCAL UPDATE
  // ---------------------------------------------------------------------------

  void replaceApplication(PilotApplicationModel updated) {
    final index =
    _applications.indexWhere((item) => item.id == updated.id);

    if (index == -1) {
      _applications.insert(0, updated);
    } else {
      _applications[index] = updated;
    }

    _sortNewestFirst();
    notifyListeners();
  }

  void _replaceAll(List<PilotApplicationModel> values) {
    _applications
      ..clear()
      ..addAll(values);

    _sortNewestFirst();
  }

  void _sortNewestFirst() {
    _applications.sort((a, b) {
      final aDate =
          a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bDate =
          b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bDate.compareTo(aDate);
    });
  }
}
