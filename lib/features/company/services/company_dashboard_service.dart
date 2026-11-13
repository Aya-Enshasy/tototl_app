import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/storage/token_storage.dart';
import '../../company/models/company_dashboard_model.dart';

class CompanyDashboardService {
  CompanyDashboardService(this.apiClient);

  final ApiClient apiClient;

  Future<CompanyDashboardModel> getDashboard() async {
    final token = await TokenStorage.getAccessToken();

    if (token == null || token.trim().isEmpty) {
      throw const CompanyDashboardException(
        'Authentication token not found.',
      );
    }

    try {
      final response = await apiClient.get(
        ApiEndpoints.companyDashboard,
        options: Options(
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer ${token.trim()}',
          },
        ),
      );

      final raw = response.data;
      if (raw is! Map) {
        throw const CompanyDashboardException(
          'Invalid dashboard response.',
        );
      }

      final body = Map<String, dynamic>.from(raw);

      if (body['success'] != true) {
        throw CompanyDashboardException(
          _messageFromBody(
            body,
            fallback: 'Unable to load company dashboard.',
          ),
          statusCode: response.statusCode,
        );
      }

      final data = body['data'];
      if (data is! Map) {
        throw const CompanyDashboardException(
          'Company dashboard data is missing.',
        );
      }

      return CompanyDashboardModel.fromJson(
        Map<String, dynamic>.from(data),
      );
    } on DioException catch (e) {
      throw CompanyDashboardException(
        _dioErrorMessage(
          e,
          fallback: 'Unable to load company dashboard.',
        ),
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
          final first = value.first.toString().trim();
          if (first.isNotEmpty) return first;
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

  String _dioErrorMessage(
    DioException error, {
    required String fallback,
  }) {
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
        fallback: fallback,
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

    return fallback;
  }

  int? _retryAfterSeconds(DioException error) {
    final value = error.response?.headers.value('retry-after');
    if (value == null || value.trim().isEmpty) return null;
    return int.tryParse(value.trim());
  }
}

class CompanyDashboardException implements Exception {
  const CompanyDashboardException(
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
