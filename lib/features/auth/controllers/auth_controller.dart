import 'package:dio/dio.dart';
import '../services/auth_service.dart';
import '../../../core/storage/token_storage.dart';

class AuthController {
  final AuthService authService;

  AuthController(this.authService);

  bool isLoading = false;

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    try {
      isLoading = true;

      final response = await authService.login(
        email: email,
        password: password,
      );

      final accessToken = response.data['access_token'];
      final refreshToken = response.data['refresh_token'];

      await TokenStorage.saveTokens(
        accessToken: accessToken,
        refreshToken: refreshToken,
      );

      return true;
    } on DioException catch (e) {
      print(e.response?.data);
      return false;
    } finally {
      isLoading = false;
    }
  }
}