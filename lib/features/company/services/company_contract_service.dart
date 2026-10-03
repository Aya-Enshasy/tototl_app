import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/storage/token_storage.dart';
import '../models/company_contract_model.dart';
import '../models/company_contract_location_model.dart';
import '../models/contract_submission_model.dart';

class CompanyContractService {
  final ApiClient apiClient;

  CompanyContractService(this.apiClient);

  Future<List<CompanyContractModel>> getContracts({String? status}) async {
    final token = await _getToken();
    final all = <CompanyContractModel>[];
    final cleanStatus = status?.trim().toLowerCase() ?? '';

    const perPage = 50;
    var page = 1;
    int? knownLastPage;

    try {
      while (true) {
        final query = <String>[
          'per_page=$perPage',
          'page=$page',
          if (cleanStatus.isNotEmpty)
            'status=${Uri.encodeQueryComponent(cleanStatus)}',
        ].join('&');

        final response = await apiClient.get(
          '${ApiEndpoints.companyContracts}?$query',
          options: _authOptions(token),
        );

        final body = _parseBody(response.data);
        _ensureSuccess(body, fallback: 'Unable to load company contracts.');

        final rawData = body['data'];
        List<CompanyContractModel> pageItems;

        // Backend/OpenAPI paginator shape:
        // data: { current_page, data: [...], last_page, ... }
        if (rawData is Map) {
          final paginator = Map<String, dynamic>.from(rawData);
          pageItems = _parseContractList(paginator['data']);
          knownLastPage = _asInt(paginator['last_page']) ??
              _asInt(paginator['current_page']) ??
              knownLastPage;
        }
        // Defensive support for APIs that unwrap the paginator as:
        // data: [...], meta: { current_page, last_page, ... }
        else if (rawData is List) {
          pageItems = _parseContractList(rawData);
          final rawMeta = body['meta'];
          if (rawMeta is Map) {
            final meta = Map<String, dynamic>.from(rawMeta);
            knownLastPage = _asInt(meta['last_page']) ?? knownLastPage;
          }
        } else {
          throw const CompanyContractException(
            'Company contracts data is missing.',
          );
        }

        all.addAll(pageItems);

        // Prefer explicit paginator metadata. If the backend does not return
        // metadata, keep paging while full pages are returned. This prevents
        // missing an existing contract that is not on page 1.
        if (knownLastPage != null) {
          if (page >= knownLastPage!) break;
        } else if (pageItems.length < perPage) {
          break;
        }

        // Safety guard against a malformed paginator.
        if (page >= 100) break;
        page++;
      }

      // Defensive de-duplication in case an API page overlaps another page.
      final byId = <int, CompanyContractModel>{};
      for (final contract in all) {
        if (contract.id > 0) {
          byId[contract.id] = contract;
        }
      }
      final result = byId.isEmpty ? all : byId.values.toList();

      result.sort((a, b) {
        final ad = a.updatedAt ??
            a.createdAt ??
            DateTime.fromMillisecondsSinceEpoch(0);
        final bd = b.updatedAt ??
            b.createdAt ??
            DateTime.fromMillisecondsSinceEpoch(0);
        return bd.compareTo(ad);
      });

      return result;
    } on DioException catch (e) {
      throw CompanyContractException(
        _dioErrorMessage(e, fallback: 'Unable to load company contracts.'),
      );
    }
  }

  Future<CompanyContractModel> getContract(int contractId) async {
    final token = await _getToken();
    try {
      final response = await apiClient.get(
        ApiEndpoints.companyContract(contractId),
        options: _authOptions(token),
      );
      final body = _parseBody(response.data);
      _ensureSuccess(body, fallback: 'Unable to load this contract.');
      final raw = body['data'];
      if (raw is! Map) {
        throw const CompanyContractException('Contract details are missing.');
      }
      return CompanyContractModel.fromJson(Map<String, dynamic>.from(raw));
    } on DioException catch (e) {
      throw CompanyContractException(
        _dioErrorMessage(e, fallback: 'Unable to load this contract.'),
      );
    }
  }

