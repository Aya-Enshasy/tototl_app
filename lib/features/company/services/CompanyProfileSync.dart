import 'package:tototl_app/core/network/api_client.dart';
import 'package:tototl_app/core/storage/user_session_storage.dart';

import 'company_profile_service.dart';

/// Uses the persisted per-account snapshot for first paint and refreshes
/// it in the background. No failed request is allowed to erase the cache.
class CompanyProfileSync {
  CompanyProfileSync._();
  static final CompanyProfileSync instance = CompanyProfileSync._();

  Future<bool>? _inFlight;
  int? _inFlightUserId;
  final Map<int, DateTime> _refreshedAtByUser = {};
  static const Duration _freshnessWindow = Duration(minutes: 2);

  String? lastError;

  Future<bool> refreshFromApi({bool force = false}) async {
    final userId = await UserSessionStorage.getUserId();
    if (userId == null || userId <= 0) return false;
    final running = _inFlight;
    if (running != null && _inFlightUserId == userId) return running;

    final last = _refreshedAtByUser[userId];
    if (!force && last != null &&
        DateTime.now().difference(last) < _freshnessWindow) {
      return true;
    }

    final future = _refresh(userId);
    _inFlight = future;
    _inFlightUserId = userId;
    future.whenComplete(() {
      if (identical(_inFlight, future)) {
        _inFlight = null;
        _inFlightUserId = null;
      }
    });
    return future;
  }

  Future<bool> _refresh(int userId) async {
    lastError = null;
    try {
      final fresh = await CompanyProfileService(ApiClient()).getMyProfile();
      // Account switching/logging out during a request must not write the
      // former company's profile into the new session.
      if (userId != await UserSessionStorage.getUserId()) return false;
      await UserSessionStorage.mergeProfile(fresh.toJson());
      if (userId != await UserSessionStorage.getUserId()) return false;
      final photo = fresh.profilePhoto.trim();
      if (photo.isNotEmpty) {
        await UserSessionStorage.updateProfilePhotoUrl(photo);
      }
      _refreshedAtByUser[userId] = DateTime.now();
      return true;
    } catch (e) {
      lastError = e.runtimeType.toString();
      return false;
    }
  }
}
