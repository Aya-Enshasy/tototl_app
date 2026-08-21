import '../../auth/controllers/user_session_storage.dart';

import '../models/pilot_profile_model.dart';
import '../services/pilot_profile_service.dart';

class PilotProfileController {
  final PilotProfileService service;

  PilotProfileController(
      this.service,
      );

  // ============================================================
  // LOCAL FIRST
  //
  // No API request here.
  // ============================================================

  Future<PilotProfileViewData?>
  loadLocalProfile() async {
    final userJson =
    await UserSessionStorage
        .getUser();

    final profileJson =
    await UserSessionStorage
        .getProfile();

    if (userJson == null &&
        profileJson == null) {
      return null;
    }

    final account =
    userJson == null
        ? const PilotAccountModel()
        : PilotAccountModel
        .fromJson(
      userJson,
    );

    final profile =
    profileJson == null
        ? const PilotProfileModel()
        : PilotProfileModel
        .fromJson(
      profileJson,
    );

    return PilotProfileViewData(
      account: account,
      profile: profile,
    );
  }

  // ============================================================
  // BACKGROUND REFRESH
  //
  // Fetch server silently.
  // Save locally.
  // Return fresh data.
  // ============================================================

  Future<PilotProfileViewData?>
  refreshSilently() async {
    try {
      final freshProfile =
      await service
          .getMyProfile();

      // Update local cache quietly.
      await UserSessionStorage
          .updateProfile(
        freshProfile.toJson(),
      );

      // User is already stored locally.
      final userJson =
      await UserSessionStorage
          .getUser();

      final account =
      userJson == null
          ? const PilotAccountModel()
          : PilotAccountModel
          .fromJson(
        userJson,
      );

      return PilotProfileViewData(
        account: account,
        profile: freshProfile,
      );
    } catch (e) {
      // Deliberately silent.
      //
      // If internet is unavailable,
      // keep showing cached data.
      //
      // This is exactly what we want
      // for a local-first profile.
      return null;
    }
  }
}