  /// Returns the contract that belongs to this exact application, if one exists.
  ///
  /// This keeps the original method signature used by older call sites.
  Future<CompanyContractModel?> findContractForApplication(
    int applicationId,
  ) async {
    if (applicationId <= 0) return null;

    final contracts = await getContracts();
    for (final contract in contracts) {
      if (contract.jobApplicationId == applicationId) {
        return contract;
      }
    }
    return null;
  }

  /// Strong duplicate-contract guard used before opening/submitting Create Contract.
  ///
  /// Primary match: the exact JobApplication ID.
  /// Fallback match: any non-terminal contract on the same JobPosting.
  ///
  /// The fallback is important because the backend enforces one active contract
  /// per job. If a stale client tries to create another contract for a different
  /// accepted application on the same job, the API returns HTTP 422. In that
  /// situation we surface the already-existing contract instead of encouraging
  /// another create attempt.
  Future<CompanyContractModel?> findExistingContract({
    required int applicationId,
    required int jobId,
  }) async {
    if (applicationId <= 0 && jobId <= 0) return null;

    CompanyContractModel? matchFrom(List<CompanyContractModel> contracts) {
      CompanyContractModel? sameJobFallback;

      for (final contract in contracts) {
        if (applicationId > 0 &&
            contract.jobApplicationId == applicationId) {
          return contract;
        }

        if (sameJobFallback == null &&
            jobId > 0 &&
            contract.jobPostingId == jobId &&
            !contract.isTerminal) {
          sameJobFallback = contract;
        }
      }

      return sameJobFallback;
    }

    // First scan the complete unfiltered contract list.
    final allContracts = await getContracts();
    final direct = matchFrom(allContracts);
    if (direct != null) return direct;

    // Extra defensive pass. Some backends or proxies may paginate/filter the
    // unfiltered route differently. The server considers these statuses active
    // enough to block creation, so scan them individually before showing
    // Create Contract to the user.
    const blockingStatuses = <String>[
      'pending',
      'accepted',
      'active',
      'in_progress',
      'submitted',
    ];

    for (final status in blockingStatuses) {
      final contracts = await getContracts(status: status);
      final match = matchFrom(contracts);
      if (match != null) return match;
    }

    return null;
  }

  /// Useful when only the job is known. Returns a non-terminal contract first.
  Future<CompanyContractModel?> findOpenContractForJob(int jobId) async {
    if (jobId <= 0) return null;

    final contracts = await getContracts();
    for (final contract in contracts) {
      if (contract.jobPostingId == jobId && !contract.isTerminal) {
        return contract;
      }
    }
    return null;
  }


  Future<CompanyContractLocationModel?> getContractLocation(int contractId) async {
    final token = await _getToken();

    Future<CompanyContractLocationModel?> read(String endpoint) async {
      final response = await apiClient.get(
        endpoint,
        options: _authOptions(token),
      );
      final body = _parseBody(response.data);
      _ensureSuccess(body, fallback: 'Unable to load the exact job location.');
      final raw = body['data'];
      if (raw is! Map) return null;
      return CompanyContractLocationModel.fromJson(
        Map<String, dynamic>.from(raw),
      );
    }

    try {
      // Preferred company-specific route. The company is allowed to view the
      // location in every lifecycle state, including Submitted/Completed.
      return await read(ApiEndpoints.companyContractLocation(contractId));
    } on DioException catch (e) {
      final status = e.response?.statusCode;

      // Some deployed builds expose the shared contract-location route more
      // reliably than the company alias. Both routes authorize the company.
      if (status == 403 || status == 404) {
        try {
          return await read(ApiEndpoints.contractLocation(contractId));
        } on DioException catch (fallbackError) {
          if (fallbackError.response?.statusCode == 404) return null;
          throw CompanyContractException(
            _dioErrorMessage(
              fallbackError,
              fallback: 'Unable to load the exact job location.',
            ),
          );
        }
      }

      throw CompanyContractException(
        _dioErrorMessage(e, fallback: 'Unable to load the exact job location.'),
      );
    }
  }

