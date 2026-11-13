import 'package:flutter/foundation.dart';

import '../models/pilot_job_filters.dart';
import '../models/pilot_job_model.dart';
import '../services/pilot_job_service.dart';

class PilotJobController extends ChangeNotifier {
  final PilotJobService service;

  PilotJobController(this.service);

  PilotJobFilters filters = const PilotJobFilters();

  final List<PilotJobModel> _jobs = [];
  List<PilotJobModel> get jobs => List.unmodifiable(_jobs);

  bool isInitialLoading = false;
  bool isRefreshing = false;
  bool isLoadingMore = false;

  String? errorMessage;
  String? errorCode;
  int? errorStatusCode;

  int currentPage = 1;
  int lastPage = 1;
  int total = 0;

  bool get canLoadMore =>
      !isInitialLoading &&
          !isRefreshing &&
          !isLoadingMore &&
          currentPage < lastPage;

  bool get isRateLimited => errorStatusCode == 429;

  Future<void> loadInitial() async {
    if (isInitialLoading) return;

    isInitialLoading = true;
    _clearError();
    notifyListeners();

    try {
      final result = await service.browseJobs(
        filters: filters,
        page: 1,
      );

      _replaceWith(result);
      _clearError();
    } catch (e) {
      _captureError(e);
    } finally {
      isInitialLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    if (isRefreshing) return;

    isRefreshing = true;
    _clearError();
    notifyListeners();

    try {
      final result = await service.browseJobs(
        filters: filters,
        page: 1,
      );

      _replaceWith(result);
      _clearError();
    } catch (e) {
      _captureError(e);
    } finally {
      isRefreshing = false;
      notifyListeners();
    }
  }

  Future<void> loadMore() async {
    if (!canLoadMore) return;

    isLoadingMore = true;
    notifyListeners();

    try {
      final result = await service.browseJobs(
        filters: filters,
        page: currentPage + 1,
      );

      final existingIds = _jobs.map((job) => job.id).toSet();

      for (final job in result.jobs) {
        if (existingIds.add(job.id)) {
          _jobs.add(job);
        }
      }

      currentPage = result.currentPage;
      lastPage = result.lastPage;
      total = result.total;
      _clearError();
    } catch (e) {
      // Keep the visible list if only the next page failed.
      _captureError(e);
    } finally {
      isLoadingMore = false;
      notifyListeners();
    }
  }

  Future<void> applyFilters(PilotJobFilters newFilters) async {
    filters = newFilters;
    await loadInitial();
  }

  Future<void> updateSearch(String query) async {
    filters = filters.copyWith(search: query.trim());
    await loadInitial();
  }

  Future<void> clearAdvancedFilters() async {
    filters = filters.clearAdvanced();
    await loadInitial();
  }

  void _replaceWith(PilotJobsPage result) {
    _jobs
      ..clear()
      ..addAll(result.jobs);

    currentPage = result.currentPage;
    lastPage = result.lastPage;
    total = result.total;
  }

  void _clearError() {
    errorMessage = null;
    errorCode = null;
    errorStatusCode = null;
  }

  void _captureError(Object error) {
    if (error is PilotJobException) {
      errorMessage = error.message;
      errorCode = error.code;
      errorStatusCode = error.statusCode;
      return;
    }

    errorMessage = error.toString();
    errorCode = null;
    errorStatusCode = null;
  }
}
