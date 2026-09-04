import '../models/admin_directory_entry.dart';
import '../models/admin_pending_company_model.dart';
import '../models/admin_pending_pilot_model.dart';
import '../models/admin_user_model.dart';
import '../models/admin_verification_history_model.dart';
import '../services/admin_service.dart';

class AdminController {
  final AdminService service;

  AdminController(this.service);

  List<AdminPendingPilotModel>
      pendingPilots = [];

  List<AdminPendingCompanyModel>
      pendingCompanies = [];

  final Map<int, AdminDirectoryEntry>
      _knownAccounts = {};

  bool loading = false;
  bool actionLoading = false;

  String? errorMessage;

  int get pendingPilotCount =>
      pendingPilots.length;

  int get pendingCompanyCount =>
      pendingCompanies.length;

  int get totalPending =>
      pendingPilotCount +
      pendingCompanyCount;

  List<AdminDirectoryEntry>
      get knownAccounts {
    final items =
        _knownAccounts.values.toList();

    items.sort(
      (a, b) {
        final aDate =
            a.latestActionAt ??
            a.user.updatedAt ??
            a.user.createdAt ??
            DateTime.fromMillisecondsSinceEpoch(
              0,
            );

        final bDate =
            b.latestActionAt ??
            b.user.updatedAt ??
            b.user.createdAt ??
            DateTime.fromMillisecondsSinceEpoch(
              0,
            );

        return bDate.compareTo(aDate);
      },
    );

    return items;
  }

  int get knownPilotCount =>
      knownAccounts
          .where(
            (item) =>
                item.isPilot,
          )
          .length;

  int get knownCompanyCount =>
      knownAccounts
          .where(
            (item) =>
                item.isCompany,
          )
          .length;

  int get knownPendingCount =>
      knownAccounts
          .where(
            (item) =>
                item.isEffectivelyPending,
          )
          .length;

  int get knownActiveCount =>
      knownAccounts
          .where(
            (item) =>
                item.isEffectivelyActive,
          )
          .length;

  int get knownSuspendedCount =>
      knownAccounts
          .where(
            (item) =>
                item.isEffectivelySuspended,
          )
          .length;

  int get knownRejectedCount =>
      knownAccounts
          .where(
            (item) =>
                item.isEffectivelyRejected,
          )
          .length;

  // The supplied backend collection exposes only pending account-list
  // endpoints. Verification history can classify a known account, but
  // it cannot discover accounts that were never returned by a list API.
  bool get hasCompleteDirectoryApi =>
      false;

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
        final existing =
            _knownAccounts[
              pilot.user.id
            ];

        _knownAccounts[pilot.user.id] =
            AdminDirectoryEntry.pilot(
          pilot,
          verificationHistory:
              existing
                      ?.verificationHistory ??
                  const [],
        );
      }

      for (final company in companies) {
        final existing =
            _knownAccounts[
              company.user.id
            ];

        _knownAccounts[company.user.id] =
            AdminDirectoryEntry.company(
          company,
          verificationHistory:
              existing
                      ?.verificationHistory ??
                  const [],
        );
      }

      await _refreshKnownHistories();

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
      refreshHistory:
          true,
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
      refreshHistory:
          true,
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
      refreshHistory:
          true,
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
      refreshHistory:
          true,
    );
  }

  Future<List<AdminVerificationHistoryModel>?>
      verificationHistory(
    int userId,
  ) async {
    errorMessage = null;

    try {
      final history =
          await service
              .getVerificationHistory(
        userId,
      );

      final existing =
          _knownAccounts[
            userId
          ];

      if (existing != null) {
        _knownAccounts[userId] =
            existing.withHistory(
          history,
        );
      }

      return history;
    } catch (e) {
      errorMessage =
          e.toString();

      return null;
    }
  }

  Future<void> _refreshKnownHistories()
      async {
    final ids =
        _knownAccounts.keys.toList();

    for (final userId in ids) {
      try {
        final history =
            await service
                .getVerificationHistory(
          userId,
        );

        final existing =
            _knownAccounts[
              userId
            ];

        if (existing != null) {
          _knownAccounts[userId] =
              existing.withHistory(
            history,
          );
        }
      } catch (_) {
        // History should enrich the directory, not block the whole
        // Admin dashboard when one user's history cannot be loaded.
      }
    }
  }

  Future<void> _refreshHistoryForUser(
    int userId,
  ) async {
    try {
      final history =
          await service
              .getVerificationHistory(
        userId,
      );

      final existing =
          _knownAccounts[
            userId
          ];

      if (existing != null) {
        _knownAccounts[userId] =
            existing.withHistory(
          history,
        );
      }
    } catch (_) {
      // The action already succeeded. History refresh failure should
      // not turn the successful account action into a failed action.
    }
  }

  Future<AdminUserModel?> _action(
    Future<AdminUserModel> Function()
        call, {
    int? removePendingUserId,
    bool refreshHistory = false,
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
          _knownAccounts[
            updated.id
          ];

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
              pendingPilots[i]
                  .copyWithUser(
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

      if (refreshHistory) {
        await _refreshHistoryForUser(
          updated.id,
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
