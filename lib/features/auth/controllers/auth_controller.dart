import 'dart:async';
import 'package:dio/dio.dart';
import '../../pilot/services/pilot_profile_sync.dart';
import 'package:flutter/foundation.dart';
import 'package:tototl_app/core/notifications/notification_inbox_state.dart';
import 'package:tototl_app/core/storage/user_session_storage.dart';

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
      await UserSessionStorage.saveSession(
        {
          'user': response.data!.user.toJson(),
          'role': response.data!.role,
        },
      );
      NotificationInboxState.instance.clear();
      if (response.data!.role.trim().toLowerCase() == 'pilot') {
        // Keep the UI responsive while /me populates the encrypted snapshot.
        unawaited(PilotProfileSync.instance.refreshFromApi(force: true));
      }
      return response;
    } on DioException catch (e) {
      errorMessage = _extractErrorMessage(
        e.response?.data,
        fallback: 'Login failed. Please try again.',
      );

      print('LOGIN ERROR STATUS: ${e.response?.statusCode}');
      if (kDebugMode) debugPrint('[TOTOTL][AUTH][LOGIN] failed http=${e.response?.statusCode} type=${e.type.name}');
      return null;
    } catch (e) {
      errorMessage = 'Something went wrong. Please try again.';
      if (kDebugMode) debugPrint('[TOTOTL][AUTH][LOGIN] errorType=${e.runtimeType}');
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

      if (kDebugMode) debugPrint('[TOTOTL][AUTH][REGISTER_PILOT] start');

      final response = await authService.registerPilot(request);
      return await _handleRegisterResponse(
        response,
        label: 'PILOT',
      );
    } on DioException catch (e) {
      return _handleRegisterDioError(e, label: 'PILOT');
    } on AuthMediaException catch (e) {
      errorMessage = e.message;
      return null;
    } catch (e, stackTrace) {
      errorMessage = 'Something went wrong. Please try again.';
      print('================================================');
      print('PILOT REGISTER ERROR');
      if (kDebugMode) debugPrint('[TOTOTL][AUTH][REGISTER] errorType=${e.runtimeType}');
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

      if (kDebugMode) debugPrint('[TOTOTL][AUTH][REGISTER_COMPANY] start');

      final response = await authService.registerCompany(request);
      return await _handleRegisterResponse(
        response,
        label: 'COMPANY',
      );
    } on DioException catch (e) {
      return _handleRegisterDioError(e, label: 'COMPANY');
    } on AuthMediaException catch (e) {
      errorMessage = e.message;
      return null;
    } catch (e, stackTrace) {
      errorMessage = 'Something went wrong. Please try again.';
      print('================================================');
      print('COMPANY REGISTER ERROR');
      if (kDebugMode) debugPrint('[TOTOTL][AUTH][REGISTER] errorType=${e.runtimeType}');
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
    // Never log the full registration payload: it contains an access token.

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
        if (sessionData['role']?.toString().toLowerCase().trim() == 'pilot') {
          unawaited(PilotProfileSync.instance.refreshFromApi(force: true));
        }

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

          if (kDebugMode) debugPrint('[TOTOTL][AUTH][REGISTER] user session stored');
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

    if (statusCode == 413) {
      errorMessage = 'An uploaded image or document is too large (10 MB maximum).';
    } else if (e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      errorMessage = 'Uploading took too long. Check your connection and account status before retrying.';
    } else {
      errorMessage = _extractErrorMessage(
        data,
        fallback: 'Registration failed. Please try again.',
      );
    }

    print('================================================');
    print('$label REGISTER DIO ERROR');
    print('STATUS CODE: $statusCode');
    if (kDebugMode) debugPrint('[TOTOTL][AUTH][REGISTER] responseType=${data.runtimeType}');
    print('ERROR MESSAGE: $errorMessage');
    if (kDebugMode) debugPrint('[TOTOTL][AUTH][REGISTER] dioType=${e.type.name}');
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
      if (kDebugMode) debugPrint('[TOTOTL][AUTH][RESET] path=${e.requestOptions.path}');
      if (kDebugMode) debugPrint('[TOTOTL][AUTH][RESET] http=${e.response?.statusCode}');
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
