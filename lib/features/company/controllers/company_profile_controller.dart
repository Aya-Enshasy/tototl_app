import '../../../core/storage/user_session_storage.dart';
import '../models/company_profile_model.dart';
import '../models/company_profile_update_model.dart';
import '../services/company_profile_service.dart';

class CompanyProfileController {
  final CompanyProfileService service;

  CompanyProfileController(this.service);

  String? errorMessage;

  bool isRefreshing = false;
  bool isUpdating = false;
  bool isUploadingPhoto = false;

  Future<CompanyProfileViewData?> loadLocalProfile() async {
    try {
      final userJson = await UserSessionStorage.getUser();
      final profileJson = await UserSessionStorage.getProfile();
      final photoUrl = await UserSessionStorage.getProfilePhotoUrl() ?? '';

      if (userJson == null && profileJson == null) return null;

      final account = userJson == null
          ? const CompanyAccountModel()
          : CompanyAccountModel.fromJson(userJson);

      final profile = profileJson == null
          ? const CompanyProfileModel()
          : CompanyProfileModel.fromJson(profileJson);

      return CompanyProfileViewData(
        account: account,
        profile: profile,
        profilePhotoUrl:
        photoUrl.isNotEmpty ? photoUrl : profile.profilePhoto,
      );
    } catch (_) {
      return null;
    }
  }

  Future<CompanyProfileViewData> _buildViewData(
      CompanyProfileModel profile,
      ) async {
    final userJson = await UserSessionStorage.getUser();
    final photoUrl = await UserSessionStorage.getProfilePhotoUrl() ?? '';

    final account = userJson == null
        ? const CompanyAccountModel()
        : CompanyAccountModel.fromJson(userJson);

    return CompanyProfileViewData(
      account: account,
      profile: profile,
      profilePhotoUrl:
      photoUrl.isNotEmpty ? photoUrl : profile.profilePhoto,
    );
  }

  Future<CompanyProfileModel> _readMergedProfile(
      CompanyProfileModel fallback,
      ) async {
    final mergedJson = await UserSessionStorage.getProfile();
    if (mergedJson == null) return fallback;
    return CompanyProfileModel.fromJson(mergedJson);
  }

  Future<CompanyProfileViewData?> refreshSilently() async {
    if (isRefreshing) return null;

    isRefreshing = true;
    errorMessage = null;

    try {
      final freshProfile = await service.getMyProfile();

      // Preserve local-only values such as profile_photo and work_regions when
      // the GET response does not return them.
      await UserSessionStorage.mergeProfile(freshProfile.toJson());

      final mergedProfile = await _readMergedProfile(freshProfile);
      return await _buildViewData(mergedProfile);
    } catch (e) {
      errorMessage = e.toString();
      return null;
    } finally {
      isRefreshing = false;
    }
  }

  Future<CompanyProfileViewData?> loadFreshProfile() async {
    errorMessage = null;

    try {
      final freshProfile = await service.getMyProfile();
      await UserSessionStorage.mergeProfile(freshProfile.toJson());
      final mergedProfile = await _readMergedProfile(freshProfile);
      return await _buildViewData(mergedProfile);
    } catch (e) {
      errorMessage = e.toString();
      return await loadLocalProfile();
    }
  }

  Future<CompanyProfileViewData?> loadEditProfile() async {
    errorMessage = null;
    final local = await loadLocalProfile();
    if (local != null) return local;
    return await loadFreshProfile();
  }

  Future<CompanyProfileViewData?> updateProfile(
      CompanyProfileUpdateRequest request,
      ) async {
    if (isUpdating) return null;

    isUpdating = true;
    errorMessage = null;

    try {
      final updatedProfile = await service.updateMyProfile(request);

      final cacheData = updatedProfile.toJson();
      cacheData.addAll(request.toJson());

      // Preserve unrelated local-only values such as profile_photo.
      await UserSessionStorage.mergeProfile(cacheData);

      final mergedProfile = await _readMergedProfile(updatedProfile);
      return await _buildViewData(mergedProfile);
    } catch (e) {
      errorMessage = e.toString();
      return null;
    } finally {
      isUpdating = false;
    }
  }

  Future<CompanyProfileViewData?> uploadProfilePhoto({
    required String filePath,
  }) async {
    if (isUploadingPhoto) return null;

    isUploadingPhoto = true;
    errorMessage = null;

    try {
      final url = await service.uploadProfilePhoto(filePath: filePath);

      // Keep the direct URL locally so the profile paints the new photo
      // immediately on the next visit, before the background API refresh.
      await UserSessionStorage.updateProfilePhotoUrl(url);
      await UserSessionStorage.mergeProfile({'profile_photo': url});

      return await loadLocalProfile();
    } catch (e) {
      errorMessage = e.toString();
      return null;
    } finally {
      isUploadingPhoto = false;
    }
  }
}
