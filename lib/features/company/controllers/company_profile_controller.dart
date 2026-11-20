import 'package:tototl_app/core/storage/user_session_storage.dart';

import '../models/company_profile_model.dart';
import '../models/company_profile_update_model.dart';
import '../services/company_profile_service.dart';

class CompanyProfileController {
  final CompanyProfileService service;

  CompanyProfileController(this.service);

  String? errorMessage;
  static final Map<int, DateTime> _lastSuccessfulRefreshByUser = {};


  bool isRefreshing = false;
  bool isUpdating = false;
  bool isUploadingPhoto = false;

  Future<CompanyProfileViewData?> loadLocalProfile() async {
    try {
      final session = await UserSessionStorage.getSession();
      final rawUser = session?['user'];
      final rawProfile = session?['profile'];
      if (rawProfile is! Map || rawProfile.isEmpty) return null;
      final account = rawUser is Map
          ? CompanyAccountModel.fromJson(Map<String, dynamic>.from(rawUser))
          : const CompanyAccountModel();
      final profile = rawProfile is Map
          ? CompanyProfileModel.fromJson(Map<String, dynamic>.from(rawProfile))
          : const CompanyProfileModel();
      final cachedPhoto = session?['profile_photo_url']?.toString() ?? '';
      return CompanyProfileViewData(
        account: account,
        profile: profile,
        profilePhotoUrl: cachedPhoto.isNotEmpty
            ? cachedPhoto
            : profile.profilePhoto,
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

  Future<CompanyProfileViewData?> refreshSilently({bool force = false}) async {
    if (isRefreshing) return null;
    final userId = await UserSessionStorage.getUserId();
    final last = userId == null ? null : _lastSuccessfulRefreshByUser[userId];
    if (!force && last != null &&
        DateTime.now().difference(last) < const Duration(minutes: 3)) {
      return loadLocalProfile();
    }

    isRefreshing = true;
    errorMessage = null;

    try {
      final freshProfile = await service.getMyProfile();
      if (userId != await UserSessionStorage.getUserId()) return null;

      // Preserve local-only values such as profile_photo and work_regions when
      // the GET response does not return them.
      await UserSessionStorage.mergeProfile(freshProfile.toJson());

      final mergedProfile = await _readMergedProfile(freshProfile);
      if (userId != null) _lastSuccessfulRefreshByUser[userId] = DateTime.now();
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
    final owner = await UserSessionStorage.getUserId();
    try {
      final freshProfile = await service.getMyProfile();
      if (owner != await UserSessionStorage.getUserId()) return null;
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
    final owner = await UserSessionStorage.getUserId();

    try {
      final updatedProfile = await service.updateMyProfile(request);
      if (owner != await UserSessionStorage.getUserId()) return null;

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
      final url = await service.uploadProfilePhoto(
        filePath: filePath,
      );

      final cleanUrl = url.trim();

      if (cleanUrl.isEmpty) {
        throw Exception('Profile photo URL is missing.');
      }

      // Same behavior as Pilot:
      // 1) persist the direct photo URL for the fastest first paint;
      // 2) keep profile_photo aligned with the profile shape.
      //
      // Both writes trigger UserSessionStorage.revision, so Company Home
      // refreshes the avatar automatically while it is mounted.
      await UserSessionStorage.updateProfilePhotoUrl(
        cleanUrl,
      );

      await UserSessionStorage.mergeProfile({
        'profile_photo': cleanUrl,
      });

      return await loadLocalProfile();
    } catch (e) {
      errorMessage = e.toString();
      return null;
    } finally {
      isUploadingPhoto = false;
    }
  }
}
