import '../models/drone_form_request.dart';
import '../models/drone_model.dart';
import '../services/drone_service.dart';

// ============================================================================
// DRONE CONTROLLER
// ============================================================================

class DroneController {
  final DroneService service;

  DroneController(
      this.service,
      );

  List<DroneModel> drones =
  <DroneModel>[];

  bool isLoading = false;
  bool isSaving = false;
  bool isDeleting = false;

  String? errorMessage;

  // ==========================================================================
  // LOAD LIST
  // ==========================================================================

  Future<List<DroneModel>?>
  loadDrones() async {
    if (isLoading) {
      return drones;
    }

    isLoading = true;
    errorMessage = null;

    try {
      drones =
      await service.getMyDrones();

      return List<DroneModel>.unmodifiable(
        drones,
      );
    } catch (e) {
      errorMessage =
          e.toString();

      return null;
    } finally {
      isLoading = false;
    }
  }

  // ==========================================================================
  // LOAD ONE
  // ==========================================================================

  Future<DroneModel?>
  loadDrone(
      int droneId,
      ) async {
    errorMessage = null;

    try {
      final drone =
      await service.getDrone(
        droneId,
      );

      _upsert(
        drone,
      );

      return drone;
    } catch (e) {
      errorMessage =
          e.toString();

      return null;
    }
  }

  // ==========================================================================
  // CREATE
  // ==========================================================================

  Future<DroneModel?>
  createDrone(
      DroneFormRequest request,
      ) async {
    if (isSaving) {
      return null;
    }

    isSaving = true;
    errorMessage = null;

    try {
      final drone =
      await service.createDrone(
        request,
      );

      _upsert(
        drone,
      );

      return drone;
    } catch (e) {
      errorMessage =
          e.toString();

      return null;
    } finally {
      isSaving = false;
    }
  }

  // ==========================================================================
  // UPDATE
  // ==========================================================================

  Future<DroneModel?>
  updateDrone(
      int droneId,
      DroneFormRequest request,
      ) async {
    if (isSaving) {
      return null;
    }

    isSaving = true;
    errorMessage = null;

    try {
      final drone =
      await service.updateDrone(
        droneId,
        request,
      );

      _upsert(
        drone,
      );

      return drone;
    } catch (e) {
      errorMessage =
          e.toString();

      return null;
    } finally {
      isSaving = false;
    }
  }

  // ==========================================================================
  // DELETE
  // ==========================================================================

  Future<bool>
  deleteDrone(
      int droneId,
      ) async {
    if (isDeleting) {
      return false;
    }

    isDeleting = true;
    errorMessage = null;

    try {
      await service.deleteDrone(
        droneId,
      );

      drones.removeWhere(
            (item) =>
        item.id == droneId,
      );

      return true;
    } catch (e) {
      errorMessage =
          e.toString();

      return false;
    } finally {
      isDeleting = false;
    }
  }

  // ==========================================================================
  // LOCAL UPSERT
  // ==========================================================================

  void _upsert(
      DroneModel drone,
      ) {
    final index =
    drones.indexWhere(
          (item) =>
      item.id == drone.id,
    );

    if (index == -1) {
      drones.insert(
        0,
        drone,
      );
      return;
    }

    drones[index] =
        drone;
  }
}