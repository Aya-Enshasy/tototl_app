import '../models/admin_pending_company_model.dart';
import '../models/admin_pending_pilot_model.dart';
import '../services/admin_service.dart';

// ============================================================================
// ADMIN CONTROLLER
// ============================================================================

class AdminController {
  final AdminService service;

  AdminController(
    this.service,
  );

  List<AdminPendingPilotModel>
      pendingPilots =
      <AdminPendingPilotModel>[];

  List<AdminPendingCompanyModel>
      pendingCompanies =
      <AdminPendingCompanyModel>[];

  bool isLoadingAll = false;
  bool isLoadingPilots = false;
  bool isLoadingCompanies = false;

  String? pilotsError;
  String? companiesError;

  // ==========================================================================
  // COUNTS
  // ==========================================================================

  int get pendingPilotCount =>
      pendingPilots.length;

  int get pendingCompanyCount =>
      pendingCompanies.length;

  int get totalPending =>
      pendingPilotCount +
      pendingCompanyCount;

  bool get hasAnyPending =>
      totalPending > 0;

  // ==========================================================================
  // LOAD ALL
  // ==========================================================================

  Future<void> loadAll() async {
    if (isLoadingAll) {
      return;
    }

    isLoadingAll = true;
    pilotsError = null;
    companiesError = null;

    try {
      await Future.wait([
        _loadPilotsInternal(),
        _loadCompaniesInternal(),
      ]);
    } finally {
      isLoadingAll = false;
    }
  }

  // ==========================================================================
  // PILOTS
  // ==========================================================================

  Future<List<AdminPendingPilotModel>?>
  loadPendingPilots() async {
    if (isLoadingPilots) {
      return pendingPilots;
    }

    isLoadingPilots = true;
    pilotsError = null;

    try {
      pendingPilots =
          await service.getPendingPilots();

      return List<
          AdminPendingPilotModel>.unmodifiable(
        pendingPilots,
      );
    } catch (e) {
      pilotsError =
          e.toString();

      return null;
    } finally {
      isLoadingPilots = false;
    }
  }

  Future<void> _loadPilotsInternal() async {
    pilotsError = null;

    try {
      pendingPilots =
          await service.getPendingPilots();
    } catch (e) {
      pilotsError =
          e.toString();
    }
  }

  // ==========================================================================
  // COMPANIES
  // ==========================================================================

  Future<List<AdminPendingCompanyModel>?>
  loadPendingCompanies() async {
    if (isLoadingCompanies) {
      return pendingCompanies;
    }

    isLoadingCompanies = true;
    companiesError = null;

    try {
      pendingCompanies =
          await service.getPendingCompanies();

      return List<
          AdminPendingCompanyModel>.unmodifiable(
        pendingCompanies,
      );
    } catch (e) {
      companiesError =
          e.toString();

      return null;
    } finally {
      isLoadingCompanies = false;
    }
  }

  Future<void> _loadCompaniesInternal() async {
    companiesError = null;

    try {
      pendingCompanies =
          await service.getPendingCompanies();
    } catch (e) {
      companiesError =
          e.toString();
    }
  }

  // ==========================================================================
  // REFRESH
  // ==========================================================================

  Future<void> refreshAll() async {
    await loadAll();
  }
}
