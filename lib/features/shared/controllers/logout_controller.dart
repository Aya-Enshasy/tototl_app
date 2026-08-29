import '../../../core/storage/token_storage.dart';

import '../../auth/controllers/user_session_storage.dart';
 import '../services/logout_service.dart';

// ============================================================================
// LOGOUT CONTROLLER
// ============================================================================

class LogoutController {
  final LogoutService service;

  LogoutController(this.service);

  bool isLoading = false;
  String? errorMessage;

  Future<bool> logout() async {
    if (isLoading) {
      return false;
    }

    isLoading = true;
    errorMessage = null;

    try {
      final response = await service.logout();

      if (!response.success) {
        errorMessage = response.message.isNotEmpty
            ? response.message
            : 'Unable to sign out.';

        return false;
      }

      await _clearLocalSession();

      return true;
    } catch (e) {
      errorMessage = e.toString();
      return false;
    } finally {
      isLoading = false;
    }
  }

  Future<void> _clearLocalSession() async {
    await TokenStorage.clearTokens();
    await UserSessionStorage.clearSession();
  }
}
