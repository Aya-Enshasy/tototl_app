import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/storage/token_storage.dart';

import '../models/admin_pending_company_model.dart';
import '../models/admin_pending_pilot_model.dart';

// ============================================================================
// ADMIN SERVICE
// ============================================================================

class AdminService {
  final ApiClient apiClient;

  AdminService(
    this.apiClient,
  );

  // ==========================================================================
  // PENDING PILOTS
  // GET /admin/pilots/pending
  // ==========================================================================

  Future<List<AdminPendingPilotModel>>
  getPendingPilots() async {
    final token = await _getToken();

    try {
      final response = await apiClient.get(
        ApiEndpoints.adminPendingPilots,
        options: Options(
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        ),
      );

      final body = _parseBody(
        response.data,
      );

      _ensureSuccess(
        body,
        fallback:
            'Unable to load pending pilots.',
      );

      return _parsePilotList(
        body['data'],
      );
    } on DioException catch (e) {
      throw AdminException(
        _dioErrorMessage(
          e,
          fallback:
              'Unable to load pending pilots.',
        ),
      );
    }
  }

  // ==========================================================================
  // PENDING COMPANIES
  // GET /admin/companies/pending
  // ==========================================================================

  Future<List<AdminPendingCompanyModel>>
  getPendingCompanies() async {
    final token = await _getToken();

    try {
      final response = await apiClient.get(
        ApiEndpoints.adminPendingCompanies,
        options: Options(
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        ),
      );

      final body = _parseBody(
        response.data,
      );

      _ensureSuccess(
        body,
        fallback:
            'Unable to load pending companies.',
      );

      return _parseCompanyList(
        body['data'],
      );
    } on DioException catch (e) {
      throw AdminException(
        _dioErrorMessage(
          e,
          fallback:
              'Unable to load pending companies.',
        ),
      );
    }
  }

  // ==========================================================================
  // TOKEN
  // ==========================================================================

  Future<String>
  _getToken() async {
    final token =
        await TokenStorage.getAccessToken();

    if (token == null ||
        token.trim().isEmpty) {
      throw const AdminException(
        'Authentication token not found.',
      );
    }

    return token.trim();
  }

  // ==========================================================================
  // PARSING
  // ==========================================================================

  Map<String, dynamic> _parseBody(
    dynamic raw,
  ) {
    if (raw is! Map) {
      throw const AdminException(
        'Invalid server response.',
      );
    }

    return Map<String, dynamic>.from(
      raw,
    );
  }

  void _ensureSuccess(
    Map<String, dynamic> body, {
    required String fallback,
  }) {
    if (body['success'] == true) {
      return;
    }

    throw AdminException(
      _messageFromBody(
        body,
        fallback: fallback,
      ),
    );
  }

  List<AdminPendingPilotModel>
  _parsePilotList(
    dynamic raw,
  ) {
    if (raw == null) {
      return <AdminPendingPilotModel>[];
    }

    if (raw is! List) {
      throw const AdminException(
        'Pending pilots data is invalid.',
      );
    }

    final result =
        <AdminPendingPilotModel>[];

    for (final item in raw) {
      if (item is Map) {
        result.add(
          AdminPendingPilotModel.fromJson(
            Map<String, dynamic>.from(
              item,
            ),
          ),
        );
      }
    }

    return result;
  }

  List<AdminPendingCompanyModel>
  _parseCompanyList(
    dynamic raw,
  ) {
    if (raw == null) {
      return <AdminPendingCompanyModel>[];
    }

    if (raw is! List) {
      throw const AdminException(
        'Pending companies data is invalid.',
      );
    }

    final result =
        <AdminPendingCompanyModel>[];

    for (final item in raw) {
      if (item is Map) {
        result.add(
          AdminPendingCompanyModel.fromJson(
            Map<String, dynamic>.from(
              item,
            ),
          ),
        );
      }
    }

    return result;
  }

  // ==========================================================================
  // ERRORS
  // ==========================================================================

  String _messageFromBody(
    Map<String, dynamic> body, {
    required String fallback,
  }) {
    final errors = body['errors'];

    if (errors is Map) {
      for (final value in errors.values) {
        if (value is List &&
            value.isNotEmpty) {
          final first =
              value.first.toString().trim();

          if (first.isNotEmpty) {
            return first;
          }
        }

        if (value != null) {
          final text =
              value.toString().trim();

          if (text.isNotEmpty) {
            return text;
          }
        }
      }
    }

    final message =
        body['message']
            ?.toString()
            .trim();

    if (message != null &&
        message.isNotEmpty) {
      return message;
    }

    return fallback;
  }

  String _dioErrorMessage(
    DioException error, {
    required String fallback,
  }) {
    final raw =
        error.response?.data;

    if (raw is Map) {
      return _messageFromBody(
        Map<String, dynamic>.from(
          raw,
        ),
        fallback: fallback,
      );
    }

    if (error.type ==
        DioExceptionType
            .connectionTimeout) {
      return 'Connection timed out. Please try again.';
    }

    if (error.type ==
        DioExceptionType
            .receiveTimeout) {
      return 'Server response timed out. Please try again.';
    }

    if (error.type ==
        DioExceptionType
            .connectionError) {
      return 'No internet connection.';
    }

    return fallback;
  }
}

// ============================================================================
// ADMIN EXCEPTION
// ============================================================================

class AdminException
    implements Exception {
  final String message;

  const AdminException(
    this.message,
  );

  @override
  String toString() =>
      message;
}
