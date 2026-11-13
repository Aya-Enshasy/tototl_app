import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/storage/token_storage.dart';

import '../models/logout_response_model.dart';

// ============================================================================
// LOGOUT SERVICE
// ============================================================================

class LogoutService {
  final ApiClient apiClient;

  LogoutService(this.apiClient);

  void _debugLog(String event) {
    if (kDebugMode) debugPrint('[logout][service] $event');
  }

  Future<LogoutResponseModel> logout() async {
    final timer = Stopwatch()..start();
    String? token;
    try {
      token = await TokenStorage.getAccessToken();
    } catch (error) {
      _debugLog('token-read-failed type=${error.runtimeType}');
      rethrow;
    }

    if (token == null || token.trim().isEmpty) {
      _debugLog('skipped reason=no-local-access-token');
      return const LogoutResponseModel(
        success: true,
        message: 'Already signed out.',
      );
    }

    try {
      _debugLog('request method=POST path=${ApiEndpoints.logout}');
      final response = await apiClient.post(
        ApiEndpoints.logout,
        options: Options(
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer ${token.trim()}',
          },
        ),
      );

      final raw = response.data;

      _debugLog(
        'response http=${response.statusCode} bodyType=${raw.runtimeType} '
        'elapsedMs=${timer.elapsedMilliseconds}',
      );

      if (raw is! Map) {
        throw const LogoutException(
          'Invalid server response.',
        );
      }

      final result = LogoutResponseModel.fromJson(
        Map<String, dynamic>.from(raw),
      );
      _debugLog('parsed success=${result.success}');
      return result;
    } on DioException catch (e) {
      _debugLog(
        'dio-error type=${e.type.name} http=${e.response?.statusCode} '
        'bodyType=${e.response?.data.runtimeType} '
        'errorCode=${ApiClient.errorCodeFromDio(e) ?? 'none'} '
        'elapsedMs=${timer.elapsedMilliseconds}',
      );
      if (e.response?.statusCode == 401) {
        return const LogoutResponseModel(
          success: true,
          message: 'Session already expired.',
        );
      }

      throw LogoutException(
        _dioErrorMessage(e),
      );
    }
  }

  String _dioErrorMessage(
      DioException error,
      ) {
    final raw = error.response?.data;

    if (raw is Map) {
      final body = Map<String, dynamic>.from(raw);

      final errors = body['errors'];

      if (errors is Map) {
        for (final value in errors.values) {
          if (value is List && value.isNotEmpty) {
            final first = value.first.toString().trim();
            if (first.isNotEmpty) {
              return first;
            }
          }

          if (value != null) {
            final text = value.toString().trim();
            if (text.isNotEmpty) {
              return text;
            }
          }
        }
      }

      final message =
      body['message']?.toString().trim();

      if (message != null && message.isNotEmpty) {
        return message;
      }
    }

    if (error.type ==
        DioExceptionType.connectionTimeout) {
      return 'Connection timed out. Please try again.';
    }

    if (error.type ==
        DioExceptionType.receiveTimeout) {
      return 'Server response timed out. Please try again.';
    }

    if (error.type ==
        DioExceptionType.connectionError) {
      return 'No internet connection.';
    }

    return 'Unable to sign out. Please try again.';
  }
}

class LogoutException implements Exception {
  final String message;

  const LogoutException(this.message);

  @override
  String toString() => message;
}
