import 'admin_pending_company_model.dart';
import 'admin_pending_pilot_model.dart';
import 'admin_user_model.dart';
import 'admin_verification_history_model.dart';

enum AdminAccountRole {
  pilot,
  company,
}

class AdminDirectoryEntry {
  final AdminAccountRole role;
  final AdminPendingPilotModel? pilot;
  final AdminPendingCompanyModel? company;

  final List<AdminVerificationHistoryModel>
      verificationHistory;

  const AdminDirectoryEntry._({
    required this.role,
    this.pilot,
    this.company,
    this.verificationHistory = const [],
  });

  factory AdminDirectoryEntry.pilot(
    AdminPendingPilotModel pilot, {
    List<AdminVerificationHistoryModel>
        verificationHistory = const [],
  }) {
    return AdminDirectoryEntry._(
      role: AdminAccountRole.pilot,
      pilot: pilot,
      verificationHistory:
          verificationHistory,
    );
  }

  factory AdminDirectoryEntry.company(
    AdminPendingCompanyModel company, {
    List<AdminVerificationHistoryModel>
        verificationHistory = const [],
  }) {
    return AdminDirectoryEntry._(
      role: AdminAccountRole.company,
      company: company,
      verificationHistory:
          verificationHistory,
    );
  }

  AdminUserModel get user {
    if (role == AdminAccountRole.pilot) {
      return pilot!.user;
    }

    return company!.user;
  }

  int get id => user.id;

  bool get isPilot =>
      role == AdminAccountRole.pilot;

  bool get isCompany =>
      role == AdminAccountRole.company;

  String get roleLabel =>
      isPilot ? 'Pilot' : 'Company';

  String get title {
    if (isPilot) {
      return pilot!.user.displayName;
    }

    return company!.displayCompanyName;
  }

  String get subtitle {
    if (isPilot) {
      return pilot!.profile.locationLabel;
    }

    final industry =
        company!.profile.industryType.trim();

    if (industry.isNotEmpty) {
      return industry;
    }

    return company!.profile.locationLabel;
  }

  String get searchableText {
    if (isPilot) {
      return pilot!.searchableText;
    }

    return company!.searchableText;
  }

  List<AdminVerificationHistoryModel>
      get sortedHistory {
    final items =
        List<AdminVerificationHistoryModel>.from(
      verificationHistory,
    );

    items.sort(
      (a, b) {
        final aDate =
            a.createdAt ??
            DateTime.fromMillisecondsSinceEpoch(
              0,
            );

        final bDate =
            b.createdAt ??
            DateTime.fromMillisecondsSinceEpoch(
              0,
            );

        return bDate.compareTo(aDate);
      },
    );

    return items;
  }

  AdminVerificationHistoryModel?
      get latestHistoryAction {
    final items =
        sortedHistory;

    if (items.isEmpty) {
      return null;
    }

    return items.first;
  }

  String get latestAction {
    return latestHistoryAction
            ?.normalizedAction ??
        '';
  }

  String get effectiveStatus {
    switch (latestAction) {
      case 'approved':
        return 'active';

      case 'rejected':
        return 'rejected';

      case 'suspended':
        return 'suspended';

      case 'reactivated':
      case 'reactivate':
        return 'active';

      default:
        return user.normalizedStatus;
    }
  }

  bool get isEffectivelyPending =>
      effectiveStatus == 'pending';

  bool get isEffectivelyActive =>
      effectiveStatus == 'active' ||
      effectiveStatus == 'approved' ||
      effectiveStatus == 'verified';

  bool get isEffectivelySuspended =>
      effectiveStatus == 'suspended';

  bool get isEffectivelyRejected =>
      effectiveStatus == 'rejected';

  String get latestReason {
    final value =
        latestHistoryAction?.reason.trim() ??
        '';

    return value;
  }

  DateTime? get latestActionAt =>
      latestHistoryAction?.createdAt;

  AdminDirectoryEntry withUser(
    AdminUserModel updatedUser,
  ) {
    if (isPilot) {
      return AdminDirectoryEntry.pilot(
        pilot!.copyWithUser(
          updatedUser,
        ),
        verificationHistory:
            verificationHistory,
      );
    }

    return AdminDirectoryEntry.company(
      company!.copyWithUser(
        updatedUser,
      ),
      verificationHistory:
          verificationHistory,
    );
  }

  AdminDirectoryEntry withHistory(
    List<AdminVerificationHistoryModel>
        history,
  ) {
    if (isPilot) {
      return AdminDirectoryEntry.pilot(
        pilot!,
        verificationHistory:
            history,
      );
    }

    return AdminDirectoryEntry.company(
      company!,
      verificationHistory:
          history,
    );
  }
}
