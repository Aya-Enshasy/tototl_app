import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/drone_model.dart';
import '../models/pilot_application_model.dart';
import '../models/pilot_job_model.dart';
import '../services/drone_service.dart';
import '../services/pilot_application_service.dart';
import '../services/pilot_job_service.dart';

/// Controller for the pilot's application history.
///
/// Important UI contract:
/// - The first visible snapshot is ALWAYS built from a fresh network response.
/// - Cached/list snapshots are never painted first and then replaced.
/// - Missing job/drone relations are hydrated off-screen before the list is published.
/// - Refresh keeps the last authoritative snapshot visible and swaps atomically.
class PilotApplicationController extends ChangeNotifier {
  PilotApplicationController(
      this.service, {
        this.jobService,
        this.droneService,
      });

  final PilotApplicationService service;
  final PilotJobService? jobService;
  final DroneService? droneService;

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
      final hydrated = await _hydrateRelations(network);

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
      final hydrated = await _hydrateRelations(network);

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
  // HYDRATE MISSING JOB / DRONE RELATIONS BEFORE PUBLISHING THE LIST
  // ---------------------------------------------------------------------------

  Future<List<PilotApplicationModel>> _hydrateRelations(
      List<PilotApplicationModel> applications,
      ) async {
    if (applications.isEmpty) {
      return <PilotApplicationModel>[];
    }

    final jobLoader = jobService;
    final droneLoader = droneService;

    // The current /applications response already includes job_posting + drone.
    // These requests are only fallbacks for older/partial responses.
    final jobFutures = <int, Future<PilotJobModel?>>{};
    final droneFutures = <int, Future<DroneModel?>>{};

    for (final application in applications) {
      if (jobLoader != null &&
          application.job == null &&
          application.jobPostingId > 0) {
        jobFutures.putIfAbsent(
          application.jobPostingId,
              () => _safeLoadJob(jobLoader, application.jobPostingId),
        );
      }

      if (droneLoader != null &&
          application.drone == null &&
          application.droneId > 0) {
        droneFutures.putIfAbsent(
          application.droneId,
              () => _safeLoadDrone(droneLoader, application.droneId),
        );
      }
    }

    if (jobFutures.isEmpty && droneFutures.isEmpty) {
      return List<PilotApplicationModel>.from(applications);
    }

    final jobEntries = jobFutures.entries.toList(growable: false);
    final droneEntries = droneFutures.entries.toList(growable: false);

    final jobsById = <int, PilotJobModel?>{};
    final dronesById = <int, DroneModel?>{};

    await Future.wait<void>([
          () async {
        final values = await Future.wait<PilotJobModel?>(
          jobEntries.map((entry) => entry.value),
        );
        for (var index = 0; index < jobEntries.length; index++) {
          jobsById[jobEntries[index].key] = values[index];
        }
      }(),
          () async {
        final values = await Future.wait<DroneModel?>(
          droneEntries.map((entry) => entry.value),
        );
        for (var index = 0; index < droneEntries.length; index++) {
          dronesById[droneEntries[index].key] = values[index];
        }
      }(),
    ]);

    return applications.map((application) {
      final job =
          application.job ?? jobsById[application.jobPostingId];
      final drone =
          application.drone ?? dronesById[application.droneId];

      if (identical(job, application.job) &&
          identical(drone, application.drone)) {
        return application;
      }

      return application.copyWith(
        job: job,
        drone: drone,
      );
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
      // application whose job was closed/cancelled.
      return null;
    }
  }

  Future<DroneModel?> _safeLoadDrone(
      DroneService loader,
      int droneId,
      ) async {
    try {
      return await loader.getDrone(droneId);
    } catch (_) {
      // Keep the real application even when a related drone can no longer be
      // fetched separately. The list/detail response remains authoritative.
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
