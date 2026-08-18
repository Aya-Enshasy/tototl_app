import 'package:dio/dio.dart';
import '../models/LoginResponseModel.dart';
import '../services/auth_service.dart';
import '../../../core/storage/token_storage.dart';

class AuthController {
  final AuthService authService;

  AuthController(this.authService);

  bool isLoading = false;
  String? errorMessage;
// login function
  Future<LoginResponseModel?> login({
    required String email,
    required String password,
  }) async {
    try {
      isLoading = true;
      errorMessage = null;

      final response = await authService.login(
        email: email,
        password: password,
      );

      if (!response.success || response.data == null) {
        errorMessage = response.message;
        return null;
      }

      final token = response.data!.token;

      await TokenStorage.saveTokens(
        accessToken: token,
      );

      return response;
    } on DioException catch (e) {
      final data = e.response?.data;

      if (data is Map<String, dynamic>) {
        errorMessage =
            data['message']?.toString() ?? 'Login failed.';
      } else {
        errorMessage = 'Login failed. Please try again.';
      }

      print('Login error: ${e.response?.data}');

      return null;
    } catch (e) {
      errorMessage = 'Something went wrong.';
      print('Login error: $e');

      return null;
    } finally {
      isLoading = false;
    }
  }

  // pilot register function
  Future<Response?> pilotRegister({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,

    String? username,
    String? phone,
    String? dateOfBirth,
    String? nationality,
    String? linkedinUrl,
    String? imagePath,
  }) async {
    try {
      isLoading = true;
      errorMessage = null;

      final response = await authService.registerPilot(
        name: name,
        email: email,
        password: password,
        passwordConfirmation: passwordConfirmation,

        username: username,
        phone: phone,
        dateOfBirth: dateOfBirth,
        nationality: nationality,
        linkedinUrl: linkedinUrl,

        imagePath: imagePath,
      );

      // لو الـ API رجع token بعد التسجيل نخزنه
      final responseData = response.data;

      if (responseData is Map<String, dynamic>) {
        final data = responseData['data'];

        if (data is Map<String, dynamic>) {
          final token = data['token']?.toString();

          if (token != null && token.isNotEmpty) {
            await TokenStorage.saveTokens(
              accessToken: token,
            );
          }
        }
      }

      return response;
    } on DioException catch (e) {
      final data = e.response?.data;

      if (data is Map<String, dynamic>) {
        errorMessage =
            data['message']?.toString() ??
                'Registration failed.';
      } else {
        errorMessage =
        'Registration failed. Please try again.';
      }

      print('Pilot registration error: ${e.response?.data}');
      print('Status Code: ${e.response?.statusCode}');

      return null;
    } catch (e) {
      errorMessage = 'Something went wrong.';
      print('Pilot registration error: $e');

      return null;
    } finally {
      isLoading = false;
    }
  }
}