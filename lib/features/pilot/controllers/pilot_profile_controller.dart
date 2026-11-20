import '../../../core/storage/user_session_storage.dart';

import '../models/pilot_profile_model.dart';
import '../models/pilot_profile_update_model.dart';
import '../models/profile_document_model.dart';
import '../services/pilot_profile_service.dart';
import '../services/pilot_profile_sync.dart';

class PilotProfileController {
  final PilotProfileService service;

  PilotProfileController(this.service);

  bool isUpdating = false;
  bool isUploadingPhoto = false;
  String? errorMessage;

  Future<PilotProfileViewData> _buildViewData(
    PilotProfileModel profile,
  ) async {
    final session = await UserSessionStorage.getSession();
    final rawUser = session?['user'];
    final userJson = rawUser is Map
        ? Map<String, dynamic>.from(rawUser)
        : null;
    final account = userJson == null
        ? const PilotAccountModel()
        : PilotAccountModel.fromJson(userJson);
    final rawProfile = session?['profile'];
    final photoUrl = session?['profile_photo_url']?.toString() ??
        (rawProfile is Map ? rawProfile['profile_photo']?.toString() : null) ?? '';
    return PilotProfileViewData(
      account: account,
      profile: profile,
      profilePhotoUrl: photoUrl,
    );
  }

  // ==========================================================================
  // LOCAL PROFILE
  // ==========================================================================

  Future<PilotProfileViewData?> loadLocalProfile() async {
    try {
      // One encrypted session snapshot, not three separate storage reads.
      final session = await UserSessionStorage.getSession();
      // Login can return only user + role; /me may be delayed or offline.
      // Keep the real account header visible immediately rather than showing
      // a full-screen "Profile unavailable" error for a valid pilot session.
      final role = session?['role']?.toString().toLowerCase().trim();
      if (role != 'pilot') return null;
      final rawUser = session?['user'];
      if (rawUser is! Map || rawUser.isEmpty) return null;
      final account = PilotAccountModel.fromJson(
        Map<String, dynamic>.from(rawUser),
      );
      if (account.id == null || account.id! <= 0) return null;
      final rawProfile = session?['profile'];
      final profile = rawProfile is Map && rawProfile.isNotEmpty
          ? PilotProfileModel.fromJson(Map<String, dynamic>.from(rawProfile))
          : PilotProfileModel(userId: account.id);
      final photoUrl = session?['profile_photo_url']?.toString() ??
          (rawProfile is Map ? rawProfile['profile_photo']?.toString() : null) ?? '';
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
  refreshSilently({bool force = false}) async {
    // Shared request started at splash/login/registration, if any. Always
    // return the saved account/profile even when the API is unavailable.
    await PilotProfileSync.instance.refreshFromApi(force: force);
    return loadLocalProfile();
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