  Future<CompanyContractLocationModel> saveContractLocation(
    int contractId,
    CompanyContractLocationRequest request,
  ) async {
    final token = await _getToken();

    if (request.address.trim().isEmpty) {
      throw const CompanyContractException('Exact address is required.');
    }
    if (request.address.trim().length > 500) {
      throw const CompanyContractException('Address cannot exceed 500 characters.');
    }
    if (request.latitude < -90 || request.latitude > 90) {
      throw const CompanyContractException('Latitude must be between -90 and 90.');
    }
    if (request.longitude < -180 || request.longitude > 180) {
      throw const CompanyContractException('Longitude must be between -180 and 180.');
    }
    if ((request.notes ?? '').trim().length > 2000) {
      throw const CompanyContractException('Location notes cannot exceed 2000 characters.');
    }

    try {
      // The project ApiClient is used for normal requests. This endpoint is PUT;
      // using Dio directly keeps this feature compatible even if ApiClient only
      // exposes get/post/patch/delete wrappers.
      final response = await Dio().put<dynamic>(
        '${ApiEndpoints.baseUrl}${ApiEndpoints.companyContractLocation(contractId)}',
        data: request.toJson(),
        options: _jsonAuthOptions(token),
      );
      final body = _parseBody(response.data);
      _ensureSuccess(body, fallback: 'Unable to save the exact job location.');
      final raw = body['data'];
      if (raw is! Map) {
        throw const CompanyContractException('Saved location data is missing.');
      }
      return CompanyContractLocationModel.fromJson(
        Map<String, dynamic>.from(raw),
      );
    } on DioException catch (e) {
      throw CompanyContractException(
        _dioErrorMessage(e, fallback: 'Unable to save the exact job location.'),
      );
    }
  }

  Future<List<ContractSubmissionModel>> getSubmissions(int contractId) async {
    final token = await _getToken();
    try {
      final response = await apiClient.get(
        ApiEndpoints.companyContractSubmissions(contractId),
        options: _authOptions(token),
      );
      final body = _parseBody(response.data);
      _ensureSuccess(body, fallback: 'Unable to load work submissions.');
      final raw = body['data'];
      if (raw is! List) return const [];
      return raw
          .whereType<Map>()
          .map((item) => ContractSubmissionModel.fromJson(
                Map<String, dynamic>.from(item),
              ))
          .toList(growable: false);
    } on DioException catch (e) {
      throw CompanyContractException(
        _dioErrorMessage(e, fallback: 'Unable to load work submissions.'),
      );
    }
  }

  Future<ContractSubmissionModel> getSubmission(
    int contractId,
    int submissionId,
  ) async {
    final token = await _getToken();
    try {
      final response = await apiClient.get(
        ApiEndpoints.companyContractSubmission(contractId, submissionId),
        options: _authOptions(token),
      );
      final body = _parseBody(response.data);
      _ensureSuccess(body, fallback: 'Unable to load this submission.');
      final raw = body['data'];
      if (raw is! Map) {
        throw const CompanyContractException('Work submission data is missing.');
      }
      return ContractSubmissionModel.fromJson(
        Map<String, dynamic>.from(raw),
      );
    } on DioException catch (e) {
      throw CompanyContractException(
        _dioErrorMessage(e, fallback: 'Unable to load this submission.'),
      );
    }
  }

