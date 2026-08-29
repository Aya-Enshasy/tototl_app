import 'package:dio/dio.dart';

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

  Future<LogoutResponseModel> logout() async {
    final token = await TokenStorage.getAccessToken();

    if (token == null || token.trim().isEmpty) {
      return const LogoutResponseModel(
        success: true,
        message: 'Already signed out.',
      );
    }

    try {
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

      if (raw is! Map) {
        throw const LogoutException(
          'Invalid server response.',
        );
      }

      return LogoutResponseModel.fromJson(
        Map<String, dynamic>.from(raw),
      );
    } on DioException catch (e) {
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
