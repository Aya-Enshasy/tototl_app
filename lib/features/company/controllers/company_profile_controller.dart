import '../../auth/controllers/user_session_storage.dart';

import '../models/company_profile_model.dart';
import '../services/company_profile_service.dart';

// ============================================================================
// COMPANY PROFILE CONTROLLER
// ============================================================================

class CompanyProfileController {
  final CompanyProfileService service;

  CompanyProfileController(
      this.service,
      );

  String? errorMessage;

  bool isRefreshing =
  false;

  // ==========================================================================
  // LOCAL PROFILE
  // ==========================================================================

  Future<CompanyProfileViewData?>
  loadLocalProfile() async {
    try {
      final userJson =
      await UserSessionStorage
          .getUser();

      final profileJson =
      await UserSessionStorage
          .getProfile();

      final photoUrl =
          await UserSessionStorage
              .getProfilePhotoUrl() ??
              '';

      if (userJson == null &&
          profileJson == null) {
        return null;
      }

      final account =
      userJson == null
          ? const CompanyAccountModel()
          : CompanyAccountModel
          .fromJson(
        userJson,
      );

      final profile =
      profileJson == null
          ? const CompanyProfileModel()
          : CompanyProfileModel
          .fromJson(
        profileJson,
      );

      return CompanyProfileViewData(
        account:
        account,

        profile:
        profile,

        profilePhotoUrl:
        photoUrl.isNotEmpty
            ? photoUrl
            : profile.profilePhoto,
      );
    } catch (_) {
      return null;
    }
  }

  // ==========================================================================
  // BUILD VIEW DATA
  // ==========================================================================

  Future<CompanyProfileViewData>
  _buildViewData(
      CompanyProfileModel profile,
      ) async {
    final userJson =
    await UserSessionStorage
        .getUser();

    final photoUrl =
        await UserSessionStorage
            .getProfilePhotoUrl() ??
            '';

    final account =
    userJson == null
        ? const CompanyAccountModel()
        : CompanyAccountModel
        .fromJson(
      userJson,
    );

    return CompanyProfileViewData(
      account:
      account,

      profile:
      profile,

      profilePhotoUrl:
      photoUrl.isNotEmpty
          ? photoUrl
          : profile.profilePhoto,
    );
  }

  // ==========================================================================
  // REFRESH SILENTLY
  // ==========================================================================

  Future<CompanyProfileViewData?>
  refreshSilently() async {
    if (isRefreshing) {
      return null;
    }

    isRefreshing =
    true;

    errorMessage =
    null;

    try {
      final freshProfile =
      await service
          .getMyProfile();

      // Keep cached values such as profile_photo
      // if GET profile does not return them.
      await UserSessionStorage
          .mergeProfile(
        freshProfile.toJson(),
      );

      // Re-read merged profile from local storage.
      final mergedJson =
      await UserSessionStorage
          .getProfile();

      final mergedProfile =
      mergedJson == null
          ? freshProfile
          : CompanyProfileModel
          .fromJson(
        mergedJson,
      );

      return await _buildViewData(
        mergedProfile,
      );
    } catch (e) {
      errorMessage =
          e.toString();

      return null;
    } finally {
      isRefreshing =
      false;
    }
  }

  // ==========================================================================
  // LOAD PROFILE
  //
  // For screens where you explicitly want API first.
  // ==========================================================================

  Future<CompanyProfileViewData?>
  loadFreshProfile() async {
    errorMessage =
    null;

    try {
      final freshProfile =
      await service
          .getMyProfile();

      await UserSessionStorage
          .mergeProfile(
        freshProfile.toJson(),
      );

      final mergedJson =
      await UserSessionStorage
          .getProfile();

      final profile =
      mergedJson == null
          ? freshProfile
          : CompanyProfileModel
          .fromJson(
        mergedJson,
      );

      return await _buildViewData(
        profile,
      );
    } catch (e) {
      errorMessage =
          e.toString();

      return await loadLocalProfile();
    }
  }
}