  Future<CompanySubmissionReviewResult> approveSubmission(
    int contractId,
    int submissionId, {
    String? reviewNotes,
  }) async {
    final cleanNotes = reviewNotes?.trim() ?? '';
    if (cleanNotes.length > 2000) {
      throw const CompanyContractException(
        'Review notes cannot exceed 2000 characters.',
      );
    }

    final token = await _getToken();
    try {
      final response = await apiClient.post(
        ApiEndpoints.approveCompanyContractSubmission(contractId, submissionId),
        data: cleanNotes.isEmpty
            ? null
            : <String, dynamic>{'review_notes': cleanNotes},
        options: cleanNotes.isEmpty
            ? _authOptions(token)
            : _jsonAuthOptions(token),
      );
      final body = _parseBody(response.data);
      _ensureSuccess(body, fallback: 'Unable to approve this submission.');
      final raw = body['data'];
      if (raw is! Map) {
        throw const CompanyContractException('Reviewed submission data is missing.');
      }
      final submission = ContractSubmissionModel.fromJson(
        Map<String, dynamic>.from(raw),
      );
      final contract = await getContract(contractId);
      return CompanySubmissionReviewResult(
        submission: submission,
        contract: contract,
      );
    } on DioException catch (e) {
      throw CompanyContractException(
        _dioErrorMessage(e, fallback: 'Unable to approve this submission.'),
      );
    }
  }

  Future<CompanySubmissionReviewResult> requestRevision(
    int contractId,
    int submissionId, {
    required String reviewNotes,
  }) async {
    final cleanNotes = reviewNotes.trim();
    if (cleanNotes.isEmpty) {
      throw const CompanyContractException(
        'Revision instructions are required.',
      );
    }
    if (cleanNotes.length > 2000) {
      throw const CompanyContractException(
        'Revision instructions cannot exceed 2000 characters.',
      );
    }

    final token = await _getToken();
    try {
      final response = await apiClient.post(
        ApiEndpoints.requestRevisionCompanyContractSubmission(
          contractId,
          submissionId,
        ),
        data: <String, dynamic>{'review_notes': cleanNotes},
        options: _jsonAuthOptions(token),
      );
      final body = _parseBody(response.data);
      _ensureSuccess(body, fallback: 'Unable to request a revision.');
      final raw = body['data'];
      if (raw is! Map) {
        throw const CompanyContractException('Reviewed submission data is missing.');
      }
      final submission = ContractSubmissionModel.fromJson(
        Map<String, dynamic>.from(raw),
      );
      final contract = await getContract(contractId);
      return CompanySubmissionReviewResult(
        submission: submission,
        contract: contract,
      );
    } on DioException catch (e) {
      throw CompanyContractException(
        _dioErrorMessage(e, fallback: 'Unable to request a revision.'),
      );
    }
  }


  Future<CompanyContractModel> cancelContract(
    int contractId, {
    String? reason,
  }) async {
    final cleanReason = reason?.trim() ?? '';
    if (cleanReason.length > 2000) {
      throw const CompanyContractException(
        'Cancellation reason cannot exceed 2000 characters.',
      );
    }

    final token = await _getToken();
    try {
      final response = await apiClient.post(
        ApiEndpoints.cancelCompanyContract(contractId),
        data: cleanReason.isEmpty
            ? null
            : <String, dynamic>{'reason': cleanReason},
        options: cleanReason.isEmpty
            ? _authOptions(token)
            : _jsonAuthOptions(token),
      );
      final body = _parseBody(response.data);
      _ensureSuccess(body, fallback: 'Unable to cancel this contract.');
      final raw = body['data'];
      if (raw is! Map) {
        throw const CompanyContractException(
          'Cancelled contract data is missing.',
        );
      }
      return CompanyContractModel.fromJson(
        Map<String, dynamic>.from(raw),
      );
    } on DioException catch (e) {
      throw CompanyContractException(
        _dioErrorMessage(e, fallback: 'Unable to cancel this contract.'),
      );
    }
  }

