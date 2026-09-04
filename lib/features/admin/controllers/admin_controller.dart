import '../models/admin_pending_company_model.dart';
import '../models/admin_pending_pilot_model.dart';
import '../models/admin_user_model.dart';
import '../models/admin_verification_history_model.dart';
import '../services/admin_service.dart';

class AdminController {
  final AdminService service;

  AdminController(this.service);

  List<AdminPendingPilotModel> pendingPilots = [];
  List<AdminPendingCompanyModel> pendingCompanies = [];

  bool loading = false;
  bool actionLoading = false;

  String? errorMessage;

  int get pendingPilotCount => pendingPilots.length;
  int get pendingCompanyCount => pendingCompanies.length;
  int get totalPending => pendingPilotCount + pendingCompanyCount;

  Future<bool> loadDashboard() async {
    if (loading) return false;

    loading = true;
    errorMessage = null;

    try {
      final result = await Future.wait([
        service.getPendingPilots(),
        service.getPendingCompanies(),
      ]);

      pendingPilots =
      result[0] as List<AdminPendingPilotModel>;

      pendingCompanies =
      result[1] as List<AdminPendingCompanyModel>;

      return true;
    } catch (e) {
      errorMessage = e.toString();
      return false;
    } finally {
      loading = false;
    }
  }

  Future<bool> refresh() => loadDashboard();

  Future<AdminUserModel?> approve(int userId) async {
    return _action(
          () => service.approveUser(userId),
      removePendingUserId: userId,
    );
  }

  Future<AdminUserModel?> reject({
    required int userId,
    required String reason,
  }) async {
    return _action(
          () => service.rejectUser(
        userId: userId,
        reason: reason,
      ),
      removePendingUserId: userId,
    );
  }

  Future<AdminUserModel?> suspend({
    required int userId,
    required String reason,
  }) async {
    return _action(
          () => service.suspendUser(
        userId: userId,
        reason: reason,
      ),
    );
  }

  Future<AdminUserModel?> reactivate(int userId) async {
    return _action(
          () => service.reactivateUser(userId),
    );
  }

  Future<List<AdminVerificationHistoryModel>?>
  verificationHistory(int userId) async {
    errorMessage = null;

    try {
      return await service.getVerificationHistory(userId);
    } catch (e) {
      errorMessage = e.toString();
      return null;
    }
  }

  Future<AdminUserModel?> _action(
      Future<AdminUserModel> Function() call, {
        int? removePendingUserId,
      }) async {
    if (actionLoading) return null;

    actionLoading = true;
    errorMessage = null;

    try {
      final user = await call();

      if (removePendingUserId != null) {
        pendingPilots.removeWhere(
              (item) => item.user.id == removePendingUserId,
        );

        pendingCompanies.removeWhere(
              (item) => item.user.id == removePendingUserId,
        );
      }

      return user;
    } catch (e) {
      errorMessage = e.toString();
      return null;
    } finally {
      actionLoading = false;
    }
  }
}
