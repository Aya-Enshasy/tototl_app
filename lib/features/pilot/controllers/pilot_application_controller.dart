import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/pilot_application_model.dart';
import '../models/pilot_job_model.dart';
import '../services/pilot_application_service.dart';
import '../services/pilot_job_service.dart';

/// Controller for the pilot's application history.
///
/// Important UI contract:
/// - The first visible snapshot is ALWAYS built from a fresh network response.
/// - Cached/list snapshots are never painted first and then replaced.
/// - Job relations are hydrated off-screen before the list is published.
/// - Refresh keeps the last authoritative snapshot visible and swaps atomically.
class PilotApplicationController extends ChangeNotifier {
  PilotApplicationController(
      this.service, {
        this.jobService,
      });

  final PilotApplicationService service;
  final PilotJobService? jobService;

  final List<PilotApplicationModel> _applications =
  <PilotApplicationModel>[];

  List<PilotApplicationModel> get applications =>
      List<PilotApplicationModel>.unmodifiable(_applications);

  bool isLoading = false;
  bool isRefreshing = false;
  String? errorMessage;
  String? refreshErrorMessage;

  bool _disposed = false;
  int _requestSerial = 0;

  bool get hasData => _applications.isNotEmpty;

  int get totalCount => _applications.length;

  int get pendingCount =>
      _applications.where((item) => item.isPending).length;

  int get acceptedCount =>
      _applications.where((item) => item.isAccepted).length;

  int get rejectedCount => _applications
      .where((item) => item.status.trim().toLowerCase() == 'rejected')
      .length;

  int get withdrawnCount => _applications
      .where((item) => item.status.trim().toLowerCase() == 'withdrawn')
      .length;

  // ---------------------------------------------------------------------------
  // AUTHORITATIVE FIRST LOAD
  // ---------------------------------------------------------------------------

  Future<void> load() async {
    if (isLoading) return;

    final serial = ++_requestSerial;

    isLoading = true;
    errorMessage = null;
    refreshErrorMessage = null;
    _notify();

    try {
      final network = await service.getMyApplications();
      final hydrated = await _hydrateJobs(network);

      if (!_isCurrent(serial)) return;

      _replaceAll(hydrated);
      errorMessage = null;
    } catch (e) {
      if (!_isCurrent(serial)) return;
      errorMessage = e.toString();
    } finally {
      if (_isCurrent(serial)) {
        isLoading = false;
        _notify();
      }
    }
  }

  // ---------------------------------------------------------------------------
  // FRESH REFRESH - KEEP CURRENT AUTHORITATIVE DATA UNTIL REPLACEMENT IS READY
  // ---------------------------------------------------------------------------

  Future<bool> refresh() async {
    if (isRefreshing) return true;

    final serial = ++_requestSerial;

    isRefreshing = true;
    refreshErrorMessage = null;

    if (_applications.isEmpty) {
      isLoading = true;
      errorMessage = null;
    }

    _notify();

    try {
      final network = await service.getMyApplications();
      final hydrated = await _hydrateJobs(network);

      if (!_isCurrent(serial)) return false;

      _replaceAll(hydrated);
      errorMessage = null;
      refreshErrorMessage = null;
      return true;
    } catch (e) {
      if (!_isCurrent(serial)) return false;

      final message = e.toString();
      refreshErrorMessage = message;

      if (_applications.isEmpty) {
        errorMessage = message;
      }

      return false;
    } finally {
      if (_isCurrent(serial)) {
        isLoading = false;
        isRefreshing = false;
        _notify();
      }
    }
  }

  // ---------------------------------------------------------------------------
  // HYDRATE JOB RELATIONS BEFORE PUBLISHING THE LIST
  // ---------------------------------------------------------------------------

  Future<List<PilotApplicationModel>> _hydrateJobs(
      List<PilotApplicationModel> applications,
      ) async {
    final loader = jobService;

    if (loader == null || applications.isEmpty) {
      return List<PilotApplicationModel>.from(applications);
    }

    final futures = <int, Future<PilotJobModel?>>{};

    for (final application in applications) {
      if (application.job != null || application.jobPostingId <= 0) {
        continue;
      }

      futures.putIfAbsent(
        application.jobPostingId,
            () => _safeLoadJob(loader, application.jobPostingId),
      );
    }

    if (futures.isEmpty) {
      return List<PilotApplicationModel>.from(applications);
    }

    final entries = futures.entries.toList(growable: false);
    final values = await Future.wait<PilotJobModel?>(
      entries.map((entry) => entry.value),
    );

    final jobsById = <int, PilotJobModel?>{};
    for (var index = 0; index < entries.length; index++) {
      jobsById[entries[index].key] = values[index];
    }

    return applications.map((application) {
      final existing = application.job;
      if (existing != null) return application;

      final job = jobsById[application.jobPostingId];
      if (job == null) return application;

      return application.copyWith(job: job);
    }).toList(growable: false);
  }

  Future<PilotJobModel?> _safeLoadJob(
      PilotJobService loader,
      int jobId,
      ) async {
    try {
      return await loader.getJobDetails(jobId);
    } catch (_) {
      // Published-job details may legitimately be unavailable for an old
      // application whose job was closed/cancelled. Never invent replacement
      // values; the UI will render the real application IDs/status instead.
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // LOCAL UPDATE AFTER A REAL MUTATION/DETAIL RESPONSE
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
    _notify();
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

  bool _isCurrent(int serial) => !_disposed && serial == _requestSerial;

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
