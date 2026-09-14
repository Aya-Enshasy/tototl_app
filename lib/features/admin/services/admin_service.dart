import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/storage/token_storage.dart';

import '../models/admin_pending_company_model.dart';
import '../models/admin_pending_pilot_model.dart';
import '../models/admin_user_model.dart';
import '../models/admin_verification_history_model.dart';

class AdminService {
  final ApiClient apiClient;

  AdminService(this.apiClient);

  Future<List<AdminPendingPilotModel>> getPendingPilots() async {
    final response = await _authorizedGet(
      ApiEndpoints.adminPendingPilots,
    );

    final body = _body(response.data);
    final raw = body['data'];

    if (raw is! List) return const [];

    return raw
        .whereType<Map>()
        .map(
          (item) => AdminPendingPilotModel.fromJson(
        Map<String, dynamic>.from(item),
      ),
    )
        .toList();
  }

  Future<List<AdminPendingCompanyModel>> getPendingCompanies() async {
    final response = await _authorizedGet(
      ApiEndpoints.adminPendingCompanies,
    );

    final body = _body(response.data);
    final raw = body['data'];

    if (raw is! List) return const [];

    return raw
        .whereType<Map>()
        .map(
          (item) => AdminPendingCompanyModel.fromJson(
        Map<String, dynamic>.from(item),
      ),
    )
        .toList();
  }

  // ==========================================================================
  // ALL COMPANIES DIRECTORY
  // GET /admin/companies?search=&status=&per_page=&page=
  //
  // The endpoint is paginated. This method loads every page so the existing
  // Accounts Directory can keep filtering locally without changing its UI.
  // ==========================================================================

  Future<List<AdminPendingCompanyModel>> getCompanies({
    String? search,
    String? status,
    int perPage = 50,
  }) async {
    final cleanSearch = search?.trim() ?? '';
    final cleanStatus = status?.trim() ?? '';
    final safePerPage = perPage <= 0 ? 50 : perPage;

    final companies = <AdminPendingCompanyModel>[];
    var page = 1;
    var lastPage = 1;

    do {
      final endpoint = _adminCompaniesEndpoint(
        page: page,
        perPage: safePerPage,
        search: cleanSearch,
        status: cleanStatus,
      );

      final response = await _authorizedGet(endpoint);
      final body = _body(response.data);
      final rawData = body['data'];

      if (rawData is! Map) {
        throw AdminException(
          _messageFromBody(
            body,
            fallback: 'Companies directory is unavailable.',
          ),
        );
      }

      final pageMap = Map<String, dynamic>.from(rawData);
      final rawCompanies = pageMap['data'];

      if (rawCompanies is List) {
        companies.addAll(
          rawCompanies
              .whereType<Map>()
              .map(
                (item) => AdminPendingCompanyModel.fromJson(
              Map<String, dynamic>.from(item),
            ),
          ),
        );
      }

      lastPage = _positiveInt(pageMap['last_page']) ?? page;

      // Defensive stop for malformed pagination responses.
      if (rawCompanies is! List || rawCompanies.isEmpty) {
        break;
      }

      page++;
    } while (page <= lastPage);

    return companies;
  }

  Future<AdminUserModel> approveUser(int userId) async {
    final response = await _authorizedPost(
      ApiEndpoints.adminApproveUser(userId),
    );

    return _parseActionUser(
      response,
      fallback: 'Unable to approve this account.',
    );
  }

  Future<AdminUserModel> rejectUser({
    required int userId,
    required String reason,
  }) async {
    final response = await _authorizedPost(
      ApiEndpoints.adminRejectUser(userId),
      data: {
        'reason': reason.trim(),
      },
    );

    return _parseActionUser(
      response,
      fallback: 'Unable to reject this account.',
    );
  }

  Future<AdminUserModel> suspendUser({
    required int userId,
    required String reason,
  }) async {
    final response = await _authorizedPost(
      ApiEndpoints.adminSuspendUser(userId),
      data: {
        'reason': reason.trim(),
      },
    );

    return _parseActionUser(
      response,
      fallback: 'Unable to suspend this account.',
    );
  }

