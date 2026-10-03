import 'package:dio/dio.dart';
import 'package:tototl_app/core/network/api_client.dart';
import 'package:tototl_app/core/storage/token_storage.dart';
import 'package:tototl_app/features/shared/models/phase3_account_summary.dart';

enum Phase3DashboardAudience { pilot, company }

class Phase3DashboardService {
  final ApiClient apiClient;
  final Phase3DashboardAudience audience;

  Phase3DashboardService(
    this.apiClient, {
    required this.audience,
  });

  Future<Phase3AccountSummary> getOverview() async {
    final token = await TokenStorage.getAccessToken();
    if (token == null || token.trim().isEmpty) {
      throw const Phase3DashboardException('Authentication token not found.');
    }

    final endpoint = audience == Phase3DashboardAudience.company
        ? '/company/dashboard'
        : '/dashboard';

    try {
      final response = await apiClient.get(
        endpoint,
        options: Options(
          headers: <String, dynamic>{
            'Accept': 'application/json',
            'Authorization': 'Bearer ${token.trim()}',
          },
        ),
      );

      final raw = response.data;
      if (raw is! Map) {
        throw const Phase3DashboardException('Invalid dashboard response.');
      }

      final body = Map<String, dynamic>.from(raw);
      if (body['success'] != true) {
        throw Phase3DashboardException(
          _messageFromBody(
            body,
            fallback: 'Unable to load Phase 3 dashboard.',
          ),
        );
      }

      final data = body['data'];
      if (data is! Map) {
        throw const Phase3DashboardException('Dashboard data is missing.');
      }

      final json = Map<String, dynamic>.from(data);
      return audience == Phase3DashboardAudience.company
          ? Phase3AccountSummary.fromCompanyDashboardJson(json)
          : Phase3AccountSummary.fromPilotDashboardJson(json);
    } on DioException catch (e) {
      final raw = e.response?.data;
      if (raw is Map) {
        throw Phase3DashboardException(
          _messageFromBody(
            Map<String, dynamic>.from(raw),
            fallback: 'Unable to load Phase 3 dashboard.',
          ),
        );
      }

      if (e.type == DioExceptionType.connectionError) {
        throw const Phase3DashboardException('No internet connection.');
      }

      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw const Phase3DashboardException(
          'Connection timed out. Please try again.',
        );
      }

      throw const Phase3DashboardException(
        'Unable to load Phase 3 dashboard.',
      );
    }
  }

  static String _messageFromBody(
    Map<String, dynamic> body, {
    required String fallback,
  }) {
    final errors = body['errors'];
    if (errors is Map) {
      for (final value in errors.values) {
        if (value is List && value.isNotEmpty) {
          final text = value.first.toString().trim();
          if (text.isNotEmpty) return text;
        }
        final text = value?.toString().trim() ?? '';
        if (text.isNotEmpty) return text;
      }
    }

    final message = body['message']?.toString().trim() ?? '';
    return message.isEmpty ? fallback : message;
  }
}

class Phase3DashboardException implements Exception {
  final String message;
  const Phase3DashboardException(this.message);

  @override
  String toString() => message;
}
