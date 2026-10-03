import 'package:tototl_app/core/network/api_client.dart';
import 'package:tototl_app/core/storage/user_session_storage.dart';

import 'company_profile_service.dart';

/// Silent company-profile network synchronizer.
///
/// The UI always paints cached login/register data first. This class only
/// refreshes the authoritative profile in the background and writes it back to
/// [UserSessionStorage]. The storage revision notifier then updates mounted
/// screens automatically.
class CompanyProfileSync {
  CompanyProfileSync._();

  static final CompanyProfileSync instance = CompanyProfileSync._();

  Future<bool>? _inFlight;
  DateTime? _lastSuccessfulRefresh;

  static const Duration _freshnessWindow = Duration(seconds: 5);

  String? lastError;

  Future<bool> refreshFromApi({
    bool force = false,
  }) {
    final running = _inFlight;
    if (running != null) return running;

    final last = _lastSuccessfulRefresh;
    if (!force &&
        last != null &&
        DateTime.now().difference(last) < _freshnessWindow) {
      return Future<bool>.value(true);
    }

    final future = _refresh();
    _inFlight = future;

    future.whenComplete(() {
      if (identical(_inFlight, future)) {
        _inFlight = null;
      }
    });

    return future;
  }

  Future<bool> _refresh() async {
    lastError = null;

    try {
      final fresh =
      await CompanyProfileService(ApiClient()).getMyProfile();

      // Preserve cached keys omitted by partial GET responses.
      await UserSessionStorage.mergeProfile(
        fresh.toJson(),
      );

      // Keep the top-level photo cache consistent because profile screens use
      // it for the fastest first paint.
      final photo = fresh.profilePhoto.trim();
      if (photo.isNotEmpty) {
        await UserSessionStorage.updateProfilePhotoUrl(photo);
      }

      _lastSuccessfulRefresh = DateTime.now();
      return true;
    } catch (e) {
      // Never block login/home because a background refresh failed.
      lastError = e.toString();
      return false;
    }
  }
}
