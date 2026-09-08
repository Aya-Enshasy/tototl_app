import 'package:dio/dio.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/storage/token_storage.dart';
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
      );
    }
  }

  String _messageFromBody(
    Map<String, dynamic> body, {
    required String fallback,
  }) {
    final errors = body['errors'];

    if (errors is Map) {
      for (final value in errors.values) {
        if (value is List && value.isNotEmpty) {
          final first = value.first.toString().trim();
          if (first.isNotEmpty) return first;
        }

        if (value != null) {
          final text = value.toString().trim();
          if (text.isNotEmpty) return text;
        }
      }
    }

    final message = body['message']?.toString().trim();
    if (message != null && message.isNotEmpty) return message;

    return fallback;
  }

  String _dioErrorMessage(
    DioException error, {
    required String fallback,
  }) {
    final raw = error.response?.data;

    if (raw is Map) {
      return _messageFromBody(
        Map<String, dynamic>.from(raw),
        fallback: fallback,
      );
    }

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
        return 'Connection timed out. Please try again.';
      case DioExceptionType.receiveTimeout:
        return 'Server response timed out. Please try again.';
      case DioExceptionType.connectionError:
        return 'No internet connection.';
      default:
        return fallback;
    }
  }
}

class CompanyDashboardException implements Exception {
  const CompanyDashboardException(this.message);

  final String message;

  @override
  String toString() => message;
}
