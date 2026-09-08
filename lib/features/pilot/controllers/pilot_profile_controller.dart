import '../../auth/controllers/user_session_storage.dart';

import '../models/pilot_profile_model.dart';
import '../models/pilot_profile_update_model.dart';
import '../models/profile_document_model.dart';
import '../services/pilot_profile_service.dart';

class PilotProfileController {
  final PilotProfileService service;

  PilotProfileController(this.service);

  bool isUpdating = false;
  bool isUploadingPhoto = false;
  String? errorMessage;

  Future<PilotProfileViewData> _buildViewData(
      PilotProfileModel profile,
      ) async {
    final userJson =
    await UserSessionStorage.getUser();

    final photoUrl =
        await UserSessionStorage
            .getProfilePhotoUrl() ??
            '';

    final account = userJson == null
        ? const PilotAccountModel()
        : PilotAccountModel.fromJson(
      userJson,
    );

    return PilotProfileViewData(
      account: account,
      profile: profile,
      profilePhotoUrl: photoUrl,
    );
  }

  // ==========================================================================
  // LOCAL PROFILE
  // ==========================================================================

  Future<PilotProfileViewData?>
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

      final account = userJson == null
          ? const PilotAccountModel()
          : PilotAccountModel.fromJson(
        userJson,
      );

      final profile = profileJson == null
          ? const PilotProfileModel()
          : PilotProfileModel.fromJson(
        profileJson,
      );

      return PilotProfileViewData(
        account: account,
        profile: profile,
        profilePhotoUrl: photoUrl,
      );
    } catch (_) {
      return null;
    }
  }

  // ==========================================================================
  // REFRESH FROM GET /me
  // ==========================================================================

  Future<PilotProfileViewData?>
  refreshSilently() async {
    try {
      final freshProfile =
      await service.getMyProfile();

      // The service already caches the complete /me response.
      // Merge again instead of replacing so extra /me keys are preserved.
      await UserSessionStorage.mergeProfile(
        freshProfile.toJson(),
      );

      return _buildViewData(
        freshProfile,
      );
    } catch (_) {
      return null;
    }
  }

  // ==========================================================================
  // LOAD EDIT PROFILE
  // ==========================================================================

  Future<PilotProfileViewData?>
  loadEditProfile() async {
    errorMessage = null;

    final local =
    await loadLocalProfile();

    if (local != null) {
      return local;
    }

    try {
      final freshProfile =
      await service.getMyProfile();

      await UserSessionStorage.mergeProfile(
        freshProfile.toJson(),
      );

      return _buildViewData(
        freshProfile,
      );
    } catch (e) {
      errorMessage = e.toString();
      return null;
    }
  }

  // ==========================================================================
  // UPDATE PROFILE
  // ==========================================================================

  Future<PilotProfileViewData?>
  updateProfile(
      PilotProfileUpdateRequest request,
      ) async {
    if (isUpdating) {
      return null;
    }

    isUpdating = true;
    errorMessage = null;

    try {
      final freshProfile =
      await service.updateMyProfile(
        request,
      );

      // Do not replace the entire cached /me profile.
      // This keeps profile_photo, drones, licenses and any other /me-only keys.
      final cacheData =
      freshProfile.toJson();

      cacheData.addAll(
        request.toJson(),
      );

      await UserSessionStorage.mergeProfile(
        cacheData,
      );

      return _buildViewData(
        freshProfile,
      );
    } catch (e) {
      errorMessage = e.toString();
      return null;
    } finally {
      isUpdating = false;
    }
  }

  // ==========================================================================
  // PROFILE PHOTO
  // ==========================================================================

  Future<ProfileDocumentModel?>
  uploadProfilePhoto({
    required String filePath,
  }) async {
    if (isUploadingPhoto) {
      return null;
    }

    isUploadingPhoto = true;
    errorMessage = null;

    try {
      final document =
      await service.uploadProfilePhoto(
        filePath: filePath,
      );

      await UserSessionStorage
          .updateProfilePhotoUrl(
        document.url,
      );

      // Also keep the direct profile_photo key aligned with GET /me format.
      await UserSessionStorage.mergeProfile(
        {
          'profile_photo': document.url,
        },
      );

      return document;
    } catch (e) {
      errorMessage = e.toString();
      return null;
    } finally {
      isUploadingPhoto = false;
    }
  }
}
