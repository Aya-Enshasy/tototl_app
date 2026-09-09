import '../../../core/storage/user_session_storage.dart';

import '../models/company_profile_model.dart';
import '../models/company_profile_update_model.dart';
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

  bool isRefreshing = false;
  bool isUpdating = false;

  // ==========================================================================
  // LOCAL PROFILE
  // ==========================================================================

  Future<CompanyProfileViewData?>
  loadLocalProfile() async {
    try {
      final userJson =
      await UserSessionStorage.getUser();

      final profileJson =
      await UserSessionStorage.getProfile();

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
          : CompanyAccountModel.fromJson(
        userJson,
      );

      final profile =
      profileJson == null
          ? const CompanyProfileModel()
          : CompanyProfileModel.fromJson(
        profileJson,
      );

      return CompanyProfileViewData(
        account: account,
        profile: profile,
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
    await UserSessionStorage.getUser();

    final photoUrl =
        await UserSessionStorage
            .getProfilePhotoUrl() ??
            '';

    final account =
    userJson == null
        ? const CompanyAccountModel()
        : CompanyAccountModel.fromJson(
      userJson,
    );

    return CompanyProfileViewData(
      account: account,
      profile: profile,
      profilePhotoUrl:
      photoUrl.isNotEmpty
          ? photoUrl
          : profile.profilePhoto,
    );
  }

  // ==========================================================================
  // READ MERGED CACHED PROFILE
  // ==========================================================================

  Future<CompanyProfileModel>
  _readMergedProfile(
      CompanyProfileModel fallback,
      ) async {
    final mergedJson =
    await UserSessionStorage.getProfile();

    if (mergedJson == null) {
      return fallback;
    }

    return CompanyProfileModel.fromJson(
      mergedJson,
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

    isRefreshing = true;
    errorMessage = null;

    try {
      final freshProfile =
      await service.getMyProfile();

      // mergeProfile preserves local keys that are NOT returned by GET,
      // such as profile_photo and possibly work_regions.
      await UserSessionStorage.mergeProfile(
        freshProfile.toJson(),
      );

      final mergedProfile =
      await _readMergedProfile(
        freshProfile,
      );

      return await _buildViewData(
        mergedProfile,
      );
    } catch (e) {
      errorMessage = e.toString();
      return null;
    } finally {
      isRefreshing = false;
    }
  }

  // ==========================================================================
  // LOAD PROFILE
  //
  // API first. If API fails, return local data.
  // ==========================================================================

  Future<CompanyProfileViewData?>
  loadFreshProfile() async {
    errorMessage = null;

    try {
      final freshProfile =
      await service.getMyProfile();

      await UserSessionStorage.mergeProfile(
        freshProfile.toJson(),
      );

      final mergedProfile =
      await _readMergedProfile(
        freshProfile,
      );

      return await _buildViewData(
        mergedProfile,
      );
    } catch (e) {
      errorMessage = e.toString();

      return await loadLocalProfile();
    }
  }

  // ==========================================================================
  // LOAD EDIT PROFILE
  //
  // Local first for the edit screen.
  // ==========================================================================

  Future<CompanyProfileViewData?>
  loadEditProfile() async {
    errorMessage = null;

    final local =
    await loadLocalProfile();

    if (local != null) {
      return local;
    }

    return await loadFreshProfile();
  }

  // ==========================================================================
  // UPDATE PROFILE
  // ==========================================================================

  Future<CompanyProfileViewData?>
  updateProfile(
      CompanyProfileUpdateRequest request,
      ) async {
    if (isUpdating) {
      return null;
    }

    isUpdating = true;
    errorMessage = null;

    try {
      final updatedProfile =
      await service.updateMyProfile(
        request,
      );

      // IMPORTANT:
      // PATCH response may not return work_regions.
      // Start with response values, then apply exactly what the user submitted.
      final cacheData =
      updatedProfile.toJson();

      cacheData.addAll(
        request.toJson(),
      );

      // Preserve unrelated local-only values such as profile_photo.
      await UserSessionStorage.mergeProfile(
        cacheData,
      );

      final mergedProfile =
      await _readMergedProfile(
        updatedProfile,
      );

      return await _buildViewData(
        mergedProfile,
      );
    } catch (e) {
      errorMessage = e.toString();
      return null;
    } finally {
      isUpdating = false;
    }
  }
}
