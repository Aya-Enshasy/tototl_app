import 'package:flutter/foundation.dart';

import '../../../core/network/api_client.dart';
import '../../../core/storage/user_session_storage.dart';
import 'pilot_profile_service.dart';

/// Session-scoped profile bootstrap shared by splash, login, registration and
/// the pilot profile screen. A failed /me request never deletes saved data.
/// Requests for the same account are coalesced, avoiding needless 429s.
class PilotProfileSync {
  PilotProfileSync._();
  static final PilotProfileSync instance = PilotProfileSync._();

  Future<bool>? _inFlight;
  int? _inFlightOwner;
  final Map<int, DateTime> _lastSuccessByOwner = {};
  static const _freshness = Duration(minutes: 2);

  Future<bool> refreshFromApi({bool force = false}) async {
    final owner = await UserSessionStorage.getUserId();
    final role = (await UserSessionStorage.getRole())?.toLowerCase().trim();
    if (owner == null || owner <= 0 || role != 'pilot') return false;

    final active = _inFlight;
    if (active != null && _inFlightOwner == owner) return active;

    final last = _lastSuccessByOwner[owner];
    if (!force && last != null &&
        DateTime.now().difference(last) < _freshness) {
      return true;
    }

    final task = _refreshOwner(owner);
    _inFlight = task;
    _inFlightOwner = owner;
    // Both branches are handled: no unobserved future exception on failure.
    task.then((_) => _clear(task), onError: (Object _, StackTrace __) => _clear(task));
    return task;
  }

  void _clear(Future<bool> task) {
    if (identical(_inFlight, task)) {
      _inFlight = null;
      _inFlightOwner = null;
    }
  }

  Future<bool> _refreshOwner(int owner) async {
    try {
      // getMyProfile saves the complete /me account, profile and photo to the
      // encrypted per-account session cache. It checks the session owner.
      await PilotProfileService(ApiClient()).getMyProfile();
      if (owner != await UserSessionStorage.getUserId()) return false;
      _lastSuccessByOwner[owner] = DateTime.now();
      return true;
    } catch (error) {
      if (kDebugMode) {
        debugPrint('[TOTOTL][PILOT_PROFILE][REFRESH] '
            'using saved profile; error=${error.runtimeType}');
      }
      return false;
    }
  }
}
