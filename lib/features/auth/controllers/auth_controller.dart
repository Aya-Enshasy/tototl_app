import 'package:dio/dio.dart';

import '../models/LoginResponseModel.dart';
import '../models/PilotRegisterRequestModel.dart';
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
        errorMessage =
        response.message.isNotEmpty
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

      print(
        'LOGIN ERROR STATUS: ${e.response?.statusCode}',
      );

      print(
        'LOGIN ERROR DATA: ${e.response?.data}',
      );

      return null;
    } catch (e) {
      errorMessage =
      'Something went wrong. Please try again.';

      print(
        'LOGIN ERROR: $e',
      );

      return null;
    } finally {
      isLoading = false;
    }
  }

  // ============================================================
  // PILOT REGISTER
  // ============================================================
  //
  // IMPORTANT:
  //
  // This function is called ONLY from Step 4.
  //
  // Step 1 -> creates PilotRegisterRequestModel
  // Step 2 -> adds profile / experience
  // Step 3 -> adds drone
  // Step 4 -> adds license then sends everything here
  //
  // ============================================================

  Future<Response<dynamic>?> pilotRegister({
    required PilotRegisterRequestModel request,
  }) async {
    try {
      isLoading = true;
      errorMessage = null;

      print(
        '================================================',
      );

      print(
        'PILOT REGISTRATION STARTED',
      );

      print(
        'Name: ${request.name}',
      );

      print(
        'Email: ${request.email}',
      );

      print(
        'Username: ${request.username}',
      );

      print(
        'Phone: ${request.phone}',
      );

      print(
        'Nationality: ${request.nationality}',
      );

      print(
        'Date of Birth: ${request.dateOfBirth}',
      );

      print(
        'Experience Years: ${request.experienceYears}',
      );

      print(
        'Languages: ${request.languages}',
      );

      print(
        'Current Country: ${request.currentCountry}',
      );

      print(
        'Current State: ${request.currentState}',
      );

      print(
        'Current City: ${request.currentCity}',
      );

      print(
        'Work Regions Count: ${request.workRegions.length}',
      );

      print(
        'Has Drone: ${request.drone != null}',
      );

      print(
        'Has Pilot License: ${request.pilotLicense != null}',
      );

      print(
        '================================================',
      );

      final response =
      await authService.registerPilot(
        request,
      );

      // ========================================================
      // RESPONSE
      // ========================================================

      final responseData = response.data;

      print(
        'REGISTER STATUS CODE: ${response.statusCode}',
      );

      print(
        'REGISTER RESPONSE: $responseData',
      );

      // ========================================================
      // SAVE TOKEN
      // ========================================================
      //
      // Expected:
      //
      // {
      //   "success": true,
      //   "data": {
      //      "user": {...},
      //      "role": "...",
      //      "token": "..."
      //   }
      // }
      //
      // ========================================================

      if (responseData is Map<String, dynamic>) {
        final success =
        responseData['success'];

        if (success == false) {
          errorMessage = _extractErrorMessage(
            responseData,
            fallback:
            'Registration failed. Please try again.',
          );

          return null;
        }

        final data =
        responseData['data'];

        if (data is Map<String, dynamic>) {
          final token =
          data['token']?.toString();

          if (token != null &&
              token.trim().isNotEmpty) {
            await TokenStorage.saveTokens(
              accessToken: token.trim(),
            );

            print(
              'REGISTER TOKEN SAVED SUCCESSFULLY',
            );
          }
        }
      }

      return response;
    }

    // ==========================================================
    // DIO ERROR
    // ==========================================================

    on DioException catch (e) {
      final statusCode =
          e.response?.statusCode;

      final data =
          e.response?.data;

      errorMessage = _extractErrorMessage(
        data,
        fallback:
        'Registration failed. Please try again.',
      );

      print(
        '================================================',
      );

      print(
        'PILOT REGISTER DIO ERROR',
      );

      print(
        'STATUS CODE: $statusCode',
      );

      print(
        'ERROR DATA: $data',
      );

      print(
        'ERROR MESSAGE: $errorMessage',
      );

      print(
        'DIO MESSAGE: ${e.message}',
      );

      print(
        '================================================',
      );

      return null;
    }

    // ==========================================================
    // OTHER ERROR
    // ==========================================================

    catch (e, stackTrace) {
      errorMessage =
      'Something went wrong. Please try again.';

      print(
        '================================================',
      );

      print(
        'PILOT REGISTER ERROR',
      );

      print(
        e,
      );

      print(
        stackTrace,
      );

      print(
        '================================================',
      );

      return null;
    } finally {
      isLoading = false;
    }
  }

  // ============================================================
  // API ERROR MESSAGE
  // ============================================================

  String _extractErrorMessage(
      dynamic responseData, {
        required String fallback,
      }) {
    if (responseData == null) {
      return fallback;
    }

    if (responseData is String) {
      if (responseData.trim().isNotEmpty) {
        return responseData.trim();
      }

      return fallback;
    }

    if (responseData is Map) {
      // ========================================================
      // NORMAL MESSAGE
      // ========================================================

      final message =
      responseData['message']
          ?.toString()
          .trim();

      // ========================================================
      // LARAVEL VALIDATION ERRORS
      //
      // Example:
      //
      // {
      //   "message": "...",
      //   "errors": {
      //      "email": [
      //          "The email has already been taken."
      //      ]
      //   }
      // }
      //
      // ========================================================

      final errors =
      responseData['errors'];

      if (errors is Map &&
          errors.isNotEmpty) {
        for (final entry
        in errors.entries) {
          final value =
              entry.value;

          if (value is List &&
              value.isNotEmpty) {
            final firstError =
            value.first
                .toString()
                .trim();

            if (firstError.isNotEmpty) {
              return firstError;
            }
          }

          if (value is String &&
              value.trim().isNotEmpty) {
            return value.trim();
          }
        }
      }

      if (message != null &&
          message.isNotEmpty) {
        return message;
      }
    }

    return fallback;
  }
}