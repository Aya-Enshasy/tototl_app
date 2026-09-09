import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/drone_form_request.dart';
import '../models/drone_model.dart';
import '../services/drone_service.dart';

// ============================================================================
// DRONE CONTROLLER
//
// Project loading rule:
// 1) Show the latest local snapshot immediately when it exists.
// 2) Refresh from the API in the background.
// 3) Never clear useful data just because a refresh is running.
// 4) Shimmer is only for the true first load when no local snapshot exists.
// ============================================================================

class DroneController extends ChangeNotifier {
  final DroneService service;

  DroneController(
      this.service,
      );

  final List<DroneModel> drones = <DroneModel>[];

  bool isInitialLoading = false;
  bool isRefreshing = false;
  bool isSaving = false;
  bool isDeleting = false;

  /// True after either a cached snapshot or a fresh API snapshot has been read.
  /// An empty cached list still counts as a valid snapshot.
  bool hasSnapshot = false;

  String? errorMessage;
  String? lastRefreshError;

  bool _bootstrapStarted = false;

  /// Backward-compatible aggregate loading flag.
  bool get isLoading => isInitialLoading || isRefreshing;

  bool get hasData => drones.isNotEmpty;

  // ===========================================================================
  // BOOTSTRAP - LOCAL FIRST, THEN SILENT NETWORK REFRESH
  // ===========================================================================

  Future<void> bootstrap() async {
    if (_bootstrapStarted) {
      if (hasSnapshot) {
        unawaited(
          refresh(
            silent: true,
          ),
        );
      }
      return;
    }

    _bootstrapStarted = true;
    errorMessage = null;
    lastRefreshError = null;
    isInitialLoading = !hasSnapshot;
    notifyListeners();

    try {
      final cached = await service.getCachedDrones();

      if (cached != null) {
        _replaceAll(
          cached,
        );
        hasSnapshot = true;
        isInitialLoading = false;
        notifyListeners();

        // The user is already looking at useful local data.
        // Ask the API for the latest version without blocking the UI.
        unawaited(
          refresh(
            silent: true,
          ),
        );
        return;
      }
    } catch (_) {
      // Cache failure must not block the real API load.
    }

    // No local snapshot has ever been stored for this user.
    // This is the only case where the screen should remain in first-load shimmer.
    await refresh(
      silent: false,
    );
  }

  // ===========================================================================
  // REFRESH - FRESH API DATA, KEEP CURRENT CONTENT ON SCREEN
  // ===========================================================================

  Future<bool> refresh({
    bool silent = false,
  }) async {
    if (isRefreshing) {
      return true;
    }

    isRefreshing = true;
    lastRefreshError = null;

    if (!hasSnapshot) {
      isInitialLoading = true;
      errorMessage = null;
    }

    notifyListeners();

    try {
      final fresh = await service.getMyDrones();

      _replaceAll(
        fresh,
      );

      hasSnapshot = true;
      errorMessage = null;
      lastRefreshError = null;

      return true;
    } catch (e) {
      final message = e.toString();
      lastRefreshError = message;

      // A background refresh must never replace valid cached data with an error.
      if (!hasSnapshot) {
        errorMessage = message;
      } else if (!silent) {
        // Keep the data visible. The caller may show a small SnackBar for a
        // user-requested pull-to-refresh failure.
        errorMessage = null;
      }

      return false;
    } finally {
      isRefreshing = false;
      isInitialLoading = false;
      notifyListeners();
    }
  }

  // ===========================================================================
  // LEGACY LIST LOAD
  //
  // Kept so existing screens/forms that still call loadDrones() do not break.
  // New list UIs should call bootstrap() once, then refresh() when requested.
  // ===========================================================================

  Future<List<DroneModel>?> loadDrones() async {
    final success = await refresh(
      silent: hasSnapshot,
    );

    if (!success && !hasSnapshot) {
      return null;
    }

    return List<DroneModel>.unmodifiable(
      drones,
    );
  }

  // ===========================================================================
  // RE-READ LOCAL CACHE
  //
  // Useful when returning from another screen that may have created, edited,
  // or deleted a drone through another DroneService instance.
  // ===========================================================================

  Future<bool> reloadLocalSnapshot() async {
    try {
      final cached = await service.getCachedDrones();

      if (cached == null) {
        return false;
      }

      _replaceAll(
        cached,
      );
      hasSnapshot = true;
      errorMessage = null;
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  // ===========================================================================
  // LOAD ONE
  // ===========================================================================

  Future<DroneModel?> loadDrone(
      int droneId,
      ) async {
    errorMessage = null;

    try {
      final drone = await service.getDrone(
        droneId,
      );

      upsertLocal(
        drone,
      );

      return drone;
    } catch (e) {
      errorMessage = e.toString();
      return null;
    }
  }

  // ===========================================================================
  // CREATE
  // ===========================================================================

  Future<DroneModel?> createDrone(
      DroneFormRequest request,
      ) async {
    if (isSaving) {
      return null;
    }

    isSaving = true;
    errorMessage = null;
    notifyListeners();

    try {
      final drone = await service.createDrone(
        request,
      );

      upsertLocal(
        drone,
      );

      return drone;
    } catch (e) {
      errorMessage = e.toString();
      return null;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  // ===========================================================================
  // UPDATE
  // ===========================================================================

  Future<DroneModel?> updateDrone(
      int droneId,
      DroneFormRequest request,
      ) async {
    if (isSaving) {
      return null;
    }

    isSaving = true;
    errorMessage = null;
    notifyListeners();

    try {
      final drone = await service.updateDrone(
        droneId,
        request,
      );

      upsertLocal(
        drone,
      );

      return drone;
    } catch (e) {
      errorMessage = e.toString();
      return null;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  // ===========================================================================
  // DELETE
  // ===========================================================================

  Future<bool> deleteDrone(
      int droneId,
      ) async {
    if (isDeleting) {
      return false;
    }

    isDeleting = true;
    errorMessage = null;
    notifyListeners();

    try {
      await service.deleteDrone(
        droneId,
      );

      removeLocal(
        droneId,
      );

      return true;
    } catch (e) {
      errorMessage = e.toString();
      return false;
    } finally {
      isDeleting = false;
      notifyListeners();
    }
  }

  // ===========================================================================
  // LOCAL MUTATIONS
  // ===========================================================================

  void upsertLocal(
      DroneModel drone,
      ) {
    final index = drones.indexWhere(
          (item) => item.id == drone.id,
    );

    if (index == -1) {
      drones.insert(
        0,
        drone,
      );
    } else {
      drones[index] = drone;
    }

    hasSnapshot = true;
    notifyListeners();
  }

  void removeLocal(
      int droneId,
      ) {
    drones.removeWhere(
          (item) => item.id == droneId,
    );

    hasSnapshot = true;
    notifyListeners();
  }

  void _replaceAll(
      List<DroneModel> values,
      ) {
    drones
      ..clear()
      ..addAll(values);
  }
}