  Future<AdminUserModel> reactivateUser(int userId) async {
    final response = await _authorizedPost(
      ApiEndpoints.adminReactivateUser(userId),
    );

    return _parseActionUser(
      response,
      fallback: 'Unable to reactivate this account.',
    );
  }

  Future<List<AdminVerificationHistoryModel>>
  getVerificationHistory(int userId) async {
    final response = await _authorizedGet(
      ApiEndpoints.adminVerificationHistory(userId),
    );

    final body = _body(response.data);
    final raw = body['data'];

    // Postman examples may contain success:false placeholder even on HTTP 200.
    // For history, a valid 2xx response with a List is treated as usable data.
    if (raw is! List) {
      throw AdminException(
        _messageFromBody(
          body,
          fallback: 'Verification history is unavailable.',
        ),
      );
    }

    return raw
        .whereType<Map>()
        .map(
          (item) => AdminVerificationHistoryModel.fromJson(
        Map<String, dynamic>.from(item),
      ),
    )
        .toList();
  }

  String _adminCompaniesEndpoint({
    required int page,
    required int perPage,
    required String search,
    required String status,
  }) {
    final params = <String, String>{
      'per_page': '$perPage',
      'page': '$page',
    };

    if (search.isNotEmpty) {
      params['search'] = search;
    }

    if (status.isNotEmpty && status.toLowerCase() != 'all') {
      params['status'] = status;
    }

    return Uri(
      path: ApiEndpoints.adminCompanies,
      queryParameters: params,
    ).toString();
  }

  Future<Response<dynamic>> _authorizedGet(String path) async {
    final token = await _token();

    try {
      return await apiClient.get(
        path,
        options: Options(
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        ),
      );
    } on DioException catch (e) {
      throw AdminException(
        _dioMessage(e),
      );
    }
  }

  Future<Response<dynamic>> _authorizedPost(
      String path, {
        Object? data,
      }) async {
    final token = await _token();

    try {
      return await apiClient.post(
        path,
        data: data,
        options: Options(
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        ),
      );
    } on DioException catch (e) {
      throw AdminException(
        _dioMessage(e),
      );
    }
  }

  AdminUserModel _parseActionUser(
      Response<dynamic> response, {
        required String fallback,
      }) {
    final body = _body(response.data);
    final raw = body['data'];

    // Some generated Postman examples show success:false even for an HTTP 200
    // action response. A returned user object on 2xx is therefore accepted.
    if (raw is Map) {
      return AdminUserModel.fromJson(
        Map<String, dynamic>.from(raw),
      );
    }

    throw AdminException(
      _messageFromBody(
        body,
        fallback: fallback,
      ),
    );
  }

  Map<String, dynamic> _body(dynamic raw) {
    if (raw is! Map) {
      throw const AdminException(
        'Invalid server response.',
      );
    }

    return Map<String, dynamic>.from(raw);
  }

  Future<String> _token() async {
    final token = await TokenStorage.getAccessToken();

    if (token == null || token.trim().isEmpty) {
      throw const AdminException(
        'Authentication token not found.',
      );
    }

    return token.trim();
  }

  String _dioMessage(DioException e) {
    final raw = e.response?.data;

    if (raw is Map) {
      return _messageFromBody(
        Map<String, dynamic>.from(raw),
        fallback: 'Admin request failed.',
      );
    }

    if (e.type == DioExceptionType.connectionError) {
      return 'No internet connection.';
    }

    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return 'The server took too long to respond.';
    }

    return 'Admin request failed.';
  }

  String _messageFromBody(
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

  int? _positiveInt(dynamic value) {
    if (value == null) return null;

    final parsed = value is int
        ? value
        : int.tryParse(value.toString().trim());

    if (parsed == null || parsed <= 0) return null;
    return parsed;
  }
}

class AdminException implements Exception {
  final String message;

  const AdminException(this.message);

  @override
  String toString() => message;
}