  Future<CompanyContractModel> terminateContract(
    int contractId, {
    required String reason,
  }) async {
    final cleanReason = reason.trim();
    if (cleanReason.isEmpty) {
      throw const CompanyContractException(
        'Termination reason is required.',
      );
    }
    if (cleanReason.length > 2000) {
      throw const CompanyContractException(
        'Termination reason cannot exceed 2000 characters.',
      );
    }

    final token = await _getToken();
    try {
      final response = await apiClient.post(
        ApiEndpoints.terminateCompanyContract(contractId),
        data: <String, dynamic>{'reason': cleanReason},
        options: _jsonAuthOptions(token),
      );
      final body = _parseBody(response.data);
      _ensureSuccess(body, fallback: 'Unable to terminate this contract.');
      final raw = body['data'];
      if (raw is! Map) {
        throw const CompanyContractException(
          'Terminated contract data is missing.',
        );
      }
      return CompanyContractModel.fromJson(
        Map<String, dynamic>.from(raw),
      );
    } on DioException catch (e) {
      throw CompanyContractException(
        _dioErrorMessage(e, fallback: 'Unable to terminate this contract.'),
      );
    }
  }

  Future<CompanyContractModel> fundContract(int contractId) async {
    final token = await _getToken();
    try {
      final response = await apiClient.post(
        ApiEndpoints.fundCompanyContract(contractId),
        options: _authOptions(token),
      );
      final body = _parseBody(response.data);
      _ensureSuccess(body, fallback: 'Unable to fund this contract.');
      final raw = body['data'];
      if (raw is! Map) {
        throw const CompanyContractException('Funded contract data is missing.');
      }
      return CompanyContractModel.fromJson(Map<String, dynamic>.from(raw));
    } on DioException catch (e) {
      throw CompanyContractException(
        _dioErrorMessage(e, fallback: 'Unable to fund this contract.'),
      );
    }
  }

  List<CompanyContractModel> _parseContractList(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((item) => CompanyContractModel.fromJson(Map<String, dynamic>.from(item)))
        .toList(growable: false);
  }

  Future<String> _getToken() async {
    final token = await TokenStorage.getAccessToken();
    if (token == null || token.trim().isEmpty) {
      throw const CompanyContractException('Authentication token not found.');
    }
    return token.trim();
  }

  Options _authOptions(String token) => Options(headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      });

  Options _jsonAuthOptions(String token) => Options(headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      });

  Map<String, dynamic> _parseBody(dynamic raw) {
    if (raw is! Map) {
      throw const CompanyContractException('Invalid server response.');
    }
    return Map<String, dynamic>.from(raw);
  }

  void _ensureSuccess(Map<String, dynamic> body, {required String fallback}) {
    if (body['success'] == true) return;
    throw CompanyContractException(_messageFromBody(body, fallback: fallback));
  }

  String _messageFromBody(Map<String, dynamic> body, {required String fallback}) {
    final errors = body['errors'];
    if (errors is Map) {
      for (final value in errors.values) {
        if (value is List && value.isNotEmpty) {
          final first = value.first.toString().trim();
          if (first.isNotEmpty) return first;
        }
        final text = value?.toString().trim() ?? '';
        if (text.isNotEmpty) return text;
      }
    }
    final message = body['message']?.toString().trim() ?? '';
    return message.isNotEmpty ? message : fallback;
  }

  String _dioErrorMessage(DioException error, {required String fallback}) {
    final raw = error.response?.data;
    if (raw is Map) {
      return _messageFromBody(Map<String, dynamic>.from(raw), fallback: fallback);
    }
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      return 'Connection timed out. Please try again.';
    }
    if (error.type == DioExceptionType.connectionError) {
      return 'No internet connection.';
    }
    return fallback;
  }

  int? _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }
}

class CompanyContractException implements Exception {
  final String message;
  const CompanyContractException(this.message);
  @override
  String toString() => message;
}

class CompanySubmissionReviewResult {
  final ContractSubmissionModel submission;
  final CompanyContractModel contract;

  const CompanySubmissionReviewResult({
    required this.submission,
    required this.contract,
  });
}
