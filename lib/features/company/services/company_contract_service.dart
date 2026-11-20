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

  Future<List<CompanyContractModel>> getContracts({
    String? status,
  }) async {
    final token = await _getToken();
    final all = <CompanyContractModel>[];
    final cleanStatus =
        status?.trim().toLowerCase() ?? '';

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

        final body =
        _parseBody(response.data);

        _ensureSuccess(
          body,
          fallback:
          'Unable to load company contracts.',
        );

        final rawData =
        body['data'];

        List<CompanyContractModel>
        pageItems;

        if (rawData is Map) {
          final paginator =
          Map<String, dynamic>.from(
            rawData,
          );

          pageItems =
              _parseContractList(
                paginator['data'],
              );

          knownLastPage =
              _asInt(
                paginator['last_page'],
              ) ??
                  _asInt(
                    paginator['current_page'],
                  ) ??
                  knownLastPage;
        } else if (rawData is List) {
          pageItems =
              _parseContractList(
                rawData,
              );

          final rawMeta =
          body['meta'];

          if (rawMeta is Map) {
            final meta =
            Map<String, dynamic>.from(
              rawMeta,
            );

            knownLastPage =
                _asInt(
                  meta['last_page'],
                ) ??
                    knownLastPage;
          }
        } else {
          throw const CompanyContractException(
            'Company contracts data is missing.',
          );
        }

        all.addAll(
          pageItems,
        );

        if (knownLastPage != null) {
          if (page >=
              knownLastPage!) {
            break;
          }
        } else if (pageItems.length <
            perPage) {
          break;
        }

        if (page >= 100) {
          break;
        }

        page++;
      }

      final byId =
      <int, CompanyContractModel>{};

      for (final contract in all) {
        if (contract.id > 0) {
          byId[contract.id] =
              contract;
        }
      }

      final result =
      byId.isEmpty
          ? all
          : byId.values.toList();

      result.sort(
            (a, b) {
          final ad =
              a.updatedAt ??
                  a.createdAt ??
                  DateTime
                      .fromMillisecondsSinceEpoch(
                    0,
                  );

          final bd =
              b.updatedAt ??
                  b.createdAt ??
                  DateTime
                      .fromMillisecondsSinceEpoch(
                    0,
                  );

          return bd.compareTo(ad);
        },
      );

      return result;
    } on DioException catch (e) {
      throw CompanyContractException(
        _dioErrorMessage(
          e,
          fallback:
          'Unable to load company contracts.',
        ),
      );
    }
  }

  Future<CompanyContractModel>
  getContract(
      int contractId,
      ) async {
    final token =
    await _getToken();

    try {
      final response =
      await apiClient.get(
        ApiEndpoints.companyContract(
          contractId,
        ),
        options:
        _authOptions(token),
      );

      final body =
      _parseBody(
        response.data,
      );

      _ensureSuccess(
        body,
        fallback:
        'Unable to load this contract.',
      );

      final raw =
      body['data'];

      if (raw is! Map) {
        throw const CompanyContractException(
          'Contract details are missing.',
        );
      }

      return CompanyContractModel.fromJson(
        Map<String, dynamic>.from(
          raw,
        ),
      );
    } on DioException catch (e) {
      throw CompanyContractException(
        _dioErrorMessage(
          e,
          fallback:
          'Unable to load this contract.',
        ),
      );
    }
  }

  Future<CompanyContractModel?>
  findContractForApplication(
      int applicationId,
      ) async {
    if (applicationId <= 0) {
      return null;
    }

    final contracts =
    await getContracts();

    for (final contract in contracts) {
      if (contract.jobApplicationId ==
          applicationId) {
        return contract;
      }
    }

    return null;
  }

  Future<CompanyContractModel?>
  findExistingContract({
    required int applicationId,
    required int jobId,
  }) async {
    if (applicationId <= 0 &&
        jobId <= 0) {
      return null;
    }

    CompanyContractModel? matchFrom(
        List<CompanyContractModel>
        contracts,
        ) {
      CompanyContractModel?
      sameJobFallback;

      for (final contract
      in contracts) {
        if (applicationId > 0 &&
            contract.jobApplicationId ==
                applicationId) {
          return contract;
        }

        if (sameJobFallback ==
            null &&
            jobId > 0 &&
            contract.jobPostingId ==
                jobId &&
            !contract.isTerminal) {
          sameJobFallback =
              contract;
        }
      }

      return sameJobFallback;
    }

    final allContracts =
    await getContracts();

    final direct =
    matchFrom(allContracts);

    if (direct != null) {
      return direct;
    }

    // The unfiltered paginated collection already contains all statuses.
    // A second pass across five filtered collections used to multiply every
    // 503/timeout and delay contract creation by over a minute.
    // Laravel's create endpoint is still authoritative about duplicates.

    return null;
  }

  Future<CompanyContractModel?>
  findOpenContractForJob(
      int jobId,
      ) async {
    if (jobId <= 0) {
      return null;
    }

    final contracts =
    await getContracts();

    for (final contract in contracts) {
      if (contract.jobPostingId ==
          jobId &&
          !contract.isTerminal) {
        return contract;
      }
    }

    return null;
  }

  Future<CompanyContractLocationModel?>
  getContractLocation(
      int contractId,
      ) async {
    final token =
    await _getToken();

    Future<CompanyContractLocationModel?>
    read(
        String endpoint,
        ) async {
      final response =
      await apiClient.get(
        endpoint,
        options:
        _authOptions(token),
      );

      final body =
      _parseBody(
        response.data,
      );

      _ensureSuccess(
        body,
        fallback:
        'Unable to load the exact job location.',
      );

      final raw =
      body['data'];

      if (raw is! Map) {
        return null;
      }

      return CompanyContractLocationModel
          .fromJson(
        Map<String, dynamic>.from(
          raw,
        ),
      );
    }

    try {
      return await read(
        ApiEndpoints
            .companyContractLocation(
          contractId,
        ),
      );
    } on DioException catch (e) {
      final status =
          e.response?.statusCode;

      if (status == 403 ||
          status == 404) {
        try {
          return await read(
            ApiEndpoints
                .contractLocation(
              contractId,
            ),
          );
        } on DioException catch (
        fallbackError) {
          if (fallbackError
              .response
              ?.statusCode ==
              404) {
            return null;
          }

          throw CompanyContractException(
            _dioErrorMessage(
              fallbackError,
              fallback:
              'Unable to load the exact job location.',
            ),
          );
        }
      }

      throw CompanyContractException(
        _dioErrorMessage(
          e,
          fallback:
          'Unable to load the exact job location.',
        ),
      );
    }
  }

  Future<CompanyContractLocationModel>
  saveContractLocation(
      int contractId,
      CompanyContractLocationRequest
      request,
      ) async {
    final token =
    await _getToken();

    if (request.address
        .trim()
        .isEmpty) {
      throw const CompanyContractException(
        'Exact address is required.',
      );
    }

    if (request.address
        .trim()
        .length >
        500) {
      throw const CompanyContractException(
        'Address cannot exceed 500 characters.',
      );
    }

    if (request.latitude < -90 ||
        request.latitude > 90) {
      throw const CompanyContractException(
        'Latitude must be between -90 and 90.',
      );
    }

    if (request.longitude < -180 ||
        request.longitude > 180) {
      throw const CompanyContractException(
        'Longitude must be between -180 and 180.',
      );
    }

    if ((request.notes ?? '')
        .trim()
        .length >
        2000) {
      throw const CompanyContractException(
        'Location notes cannot exceed 2000 characters.',
      );
    }

    try {
      final response =
      await Dio().put<dynamic>(
        '${ApiEndpoints.baseUrl}'
            '${ApiEndpoints.companyContractLocation(contractId)}',
        data: request.toJson(),
        options:
        _jsonAuthOptions(token),
      );

      final body =
      _parseBody(
        response.data,
      );

      _ensureSuccess(
        body,
        fallback:
        'Unable to save the exact job location.',
      );

      final raw =
      body['data'];

      if (raw is! Map) {
        throw const CompanyContractException(
          'Saved location data is missing.',
        );
      }

      return CompanyContractLocationModel
          .fromJson(
        Map<String, dynamic>.from(
          raw,
        ),
      );
    } on DioException catch (e) {
      throw CompanyContractException(
        _dioErrorMessage(
          e,
          fallback:
          'Unable to save the exact job location.',
        ),
      );
    }
  }

  Future<List<ContractSubmissionModel>>
  getSubmissions(
      int contractId,
      ) async {
    final token =
    await _getToken();

    try {
      final response =
      await apiClient.get(
        ApiEndpoints
            .companyContractSubmissions(
          contractId,
        ),
        options:
        _authOptions(token),
      );

      final body =
      _parseBody(
        response.data,
      );

      _ensureSuccess(
        body,
        fallback:
        'Unable to load work submissions.',
      );

      final raw =
      body['data'];

      if (raw is! List) {
        return const [];
      }

      return raw
          .whereType<Map>()
          .map(
            (item) =>
            ContractSubmissionModel
                .fromJson(
              Map<String, dynamic>.from(
                item,
              ),
            ),
      )
          .toList(
        growable: false,
      );
    } on DioException catch (e) {
      throw CompanyContractException(
        _dioErrorMessage(
          e,
          fallback:
          'Unable to load work submissions.',
        ),
      );
    }
  }

  Future<ContractSubmissionModel>
  getSubmission(
      int contractId,
      int submissionId,
      ) async {
    final token =
    await _getToken();

    try {
      final response =
      await apiClient.get(
        ApiEndpoints
            .companyContractSubmission(
          contractId,
          submissionId,
        ),
        options:
        _authOptions(token),
      );

      final body =
      _parseBody(
        response.data,
      );

      _ensureSuccess(
        body,
        fallback:
        'Unable to load this submission.',
      );

      final raw =
      body['data'];

      if (raw is! Map) {
        throw const CompanyContractException(
          'Work submission data is missing.',
        );
      }

      return ContractSubmissionModel
          .fromJson(
        Map<String, dynamic>.from(
          raw,
        ),
      );
    } on DioException catch (e) {
      throw CompanyContractException(
        _dioErrorMessage(
          e,
          fallback:
          'Unable to load this submission.',
        ),
      );
    }
  }

  Future<CompanySubmissionReviewResult>
  approveSubmission(
      int contractId,
      int submissionId, {
        String? reviewNotes,
      }) async {
    final cleanNotes =
        reviewNotes?.trim() ?? '';

    if (cleanNotes.length > 2000) {
      throw const CompanyContractException(
        'Review notes cannot exceed 2000 characters.',
      );
    }

    final token =
    await _getToken();

    try {
      final response =
      await apiClient.post(
        ApiEndpoints
            .approveCompanyContractSubmission(
          contractId,
          submissionId,
        ),
        data:
        cleanNotes.isEmpty
            ? null
            : <String, dynamic>{
          'review_notes':
          cleanNotes,
        },
        options:
        cleanNotes.isEmpty
            ? _authOptions(token)
            : _jsonAuthOptions(
          token,
        ),
      );

      final body =
      _parseBody(
        response.data,
      );

      _ensureSuccess(
        body,
        fallback:
        'Unable to approve this submission.',
      );

      final raw =
      body['data'];

      if (raw is! Map) {
        throw const CompanyContractException(
          'Reviewed submission data is missing.',
        );
      }

      final submission =
      ContractSubmissionModel.fromJson(
        Map<String, dynamic>.from(
          raw,
        ),
      );

      final contract =
      await getContract(
        contractId,
      );

      return CompanySubmissionReviewResult(
        submission: submission,
        contract: contract,
      );
    } on DioException catch (e) {
      throw CompanyContractException(
        _dioErrorMessage(
          e,
          fallback:
          'Unable to approve this submission.',
        ),
      );
    }
  }

  Future<CompanySubmissionReviewResult>
  requestRevision(
      int contractId,
      int submissionId, {
        required String reviewNotes,
      }) async {
    final cleanNotes =
    reviewNotes.trim();

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

    final token =
    await _getToken();

    try {
      final response =
      await apiClient.post(
        ApiEndpoints
            .requestRevisionCompanyContractSubmission(
          contractId,
          submissionId,
        ),
        data:
        <String, dynamic>{
          'review_notes':
          cleanNotes,
        },
        options:
        _jsonAuthOptions(token),
      );

      final body =
      _parseBody(
        response.data,
      );

      _ensureSuccess(
        body,
        fallback:
        'Unable to request a revision.',
      );

      final raw =
      body['data'];

      if (raw is! Map) {
        throw const CompanyContractException(
          'Reviewed submission data is missing.',
        );
      }

      final submission =
      ContractSubmissionModel.fromJson(
        Map<String, dynamic>.from(
          raw,
        ),
      );

      final contract =
      await getContract(
        contractId,
      );

      return CompanySubmissionReviewResult(
        submission: submission,
        contract: contract,
      );
    } on DioException catch (e) {
      throw CompanyContractException(
        _dioErrorMessage(
          e,
          fallback:
          'Unable to request a revision.',
        ),
      );
    }
  }

  Future<CompanyContractModel>
  cancelContract(
      int contractId, {
        String? reason,
      }) async {
    final cleanReason =
        reason?.trim() ?? '';

    if (cleanReason.isEmpty || cleanReason.length > 2000) {
      throw const CompanyContractException(
        'A cancellation reason is required (maximum 2000 characters).',
      );
    }

    final token =
    await _getToken();

    try {
      final response =
      await apiClient.post(
        ApiEndpoints
            .cancelCompanyContract(
          contractId,
        ),
        data: <String, dynamic>{'reason': cleanReason},
        options: _jsonAuthOptions(token),
      );

      final body =
      _parseBody(
        response.data,
      );

      _ensureSuccess(
        body,
        fallback:
        'Unable to cancel this contract.',
      );

      final raw =
      body['data'];

      if (raw is! Map) {
        throw const CompanyContractException(
          'Cancelled contract data is missing.',
        );
      }

      return CompanyContractModel.fromJson(
        Map<String, dynamic>.from(
          raw,
        ),
      );
    } on DioException catch (e) {
      throw CompanyContractException(
        _dioErrorMessage(
          e,
          fallback:
          'Unable to cancel this contract.',
        ),
      );
    }
  }

  Future<CompanyContractModel>
  terminateContract(
      int contractId, {
        required String reason,
      }) async {
    final cleanReason =
    reason.trim();

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

    final token =
    await _getToken();

    try {
      final response =
      await apiClient.post(
        ApiEndpoints
            .terminateCompanyContract(
          contractId,
        ),
        data:
        <String, dynamic>{
          'reason':
          cleanReason,
        },
        options:
        _jsonAuthOptions(token),
      );

      final body =
      _parseBody(
        response.data,
      );

      _ensureSuccess(
        body,
        fallback:
        'Unable to terminate this contract.',
      );

      final raw =
      body['data'];

      if (raw is! Map) {
        throw const CompanyContractException(
          'Terminated contract data is missing.',
        );
      }

      return CompanyContractModel.fromJson(
        Map<String, dynamic>.from(
          raw,
        ),
      );
    } on DioException catch (e) {
      throw CompanyContractException(
        _dioErrorMessage(
          e,
          fallback:
          'Unable to terminate this contract.',
        ),
      );
    }
  }

  // Stripe funding is now handled by CompanyCollectionService:
  // POST /quote -> POST /fund {quote_reference, method: redirect}.
  // Do not issue an unquoted funding POST from this service.

  // ===========================================================================
  // PHASE 4 - REVIEW PILOT
  // ===========================================================================

  Future<String> submitReview(
      int contractId, {
        required int rating,
        String? comment,
      }) async {
    if (contractId <= 0) {
      throw const CompanyContractException(
        'Invalid contract.',
      );
    }

    if (rating < 1 ||
        rating > 5) {
      throw const CompanyContractException(
        'Rating must be between 1 and 5.',
      );
    }

    final cleanComment =
        comment?.trim() ?? '';

    if (cleanComment.length > 2000) {
      throw const CompanyContractException(
        'Review comment cannot exceed 2000 characters.',
      );
    }

    final token =
    await _getToken();

    final data =
    <String, dynamic>{
      'rating': rating,
      if (cleanComment.isNotEmpty)
        'comment':
        cleanComment,
    };

    try {
      final response =
      await apiClient.post(
        ApiEndpoints
            .companyContractReview(
          contractId,
        ),
        data: data,
        options:
        _jsonAuthOptions(token),
      );

      final body =
      _parseBody(
        response.data,
      );

      _ensureSuccess(
        body,
        fallback:
        'Unable to submit your review.',
      );

      final message =
      body['message']
          ?.toString()
          .trim();

      if (message != null &&
          message.isNotEmpty) {
        return message;
      }

      return 'Review submitted.';
    } on DioException catch (e) {
      throw CompanyContractException(
        _dioErrorMessage(
          e,
          fallback:
          'Unable to submit your review.',
        ),
      );
    }
  }

  List<CompanyContractModel>
  _parseContractList(
      dynamic raw,
      ) {
    if (raw is! List) {
      return const [];
    }

    return raw
        .whereType<Map>()
        .map(
          (item) =>
          CompanyContractModel
              .fromJson(
            Map<String, dynamic>.from(
              item,
            ),
          ),
    )
        .toList(
      growable: false,
    );
  }

  Future<String> _getToken() async {
    final token =
    await TokenStorage
        .getAccessToken();

    if (token == null ||
        token.trim().isEmpty) {
      throw const CompanyContractException(
        'Authentication token not found.',
      );
    }

    return token.trim();
  }

  Options _authOptions(
      String token,
      ) =>
      Options(
        headers: {
          'Accept':
          'application/json',
          'Authorization':
          'Bearer $token',
        },
      );

  Options _jsonAuthOptions(
      String token,
      ) =>
      Options(
        headers: {
          'Accept':
          'application/json',
          'Content-Type':
          'application/json',
          'Authorization':
          'Bearer $token',
        },
      );

  Map<String, dynamic> _parseBody(
      dynamic raw,
      ) {
    if (raw is! Map) {
      throw const CompanyContractException(
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

    throw CompanyContractException(
      _messageFromBody(
        body,
        fallback: fallback,
      ),
    );
  }

  String _messageFromBody(
      Map<String, dynamic> body, {
        required String fallback,
      }) {
    final errors =
    body['errors'];

    if (errors is Map) {
      for (final value
      in errors.values) {
        if (value is List &&
            value.isNotEmpty) {
          final first =
          value.first
              .toString()
              .trim();

          if (first.isNotEmpty) {
            return first;
          }
        }

        final text =
            value
                ?.toString()
                .trim() ??
                '';

        if (text.isNotEmpty) {
          return text;
        }
      }
    }

    final message =
        body['message']
            ?.toString()
            .trim() ??
            '';

    return message.isNotEmpty
        ? message
        : fallback;
  }

  String _dioErrorMessage(
      DioException error, {
        required String fallback,
      }) {
    final status = error.response?.statusCode;
    if (status == 503 || status == 502 || status == 504 || status == 500) {
      return 'The server is temporarily unavailable. Please try again.';
    }
    if (status == 429) {
      return 'Too many requests. Please try again shortly.';
    }
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
            .connectionTimeout ||
        error.type ==
            DioExceptionType
                .receiveTimeout) {
      return 'Connection timed out. Please try again.';
    }

    if (error.type ==
        DioExceptionType
            .connectionError) {
      return 'No internet connection.';
    }

    return fallback;
  }

  int? _asInt(
      dynamic value,
      ) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(
      value?.toString() ?? '',
    );
  }
}

class CompanyContractException
    implements Exception {
  final String message;

  const CompanyContractException(
      this.message,
      );

  @override
  String toString() =>
      message;
}

class CompanySubmissionReviewResult {
  final ContractSubmissionModel
  submission;

  final CompanyContractModel
  contract;

  const CompanySubmissionReviewResult({
    required this.submission,
    required this.contract,
  });
}