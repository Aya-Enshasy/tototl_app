import 'admin_pending_company_model.dart';
import 'admin_pending_pilot_model.dart';
import 'admin_user_model.dart';

enum AdminAccountRole {
  pilot,
  company,
}

class AdminDirectoryEntry {
  final AdminAccountRole role;
  final AdminPendingPilotModel? pilot;
  final AdminPendingCompanyModel? company;

  const AdminDirectoryEntry._({
    required this.role,
    this.pilot,
    this.company,
  });

  factory AdminDirectoryEntry.pilot(
    AdminPendingPilotModel pilot,
  ) {
    return AdminDirectoryEntry._(
      role: AdminAccountRole.pilot,
      pilot: pilot,
    );
  }

  factory AdminDirectoryEntry.company(
    AdminPendingCompanyModel company,
  ) {
    return AdminDirectoryEntry._(
      role: AdminAccountRole.company,
      company: company,
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

  AdminDirectoryEntry withUser(
    AdminUserModel updatedUser,
  ) {
    if (isPilot) {
      return AdminDirectoryEntry.pilot(
        pilot!.copyWithUser(
          updatedUser,
        ),
      );
    }

    return AdminDirectoryEntry.company(
      company!.copyWithUser(
        updatedUser,
      ),
    );
  }
}
