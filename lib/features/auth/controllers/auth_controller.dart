import 'package:dio/dio.dart';
import 'package:tototl_app/features/auth/controllers/user_session_storage.dart';

import '../models/LoginResponseModel.dart';
import '../models/PilotRegisterRequestModel.dart';
import '../models/CompanyRegisterRequestModel.dart';
import '../services/auth_service.dart';

import '../../../core/storage/token_storage.dart';

class AuthController {
  final AuthService authService;

  AuthController(this.authService);

  bool isLoading = false;
  String? errorMessage;

  // ============================================================
  // LOGIN
  // ============================================================

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
        errorMessage = response.message.isNotEmpty
            ? response.message
            : 'Login failed.';
        return null;
      }

      final token = response.data!.token;

      if (token.isNotEmpty) {
        await TokenStorage.saveTokens(
          accessToken: token,
        );
      }

      return response;
    } on DioException catch (e) {
      errorMessage = _extractErrorMessage(
        e.response?.data,
        fallback: 'Login failed. Please try again.',
      );

      print('LOGIN ERROR STATUS: ${e.response?.statusCode}');
      print('LOGIN ERROR DATA: ${e.response?.data}');
      return null;
    } catch (e) {
      errorMessage = 'Something went wrong. Please try again.';
      print('LOGIN ERROR: $e');
      return null;
    } finally {
      isLoading = false;
    }
  }

  // ============================================================
  // PILOT REGISTER
  // ============================================================

  Future<Response<dynamic>?> pilotRegister({
    required PilotRegisterRequestModel request,
  }) async {
    try {
      isLoading = true;
      errorMessage = null;

      print('================================================');
      print('PILOT REGISTRATION STARTED');
      print('Name: ${request.name}');
      print('Email: ${request.email}');
      print('Username: ${request.username}');
      print('Phone: ${request.phone}');
      print('Nationality: ${request.nationality}');
      print('Date of Birth: ${request.dateOfBirth}');
      print('Experience Years: ${request.experienceYears}');
      print('Languages: ${request.languages}');
      print('Current Country: ${request.currentCountry}');
      print('Current State: ${request.currentState}');
      print('Current City: ${request.currentCity}');
      print('Work Regions Count: ${request.workRegions.length}');
      print('Has Drone: ${request.drone != null}');
      print('Has Pilot License: ${request.pilotLicense != null}');
      print('================================================');

      final response = await authService.registerPilot(request);
      return await _handleRegisterResponse(
        response,
        label: 'PILOT',
      );
    } on DioException catch (e) {
      return _handleRegisterDioError(e, label: 'PILOT');
    } catch (e, stackTrace) {
      errorMessage = 'Something went wrong. Please try again.';
      print('================================================');
      print('PILOT REGISTER ERROR');
      print(e);
      print(stackTrace);
      print('================================================');
      return null;
    } finally {
      isLoading = false;
    }
  }

  // ============================================================
  // COMPANY REGISTER
  // ============================================================

  Future<Response<dynamic>?> companyRegister({
    required CompanyRegisterRequestModel request,
  }) async {
    try {
      isLoading = true;
      errorMessage = null;

      print('================================================');
      print('COMPANY REGISTRATION STARTED');
      print('Representative Name: ${request.name}');
      print('Company Name: ${request.companyName}');
      print('Email: ${request.email}');
      print('Username: ${request.username}');
      print('Phone: ${request.phone}');
      print('Industry Type: ${request.industryType}');
      print('Country: ${request.country}');
      print('State: ${request.state}');
      print('City: ${request.city}');
      print('Work Regions Count: ${request.workRegions.length}');
      print('Has Logo: ${request.logoPath != null}');
      print('================================================');

      final response = await authService.registerCompany(request);
      return await _handleRegisterResponse(
        response,
        label: 'COMPANY',
      );
    } on DioException catch (e) {
      return _handleRegisterDioError(e, label: 'COMPANY');
    } catch (e, stackTrace) {
      errorMessage = 'Something went wrong. Please try again.';
      print('================================================');
      print('COMPANY REGISTER ERROR');
      print(e);
      print(stackTrace);
      print('================================================');
      return null;
    } finally {
      isLoading = false;
    }
  }

  Future<Response<dynamic>?> _handleRegisterResponse(
      Response<dynamic> response, {
        required String label,
      }) async {
    final responseData = response.data;

    print('$label REGISTER STATUS CODE: ${response.statusCode}');
    print('$label REGISTER RESPONSE: $responseData');

    if (responseData is Map<String, dynamic>) {
      final success = responseData['success'];

      if (success == false) {
        errorMessage = _extractErrorMessage(
          responseData,
          fallback: 'Registration failed. Please try again.',
        );

        return null;
      }

      final data = responseData['data'];

      if (data is Map) {
        final sessionData =
        Map<String, dynamic>.from(data);

        // ========================================================
        // SAVE TOKEN
        // ========================================================

        final token =
        sessionData['token']?.toString();

        if (token != null &&
            token.trim().isNotEmpty) {
          await TokenStorage.saveTokens(
            accessToken: token.trim(),
          );

          print(
            '$label REGISTER TOKEN SAVED SUCCESSFULLY',
          );
        }

        // ========================================================
        // SAVE USER + ROLE + STATUS + PROFILE
        // نفس عملية LOGIN
        // ========================================================

        await UserSessionStorage.saveSession(
          sessionData,
        );

        print(
          '$label REGISTER USER SESSION SAVED SUCCESSFULLY',
        );

        // ========================================================
        // DEBUG
        // ========================================================

        final user = sessionData['user'];

        print(
          '$label REGISTER ROLE: ${sessionData['role']}',
        );

        if (user is Map) {
          print(
            '$label REGISTER USER STATUS: ${user['status']}',
          );

          print(
            '$label REGISTER USER NAME: ${user['name']}',
          );
        }
      }
    }

    return response;
  }

  Response<dynamic>? _handleRegisterDioError(
      DioException e, {
        required String label,
      }) {
    final statusCode = e.response?.statusCode;
    final data = e.response?.data;

    errorMessage = _extractErrorMessage(
      data,
      fallback: 'Registration failed. Please try again.',
    );

    print('================================================');
    print('$label REGISTER DIO ERROR');
    print('STATUS CODE: $statusCode');
    print('ERROR DATA: $data');
    print('ERROR MESSAGE: $errorMessage');
    print('DIO MESSAGE: ${e.message}');
    print('================================================');

    return null;
  }

  // ============================================================
  // API ERROR MESSAGE
  // ============================================================

  String _extractErrorMessage(
      dynamic responseData, {
        required String fallback,
      }) {
    if (responseData == null) return fallback;

    if (responseData is String) {
      return responseData.trim().isNotEmpty
          ? responseData.trim()
          : fallback;
    }

    if (responseData is Map) {
      final message = responseData['message']?.toString().trim();
      final errors = responseData['errors'];

      if (errors is Map && errors.isNotEmpty) {
        for (final entry in errors.entries) {
          final value = entry.value;

          if (value is List && value.isNotEmpty) {
            final firstError = value.first.toString().trim();
            if (firstError.isNotEmpty) return firstError;
          }

          if (value is String && value.trim().isNotEmpty) {
            return value.trim();
          }
        }
      }

      if (message != null && message.isNotEmpty) {
        return message;
      }
    }

    return fallback;
  }


  Future<bool> forgotPassword({
    required String email,
  }) async {
    try {
      isLoading = true;
      errorMessage = null;

      final response =
      await authService.forgotPassword(
        email: email,
      );

      final data = response.data;

      if (data is Map) {
        if (data['success'] == true) {
          return true;
        }

        errorMessage =
            data['message']?.toString() ??
                'Unable to send reset email.';
      }

      return false;
    } on DioException catch (e) {
      print('======================================');
      print('FORGOT PASSWORD ERROR');
      print('STATUS CODE: ${e.response?.statusCode}');
      print('REQUEST URL: ${e.requestOptions.uri}');
      print('RESPONSE DATA: ${e.response?.data}');
      print('======================================');

      errorMessage = _extractErrorMessage(
        e.response?.data,
        fallback: 'Unable to send reset email.',
      );

      return false;
    } catch (e) {
      errorMessage =
      'Something went wrong. Please try again.';
      return false;
    } finally {
      isLoading = false;
    }
  }
}
