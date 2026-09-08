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

  int currentPage = 1;
  int lastPage = 1;
  int total = 0;

  bool get canLoadMore =>
      !isInitialLoading &&
      !isRefreshing &&
      !isLoadingMore &&
      currentPage < lastPage;

  Future<void> loadInitial() async {
    if (isInitialLoading) return;

    isInitialLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final result = await service.browseJobs(
        filters: filters,
        page: 1,
      );

      _replaceWith(result);
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isInitialLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    if (isRefreshing) return;

    isRefreshing = true;
    errorMessage = null;
    notifyListeners();

    try {
      final result = await service.browseJobs(
        filters: filters,
        page: 1,
      );

      _replaceWith(result);
    } catch (e) {
      errorMessage = e.toString();
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
      errorMessage = null;
    } catch (e) {
      // Keep the visible list if only the next page failed.
      errorMessage = e.toString();
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
}
