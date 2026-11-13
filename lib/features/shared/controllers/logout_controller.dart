import 'package:flutter/foundation.dart';

import '../../../core/storage/token_storage.dart';

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
        _debugLog('server-rejected success=false');
        errorMessage = response.message.isNotEmpty
            ? response.message
            : 'Unable to sign out.';

        return false;
      }

      _debugLog('remote-confirmed clearing-local-session');
      await _clearLocalSession();

      _debugLog('complete local-session-cleared');

      return true;
    } catch (e) {
      _debugLog('failed exceptionType=${e.runtimeType}');
      errorMessage = e.toString();
      return false;
    } finally {
      isLoading = false;
    }
  }

  Future<void> _clearLocalSession() async {
    await TokenStorage.clearTokens();
    _debugLog('local-tokens-cleared');
    await UserSessionStorage.clearSession();
    _debugLog('local-user-session-cleared');
  }
}
