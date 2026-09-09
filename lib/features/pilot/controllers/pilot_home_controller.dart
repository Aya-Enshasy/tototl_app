import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:tototl_app/features/pilot/models/pilot_application_model.dart';
import 'package:tototl_app/features/pilot/models/pilot_home_snapshot.dart';
import 'package:tototl_app/features/pilot/services/pilot_application_service.dart';

import '../models/drone_model.dart';
import '../services/drone_service.dart';

/// Pilot Home data coordinator.
///
/// Strategy:
/// 1. Read the already persisted service caches first.
/// 2. Paint them immediately when available.
/// 3. Refresh both endpoints in parallel without clearing what is on screen.
/// 4. On the very first launch only, sections without a cache keep their
///    skeleton until their network request finishes.
class PilotHomeController extends ChangeNotifier {
  PilotHomeController({
    required this.applicationService,
    required this.droneService,
  });

  final PilotApplicationService applicationService;
  final DroneService droneService;

  PilotHomeSnapshot? _snapshot;
  PilotHomeSnapshot? get snapshot => _snapshot;

  bool _hasDronesSnapshot = false;
  bool _hasApplicationsSnapshot = false;

  bool get hasDronesSnapshot => _hasDronesSnapshot;
  bool get hasApplicationsSnapshot => _hasApplicationsSnapshot;
  bool get hasAnySnapshot =>
      _hasDronesSnapshot || _hasApplicationsSnapshot;

  bool isDronesInitialLoading = true;
  bool isApplicationsInitialLoading = true;
  bool isRefreshing = false;

  /// Kept for compatibility with older Home code.
  bool get isInitialLoading =>
      isDronesInitialLoading || isApplicationsInitialLoading;

  String? dronesError;
  String? applicationsError;
  String? errorMessage;

  bool _bootstrapping = false;
  bool _networkRefreshing = false;
  bool _disposed = false;

  Future<void> bootstrap() async {
    if (_bootstrapping || _disposed) return;
    _bootstrapping = true;

    isDronesInitialLoading = !_hasDronesSnapshot;
    isApplicationsInitialLoading = !_hasApplicationsSnapshot;
    dronesError = null;
    applicationsError = null;
    errorMessage = null;
    _safeNotify();

    try {
      // Both disk-cache reads start together. Each service itself checks its
      // in-memory cache before touching FlutterSecureStorage.
      final cachedResults = await Future.wait<dynamic>([
        _safeCachedDrones(),
        _safeCachedApplications(),
      ]);

      if (_disposed) return;

      final cachedDrones = cachedResults[0] as List<DroneModel>?;
      final cachedApplications =
      cachedResults[1] as List<PilotApplicationModel>?;

      if (cachedDrones != null) {
        _setDrones(cachedDrones);
        _hasDronesSnapshot = true;
        isDronesInitialLoading = false;
      }

      if (cachedApplications != null) {
        _setApplications(cachedApplications);
        _hasApplicationsSnapshot = true;
        isApplicationsInitialLoading = false;
      }

      _safeNotify();

      if (hasAnySnapshot) {
        // The user already has something useful to look at. Do not make Home
        // wait for the internet; refresh silently in the background.
        unawaited(_refreshFromNetwork());
      } else {
        // True first-use path: there is no local snapshot yet, so keep the
        // skeletons visible while the first authoritative requests complete.
        await _refreshFromNetwork();
      }
    } finally {
      _bootstrapping = false;
    }
  }

  /// Explicit refresh that never clears currently visible Home data.
  Future<void> forceRefresh() async {
    if (_disposed) return;

    if (!hasAnySnapshot) {
      isDronesInitialLoading = !_hasDronesSnapshot;
      isApplicationsInitialLoading = !_hasApplicationsSnapshot;
      _safeNotify();
    }

    await _refreshFromNetwork();
  }

  Future<List<DroneModel>?> _safeCachedDrones() async {
    try {
      return await droneService.getCachedDrones();
    } catch (_) {
      return null;
    }
  }

  Future<List<PilotApplicationModel>?> _safeCachedApplications() async {
    try {
      return await applicationService.getCachedApplications();
    } catch (_) {
      return null;
    }
  }

  Future<void> _refreshFromNetwork() async {
    if (_networkRefreshing || _disposed) return;
    _networkRefreshing = true;

    isRefreshing = hasAnySnapshot;
    errorMessage = null;

    // Do not remove section errors if that section still has no data. A Retry
    // should visibly remain in a failed first-load section until it succeeds.
    if (_hasDronesSnapshot) dronesError = null;
    if (_hasApplicationsSnapshot) applicationsError = null;

    _safeNotify();

    try {
      // Run both endpoints concurrently. Each method updates its own section as
      // soon as it finishes, so a slow endpoint cannot hold the other one back.
      await Future.wait<void>([
        _refreshDrones(),
        _refreshApplications(),
      ]);
    } finally {
      if (!_disposed) {
        isRefreshing = false;
        _networkRefreshing = false;

        if (!hasAnySnapshot) {
          errorMessage =
              applicationsError ?? dronesError ?? 'Unable to load Home data.';
        } else {
          errorMessage = null;
        }

        _safeNotify();
      } else {
        _networkRefreshing = false;
      }
    }
  }

  Future<void> _refreshDrones() async {
    try {
      final fresh = await droneService.getMyDrones();
      if (_disposed) return;

      _setDrones(fresh);
      _hasDronesSnapshot = true;
      dronesError = null;
    } catch (e) {
      if (!_hasDronesSnapshot) {
        dronesError = _cleanError(e);
      }
    } finally {
      if (!_disposed) {
        isDronesInitialLoading = false;
        _safeNotify();
      }
    }
  }

  Future<void> _refreshApplications() async {
    try {
      final fresh = await applicationService.getMyApplications();
      if (_disposed) return;

      _setApplications(fresh);
      _hasApplicationsSnapshot = true;
      applicationsError = null;
    } catch (e) {
      if (!_hasApplicationsSnapshot) {
        applicationsError = _cleanError(e);
      }
    } finally {
      if (!_disposed) {
        isApplicationsInitialLoading = false;
        _safeNotify();
      }
    }
  }

  void _setDrones(List<DroneModel> values) {
    final mapped = values
        .map(PilotHomeDroneItem.fromDrone)
        .toList(growable: false);

    _snapshot = (_snapshot ?? const PilotHomeSnapshot()).copyWith(
      drones: List<PilotHomeDroneItem>.unmodifiable(mapped),
    );
  }

  void _setApplications(List<PilotApplicationModel> values) {
    final mapped = values
        .map(PilotHomeApplicationItem.fromApplication)
        .toList(growable: false);

    _snapshot = (_snapshot ?? const PilotHomeSnapshot()).copyWith(
      applications: List<PilotHomeApplicationItem>.unmodifiable(mapped),
    );
  }

  String _cleanError(Object error) {
    final value = error.toString().trim();
    if (value.startsWith('Exception:')) {
      return value.substring('Exception:'.length).trim();
    }
    return value.isEmpty ? 'Something went wrong.' : value;
  }

  void _safeNotify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
