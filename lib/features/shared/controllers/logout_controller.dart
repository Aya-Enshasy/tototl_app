import 'package:flutter/foundation.dart';

import '../../../core/storage/token_storage.dart';
import '../../../core/network/request_error_message.dart';
import '../../../core/notifications/push_notification_coordinator.dart';

import '../../../core/storage/user_session_storage.dart';
import '../services/logout_service.dart';

// ============================================================================
// LOGOUT CONTROLLER
// ============================================================================

class LogoutController {
  final LogoutService service;

  LogoutController(this.service);

  void _debugLog(String event) {
    if (kDebugMode) debugPrint('[logout][controller] $event');
  }

  bool isLoading = false;
  String? errorMessage;

  Future<bool> logout() async {
    if (isLoading) {
      _debugLog('skipped reason=request-already-running');
      return false;
    }

    isLoading = true;
    errorMessage = null;

    try {
      _debugLog('start');
      final response = await service.logout();

      if (!response.success) {
        _debugLog('server-rejected success=false; clearing-local-session');
        await _clearLocalSession();
        return true;
      }

      _debugLog('remote-confirmed clearing-local-session');
      await _clearLocalSession();

      _debugLog('complete local-session-cleared');

      return true;
    } catch (e) {
      // Logout is a user-directed LOCAL privacy action even if Laravel/Cloudflare
      // cannot revoke the remote token at this moment. Do not trap the user in
      // the account because of 503/timeouts. Discard the local token and data.
      _debugLog('remote-revocation-failed type=${e.runtimeType}; '
          'attempting-local-sign-out');
      try {
        await _clearLocalSession();
        _debugLog('local-sign-out-complete; remote-revocation-unconfirmed');
        return true;
      } catch (localError) {
        _debugLog('local-cleanup-failed type=${localError.runtimeType}');
        errorMessage = RequestErrorMessage.from(localError,
            fallback: 'Could not clear local account information. Please retry.');
        return false;
      }
    } finally {
      isLoading = false;
    }
  }

  Future<void> _clearLocalSession() async {
    await TokenStorage.clearTokens();
    _debugLog('local-tokens-cleared');
    await UserSessionStorage.clearSession();
    PushNotificationCoordinator.instance.onSignedOut();
    _debugLog('local-user-session-cleared');
  }
}
