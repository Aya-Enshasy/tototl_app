import 'package:dio/dio.dart';
import 'package:tototl_app/core/network/api_client.dart';
import 'package:tototl_app/core/network/api_endpoints.dart';

import '../models/LoginResponseModel.dart';

class AuthService {
  final ApiClient apiClient;

  AuthService(this.apiClient);

  // ============================================================
  // LOGIN
  // ============================================================

  Future<LoginResponseModel> login({
    required String email,
    required String password,
  }) async {
    final response = await apiClient.post(
      ApiEndpoints.login,
      data: {
        'login': email,
        'password': password,
        'fcm_token': '',
        'apn_token': '',
        'device_type': 'android',
      },
    );

    return LoginResponseModel.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  // ============================================================
  // PILOT REGISTER
  // ============================================================

  Future<Response> registerPilot({
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
    final formData = FormData.fromMap({
      'name': name,
      'email': email,
      'password': password,
      'password_confirmation': passwordConfirmation,

      if (username != null && username.isNotEmpty)
        'username': username,

      if (phone != null && phone.isNotEmpty)
        'phone': phone,

      if (dateOfBirth != null && dateOfBirth.isNotEmpty)
        'date_of_birth': dateOfBirth,

      if (nationality != null && nationality.isNotEmpty)
        'nationality': nationality,

      if (linkedinUrl != null && linkedinUrl.isNotEmpty)
        'linkedin_url': linkedinUrl,

      'fcm_token': '',
      'apn_token': '',
      'device_type': 'android',

      if (imagePath != null && imagePath.isNotEmpty)
        'image': await MultipartFile.fromFile(
          imagePath,
          filename: imagePath.split('/').last,
        ),
    });

    return await apiClient.post(
      ApiEndpoints.pilotRegister,
      data: formData,
    );
  }
}