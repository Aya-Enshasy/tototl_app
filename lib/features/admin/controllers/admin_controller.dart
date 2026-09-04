import '../models/admin_directory_entry.dart';
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

  final Map<int, AdminDirectoryEntry> _knownAccounts = {};

  bool loading = false;
  bool actionLoading = false;

  String? errorMessage;

  int get pendingPilotCount => pendingPilots.length;

  int get pendingCompanyCount =>
      pendingCompanies.length;

  int get totalPending =>
      pendingPilotCount +
      pendingCompanyCount;

  List<AdminDirectoryEntry> get knownAccounts {
    final items =
        _knownAccounts.values.toList();

    items.sort(
      (a, b) {
        final aDate =
            a.user.updatedAt ??
            a.user.createdAt ??
            DateTime.fromMillisecondsSinceEpoch(0);

        final bDate =
            b.user.updatedAt ??
            b.user.createdAt ??
            DateTime.fromMillisecondsSinceEpoch(0);

        return bDate.compareTo(aDate);
      },
    );

    return items;
  }

  int get knownPilotCount =>
      knownAccounts
          .where(
            (item) => item.isPilot,
          )
          .length;

  int get knownCompanyCount =>
      knownAccounts
          .where(
            (item) => item.isCompany,
          )
          .length;

  int get knownActiveCount =>
      knownAccounts
          .where(
            (item) => item.user.isActive,
          )
          .length;

  int get knownSuspendedCount =>
      knownAccounts
          .where(
            (item) => item.user.isSuspended,
          )
          .length;

  int get knownRejectedCount =>
      knownAccounts
          .where(
            (item) =>
                item.user.normalizedStatus ==
                'rejected',
          )
          .length;

  // The supplied backend collection exposes only pending list endpoints.
  // Therefore this directory is "known accounts": current pending records
  // plus accounts changed by this admin during the current app session.
  bool get hasCompleteDirectoryApi => false;

  Future<bool> loadDashboard() async {
    if (loading) {
      return false;
    }

    loading = true;
    errorMessage = null;

    try {
      final pilots =
          await service.getPendingPilots();

      final companies =
          await service.getPendingCompanies();

      pendingPilots =
          pilots;

      pendingCompanies =
          companies;

      for (final pilot in pilots) {
        _knownAccounts[pilot.user.id] =
            AdminDirectoryEntry.pilot(
          pilot,
        );
      }

      for (final company in companies) {
        _knownAccounts[company.user.id] =
            AdminDirectoryEntry.company(
          company,
        );
      }

      return true;
    } catch (e) {
      errorMessage =
          e.toString();

      return false;
    } finally {
      loading =
          false;
    }
  }

  Future<bool> refresh() =>
      loadDashboard();

  Future<AdminUserModel?> approve(
    int userId,
  ) async {
    return _action(
      () =>
          service.approveUser(
        userId,
      ),
      removePendingUserId:
          userId,
    );
  }

  Future<AdminUserModel?> reject({
    required int userId,
    required String reason,
  }) async {
    return _action(
      () =>
          service.rejectUser(
        userId: userId,
        reason: reason,
      ),
      removePendingUserId:
          userId,
    );
  }

  Future<AdminUserModel?> suspend({
    required int userId,
    required String reason,
  }) async {
    return _action(
      () =>
          service.suspendUser(
        userId: userId,
        reason: reason,
      ),
    );
  }

  Future<AdminUserModel?> reactivate(
    int userId,
  ) async {
    return _action(
      () =>
          service.reactivateUser(
        userId,
      ),
    );
  }

  Future<List<AdminVerificationHistoryModel>?>
      verificationHistory(
    int userId,
  ) async {
    errorMessage = null;

    try {
      return await service
          .getVerificationHistory(
        userId,
      );
    } catch (e) {
      errorMessage =
          e.toString();

      return null;
    }
  }

  Future<AdminUserModel?> _action(
    Future<AdminUserModel> Function()
        call, {
    int? removePendingUserId,
  }) async {
    if (actionLoading) {
      return null;
    }

    actionLoading =
        true;

    errorMessage =
        null;

    try {
      final updated =
          await call();

      final existing =
          _knownAccounts[updated.id];

      if (existing != null) {
        _knownAccounts[updated.id] =
            existing.withUser(
          updated,
        );
      }

      for (var i = 0;
          i < pendingPilots.length;
          i++) {
        if (pendingPilots[i].user.id ==
            updated.id) {
          pendingPilots[i] =
              pendingPilots[i].copyWithUser(
            updated,
          );
        }
      }

      for (var i = 0;
          i < pendingCompanies.length;
          i++) {
        if (pendingCompanies[i].user.id ==
            updated.id) {
          pendingCompanies[i] =
              pendingCompanies[i]
                  .copyWithUser(
            updated,
          );
        }
      }

      if (removePendingUserId != null) {
        pendingPilots.removeWhere(
          (item) =>
              item.user.id ==
              removePendingUserId,
        );

        pendingCompanies.removeWhere(
          (item) =>
              item.user.id ==
              removePendingUserId,
        );
      }

      return updated;
    } catch (e) {
      errorMessage =
          e.toString();

      return null;
    } finally {
      actionLoading =
          false;
    }
  }
}
