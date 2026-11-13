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

  /// Every company returned by GET /admin/companies.
  ///
  /// The backend directory response currently contains the user/account fields
  /// but not necessarily company_profile. Pending-company data is merged later
  /// so pending records keep their richer profile information.
  List<AdminPendingCompanyModel> allCompanies = [];

  final Map<int, AdminDirectoryEntry> _knownAccounts = {};

  bool loading = false;
  bool actionLoading = false;

  String? errorMessage;

  int get pendingPilotCount => pendingPilots.length;

  int get pendingCompanyCount => pendingCompanies.length;

  int get totalPending => pendingPilotCount + pendingCompanyCount;

  List<AdminDirectoryEntry> get knownAccounts {
    final items = _knownAccounts.values.toList();

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
            (item) => item.isPilot,
      )
          .length;

  int get knownCompanyCount =>
      knownAccounts
          .where(
            (item) => item.isCompany,
      )
          .length;

  int get knownPendingCount =>
      knownAccounts
          .where(
            (item) => item.isEffectivelyPending,
      )
          .length;

  int get knownActiveCount =>
      knownAccounts
          .where(
            (item) => item.isEffectivelyActive,
      )
          .length;

  int get knownSuspendedCount =>
      knownAccounts
          .where(
            (item) => item.isEffectivelySuspended,
      )
          .length;

  int get knownRejectedCount =>
      knownAccounts
          .where(
            (item) => item.isEffectivelyRejected,
      )
          .length;

  bool _completeDirectoryLoaded = false;
  bool get hasCompleteDirectoryApi => _completeDirectoryLoaded;

  Future<bool> loadDashboard() async {
    if (loading) {
      return false;
    }

    loading = true;
    errorMessage = null;

    try {
      // Every request is isolated so a failing directory/history endpoint
      // cannot hide successfully loaded pending approvals.
      final warnings = <String>[];
      final results = await Future.wait<Object?>([
        _tryLoad('Pending pilots', service.getPendingPilots, warnings),
        _tryLoad('Pending companies', service.getPendingCompanies, warnings),
        _tryLoad('Company directory', service.getCompanies, warnings),
        _tryLoad('Pilot directory', () => service.getUsersByRole('pilot'), warnings),
        _tryLoad('User company directory', () => service.getUsersByRole('company'), warnings),
      ]);

      final pilots = results[0] as List<AdminPendingPilotModel>?;
      final companies = results[1] as List<AdminPendingCompanyModel>?;
      final companyDirectory = results[2] as List<AdminPendingCompanyModel>?;
      final pilotUsers = results[3] as List<AdminUserModel>?;
      final companyUsers = results[4] as List<AdminUserModel>?;

      if (pilots != null) pendingPilots = pilots;
      if (companies != null) pendingCompanies = companies;
      if (companyDirectory != null) allCompanies = companyDirectory;
      _completeDirectoryLoaded = pilotUsers != null && companyUsers != null;

      final oldAccounts = Map<int, AdminDirectoryEntry>.from(_knownAccounts);
      if (warnings.isEmpty) _knownAccounts.clear();

      List<AdminVerificationHistoryModel> knownHistory(int userId) =>
          _knownAccounts[userId]?.verificationHistory ??
          oldAccounts[userId]?.verificationHistory ?? const [];

      // Build the complete directory from the role-filtered user endpoint.
      // Detailed records then override these minimal profiles.
      for (final user in pilotUsers ?? const <AdminUserModel>[]) {
        _knownAccounts[user.id] = AdminDirectoryEntry.pilot(
          AdminPendingPilotModel(user: user),
          verificationHistory: knownHistory(user.id),
        );
      }

      for (final user in companyUsers ?? const <AdminUserModel>[]) {
        _knownAccounts[user.id] = AdminDirectoryEntry.company(
          AdminPendingCompanyModel(user: user),
          verificationHistory: knownHistory(user.id),
        );
      }

      for (final company in companyDirectory ?? const <AdminPendingCompanyModel>[]) {
        _knownAccounts[company.user.id] = AdminDirectoryEntry.company(
          company,
          verificationHistory: knownHistory(company.user.id),
        );
      }

      for (final pilot in pilots ?? const <AdminPendingPilotModel>[]) {
        _knownAccounts[pilot.user.id] = AdminDirectoryEntry.pilot(
          pilot,
          verificationHistory: knownHistory(pilot.user.id),
        );
      }

      for (final company in companies ?? const <AdminPendingCompanyModel>[]) {
        _knownAccounts[company.user.id] = AdminDirectoryEntry.company(
          company,
          verificationHistory: knownHistory(company.user.id),
        );
      }

      // Verification history is loaded when a user opens that tab or an
      // approval action completes. Fetching it once for *every* pending user
      // here made the Admin dashboard appear stuck on slow connections.

      errorMessage = warnings.isEmpty ? null : warnings.join(' · ');
      return results.any((result) => result != null);
    } catch (e) {
      errorMessage = e.toString();

      return false;
    } finally {
      loading = false;
    }
  }

  Future<T?> _tryLoad<T>(
    String label,
    Future<T> Function() loader,
    List<String> warnings,
  ) async {
    try {
      return await loader();
    } catch (error) {
      warnings.add('$label: $error');
      return null;
    }
  }

  Future<bool> refresh() => loadDashboard();

  Future<AdminUserModel?> approve(
      int userId,
      ) async {
    return _action(
          () => service.approveUser(
        userId,
      ),
      removePendingUserId: userId,
      refreshHistory: true,
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
      refreshHistory: true,
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
      refreshHistory: true,
    );
  }

  Future<AdminUserModel?> reactivate(
      int userId,
      ) async {
    return _action(
          () => service.reactivateUser(
        userId,
      ),
      refreshHistory: true,
    );
  }

  Future<List<AdminVerificationHistoryModel>?> verificationHistory(
      int userId,
      ) async {
    errorMessage = null;

    try {
      final history = await service.getVerificationHistory(
        userId,
      );

      final existing = _knownAccounts[userId];

      if (existing != null) {
        _knownAccounts[userId] = existing.withHistory(
          history,
        );
      }

      return history;
    } catch (e) {
      errorMessage = e.toString();

      return null;
    }
  }

  Future<void> _refreshHistoryForUser(
      int userId,
      ) async {
    try {
      final history = await service.getVerificationHistory(
        userId,
      );

      final existing = _knownAccounts[userId];

      if (existing != null) {
        _knownAccounts[userId] = existing.withHistory(
          history,
        );
      }
    } catch (_) {
      // The action already succeeded. History refresh failure should
      // not turn the successful account action into a failed action.
    }
  }

  Future<AdminUserModel?> _action(
      Future<AdminUserModel> Function() call, {
        int? removePendingUserId,
        bool refreshHistory = false,
      }) async {
    if (actionLoading) {
      return null;
    }

    actionLoading = true;

    errorMessage = null;

    try {
      final updated = await call();

      final existing = _knownAccounts[updated.id];

      if (existing != null) {
        _knownAccounts[updated.id] = existing.withUser(
          updated,
        );
      }

      for (var i = 0; i < pendingPilots.length; i++) {
        if (pendingPilots[i].user.id == updated.id) {
          pendingPilots[i] = pendingPilots[i].copyWithUser(
            updated,
          );
        }
      }

      for (var i = 0; i < pendingCompanies.length; i++) {
        if (pendingCompanies[i].user.id == updated.id) {
          pendingCompanies[i] = pendingCompanies[i].copyWithUser(
            updated,
          );
        }
      }

      for (var i = 0; i < allCompanies.length; i++) {
        if (allCompanies[i].user.id == updated.id) {
          allCompanies[i] = allCompanies[i].copyWithUser(
            updated,
          );
        }
      }

      if (removePendingUserId != null) {
        pendingPilots.removeWhere(
              (item) => item.user.id == removePendingUserId,
        );

        pendingCompanies.removeWhere(
              (item) => item.user.id == removePendingUserId,
        );
      }

      if (refreshHistory) {
        await _refreshHistoryForUser(
          updated.id,
        );
      }

      return updated;
    } catch (e) {
      errorMessage = e.toString();

      return null;
    } finally {
      actionLoading = false;
    }
  }
}
