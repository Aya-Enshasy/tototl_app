import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/storage/token_storage.dart';
import '../models/pilot_dashboard_model.dart';

class PilotDashboardService {
  PilotDashboardService(this.apiClient);

  final ApiClient apiClient;

  Future<PilotDashboardModel> getDashboard() async {
    final token = await TokenStorage.getAccessToken();

    if (token == null || token.trim().isEmpty) {
      throw const PilotDashboardException(
        'Authentication token not found.',
      );
    }

    try {
      final response = await apiClient.get(
        ApiEndpoints.pilotDashboard,
        options: Options(
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer ${token.trim()}',
          },
        ),
      );

      final raw = response.data;

      if (raw is! Map) {
        throw const PilotDashboardException(
          'Invalid dashboard response.',
        );
      }

      final body = Map<String, dynamic>.from(raw);

      if (body['success'] != true) {
        throw PilotDashboardException(
          _messageFromBody(
            body,
            fallback: 'Unable to load dashboard.',
          ),
          statusCode: response.statusCode,
        );
      }

      final data = body['data'];

      if (data is! Map) {
        throw const PilotDashboardException(
          'Dashboard data is missing.',
        );
      }

      return PilotDashboardModel.fromJson(
        Map<String, dynamic>.from(data),
      );
    } on DioException catch (e) {
      throw PilotDashboardException(
        _dioErrorMessage(e),
        statusCode: e.response?.statusCode,
        retryAfterSeconds: _retryAfterSeconds(e),
      );
    }
  }

  String _messageFromBody(
    Map<String, dynamic> body, {
    required String fallback,
  }) {
    final errors = body['errors'];

    if (errors is Map) {
      for (final entry in errors.entries) {
        final key = entry.key.toString().trim().toLowerCase();
        if (key == 'error_code' || key == 'code') continue;

        final value = entry.value;

        if (value is List && value.isNotEmpty) {
          final text = value.first.toString().trim();
          if (text.isNotEmpty) return text;
        }

        final text = value?.toString().trim() ?? '';
        if (text.isNotEmpty && text.toLowerCase() != 'null') {
          return text;
        }
      }
    }

    final message = body['message']?.toString().trim() ?? '';
    return message.isNotEmpty ? message : fallback;
  }

  String _dioErrorMessage(DioException error) {
    if (error.response?.statusCode == 429) {
      final retryAfter = _retryAfterSeconds(error);
      return retryAfter == null
          ? 'Too many requests. Please try again shortly.'
          : 'Too many requests. Please try again in $retryAfter seconds.';
    }

    final raw = error.response?.data;

    if (raw is Map) {
      return _messageFromBody(
        Map<String, dynamic>.from(raw),
        fallback: 'Unable to load dashboard.',
      );
    }

    if (error.type == DioExceptionType.connectionTimeout) {
      return 'Connection timed out. Please try again.';
    }

    if (error.type == DioExceptionType.receiveTimeout) {
      return 'Server response timed out. Please try again.';
    }

    if (error.type == DioExceptionType.sendTimeout) {
      return 'Request timed out while sending. Please try again.';
    }

    if (error.type == DioExceptionType.connectionError) {
      return 'No internet connection.';
    }

    return 'Unable to load dashboard. Please try again.';
  }

  int? _retryAfterSeconds(DioException error) {
    final value = error.response?.headers.value('retry-after');
    if (value == null || value.trim().isEmpty) return null;
    return int.tryParse(value.trim());
  }
}

class PilotDashboardException implements Exception {
  const PilotDashboardException(
    this.message, {
    this.statusCode,
    this.retryAfterSeconds,
  });

  final String message;
  final int? statusCode;
  final int? retryAfterSeconds;

  bool get isRateLimited => statusCode == 429;

  @override
  String toString() => message;
}
