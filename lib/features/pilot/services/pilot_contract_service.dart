import 'dart:io';

import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/storage/token_storage.dart';
import '../../company/models/contract_submission_model.dart';
import '../models/pilot_contract_model.dart';
import '../models/pilot_contract_location_model.dart';

class PilotContractService {
  final ApiClient apiClient;

  PilotContractService(this.apiClient);

  Future<List<PilotContractModel>> getContracts({
    String? status,
    int perPage = 50,
  }) async {
    final token = await _getToken();
    final cleanStatus = status?.trim().toLowerCase() ?? '';
    final safePerPage = perPage.clamp(1, 50).toInt();

    final contracts = <PilotContractModel>[];
    var page = 1;
    var lastPage = 1;

    try {
      do {
        final query = <String>[
          if (cleanStatus.isNotEmpty)
            'status=${Uri.encodeQueryComponent(cleanStatus)}',
          'per_page=$safePerPage',
          'page=$page',
        ].join('&');

        final response = await apiClient.get(
          '${ApiEndpoints.contracts}?$query',
          options: _authOptions(token),
        );

        final body = _parseBody(response.data);

        _ensureSuccess(
          body,
          fallback: 'Unable to load your contracts.',
        );

        final pageData = _extractPaginator(
          body['data'],
        );

        contracts.addAll(
          pageData.items.map(
            PilotContractModel.fromJson,
          ),
        );

        lastPage = pageData.lastPage < page
            ? page
            : pageData.lastPage;

        page++;
      } while (page <= lastPage);

      contracts.sort(
            (a, b) {
          final aDate =
              a.createdAt ??
                  DateTime.fromMillisecondsSinceEpoch(
                    0,
                  );

          final bDate =
              b.createdAt ??
                  DateTime.fromMillisecondsSinceEpoch(
                    0,
                  );

          return bDate.compareTo(aDate);
        },
      );

      return contracts;
    } on DioException catch (e) {
      throw PilotContractException(
        _dioErrorMessage(
          e,
          fallback:
          'Unable to load your contracts.',
        ),
      );
    }
  }

  Future<PilotContractModel> getContract(
      int contractId,
      ) async {
    final token = await _getToken();

    try {
      final response = await apiClient.get(
        ApiEndpoints.contract(
          contractId,
        ),
        options: _authOptions(token),
      );

      final body = _parseBody(
        response.data,
      );

      _ensureSuccess(
        body,
        fallback:
        'Unable to load this contract.',
      );

      return _parseContract(
        body['data'],
        fallback:
        'Contract details are missing.',
      );
    } on DioException catch (e) {
      throw PilotContractException(
        _dioErrorMessage(
          e,
          fallback:
          'Unable to load this contract.',
        ),
      );
    }
  }

  Future<PilotContractModel?>
  getContractForApplication(
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

  Future<PilotContractLocationModel?>
  getContractLocation(
      int contractId,
      ) async {
    final token = await _getToken();

    try {
      final response = await apiClient.get(
        ApiEndpoints.contractLocation(
          contractId,
        ),
        options: _authOptions(token),
      );

      final body = _parseBody(
        response.data,
      );

      _ensureSuccess(
        body,
        fallback:
        'Unable to load the exact job location.',
      );

      final raw = body['data'];

      if (raw is! Map) {
        return null;
      }

      return PilotContractLocationModel
          .fromJson(
        Map<String, dynamic>.from(
          raw,
        ),
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return null;
      }

      throw PilotContractException(
        _dioErrorMessage(
          e,
          fallback:
          'Unable to load the exact job location.',
        ),
      );
    }
  }

  Future<PilotContractModel> startWork(
      int contractId,
      ) async {
    final token = await _getToken();

    try {
      final response = await apiClient.post(
        ApiEndpoints.startContractWork(
          contractId,
        ),
        options: _authOptions(token),
      );

      final body = _parseBody(
        response.data,
      );

      _ensureSuccess(
        body,
        fallback:
        'Unable to start work on this contract.',
      );

      final actionContract =
      _parseContract(
        body['data'],
        fallback:
        'Started contract data is missing.',
      );

      try {
        final fresh =
        await getContract(
          contractId,
        );

        if (fresh.isInProgress ||
            fresh.startedAt != null) {
          return fresh;
        }
      } catch (_) {
        // Keep the successful action response.
      }

      return actionContract.copyWith(
        status: 'in_progress',
        startedAt:
        actionContract.startedAt ??
            DateTime.now().toUtc(),
        updatedAt:
        DateTime.now().toUtc(),
      );
    } on DioException catch (e) {
      throw PilotContractException(
        _dioErrorMessage(
          e,
          fallback:
          'Unable to start work on this contract.',
        ),
      );
    }
  }

  Future<List<ContractSubmissionModel>>
  getSubmissions(
      int contractId,
      ) async {
    final token = await _getToken();

    try {
      final response = await apiClient.get(
        ApiEndpoints.contractSubmissions(
          contractId,
        ),
        options: _authOptions(token),
      );

      final body = _parseBody(
        response.data,
      );

      _ensureSuccess(
        body,
        fallback:
        'Unable to load work submissions.',
      );

      final payload = body['data'];
      // Accept both plain Laravel lists and nested paginated data.
      final raw = payload is Map && payload['data'] is List
          ? payload['data']
          : payload;
      if (raw is! List) return const [];

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
      throw PilotContractException(
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
    final token = await _getToken();

    try {
      final response = await apiClient.get(
        ApiEndpoints.contractSubmission(
          contractId,
          submissionId,
        ),
        options: _authOptions(token),
      );

      final body = _parseBody(
        response.data,
      );

      _ensureSuccess(
        body,
        fallback:
        'Unable to load this work submission.',
      );

      final raw = body['data'];

      if (raw is! Map) {
        throw const PilotContractException(
          'Work submission data is missing.',
        );
      }

      return ContractSubmissionModel.fromJson(
        Map<String, dynamic>.from(
          raw,
        ),
      );
    } on DioException catch (e) {
      throw PilotContractException(
        _dioErrorMessage(
          e,
          fallback:
          'Unable to load this work submission.',
        ),
      );
    }
  }

  Future<PilotSubmitWorkResult> submitWork(
      int contractId, {
        String? notes,
        List<String> filePaths = const [],
      }) async {
    if (filePaths.length > 10) {
      throw const PilotContractException(
        'You can upload up to 10 files per submission.',
      );
    }

    final cleanNotes =
        notes?.trim() ?? '';

    if (cleanNotes.length > 2000) {
      throw const PilotContractException(
        'Submission notes cannot exceed 2000 characters.',
      );
    }

    final multipartFiles =
    <MultipartFile>[];

    for (final rawPath in filePaths) {
      final path =
      rawPath.trim();

      if (path.isEmpty) {
        continue;
      }

      final file =
      File(path);

      if (!await file.exists()) {
        throw PilotContractException(
          'Selected file was not found: '
              '${file.uri.pathSegments.isEmpty ? path : file.uri.pathSegments.last}',
        );
      }

      final size =
      await file.length();

      if (size >
          20 * 1024 * 1024) {
        throw const PilotContractException(
          'Each submission file must be 20 MB or smaller.',
        );
      }

      final filename =
      file.uri.pathSegments.isEmpty
          ? 'deliverable'
          : file.uri.pathSegments.last;

      multipartFiles.add(
        await MultipartFile.fromFile(
          path,
          filename: filename,
        ),
      );
    }

    final formData =
    FormData();

    if (cleanNotes.isNotEmpty) {
      formData.fields.add(
        MapEntry(
          'notes',
          cleanNotes,
        ),
      );
    }

    for (var i = 0;
    i < multipartFiles.length;
    i++) {
      formData.files.add(
        MapEntry(
          'files[$i]',
          multipartFiles[i],
        ),
      );
    }

    print(
      '================ SUBMIT WORK MULTIPART ================',
    );
    print(
      'NOTES FIELD PRESENT: ${cleanNotes.isNotEmpty}',
    );
    print(
      'FILES COUNT: ${formData.files.length}',
    );
    print(
      'FILE KEYS: ${formData.files.map((e) => e.key).toList()}',
    );
    print(
      '=======================================================',
    );

    final token =
    await _getToken();

    try {
      final response =
      await apiClient.post(
        ApiEndpoints.contractSubmissions(
          contractId,
        ),
        data: formData,
        options: Options(
          contentType:
          Headers
              .multipartFormDataContentType,
          headers: {
            'Accept':
            'application/json',
            'Authorization':
            'Bearer $token',
          },
        ),
      );

      final body = _parseBody(
        response.data,
      );

      _ensureSuccess(
        body,
        fallback:
        'Unable to submit completed work.',
      );

      final raw = body['data'];

      if (raw is! Map) {
        throw const PilotContractException(
          'Submitted work data is missing.',
        );
      }

      final submission =
      ContractSubmissionModel.fromJson(
        Map<String, dynamic>.from(
          raw,
        ),
      );

      // The POST 201 is authoritative proof that the work was accepted.
      // Do NOT wait for GET /contract here: it may be slow, unavailable or
      // eventually consistent. The detail screen updates immediately and
      // refreshes in the background without asking the user to POST again.
      return PilotSubmitWorkResult(submission: submission, contract: null);
    } on DioException catch (e) {
      // 409/422 (or a lost response) can occur when the upload was actually
      // accepted but the app did not receive the original response. Confirm
      // with GET before presenting the action as failed. Never POST twice.
      if (e.response?.statusCode == 409 || e.response?.statusCode == 422 ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError) {
        final restored = await _recoverSubmittedWork(contractId);
        if (restored != null) return restored;
      }
      throw PilotContractException(
        _dioErrorMessage(e, fallback: 'Unable to submit completed work.'),
      );
    }
  }

  Future<PilotSubmitWorkResult?> _recoverSubmittedWork(int contractId) async {
    try {
      final rounds = await getSubmissions(contractId);
      if (rounds.isEmpty) return null;
      final last = rounds.last;
      if (!last.isSubmitted || last.contractId != contractId) return null;
      PilotContractModel? contract;
      try {
        contract = await getContract(contractId);
      } catch (_) {
        // A verified submitted round is enough to stop repeat uploads.
      }
      return PilotSubmitWorkResult(submission: last, contract: contract);
    } catch (_) {
      return null;
    }
  }

  Future<PilotContractModel>
  acceptContract(
      int contractId,
      ) async {
    final token =
    await _getToken();

    try {
      final response =
      await apiClient.post(
        ApiEndpoints.acceptContract(
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
        'Unable to accept this contract.',
      );

      return _parseContract(
        body['data'],
        fallback:
        'Accepted contract data is missing.',
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 422 &&
          ApiClient.errorCodeFromDio(e) == 'LEGAL_IDENTITY_NOT_VERIFIED') {
        throw const PilotContractException('LEGAL_IDENTITY_NOT_VERIFIED');
      }
      throw PilotContractException(
        _dioErrorMessage(
          e,
          fallback:
          'Unable to accept this contract.',
        ),
      );
    }
  }

  Future<PilotContractModel>
  rejectContract(
      int contractId, {
        String? reason,
      }) async {
    final token =
    await _getToken();

    final cleanReason =
        reason?.trim() ?? '';

    if (cleanReason.length > 2000) {
      throw const PilotContractException(
        'Rejection reason cannot exceed 2000 characters.',
      );
    }

    try {
      final response =
      await apiClient.post(
        ApiEndpoints.rejectContract(
          contractId,
        ),
        data:
        cleanReason.isEmpty
            ? null
            : <String, dynamic>{
          'reason':
          cleanReason,
        },
        options:
        cleanReason.isEmpty
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
        'Unable to reject this contract.',
      );

      return _parseContract(
        body['data'],
        fallback:
        'Rejected contract data is missing.',
      );
    } on DioException catch (e) {
      throw PilotContractException(
        _dioErrorMessage(
          e,
          fallback:
          'Unable to reject this contract.',
        ),
      );
    }
  }

  // ===========================================================================
  // PHASE 4 - REVIEW COMPANY
  // ===========================================================================

  Future<String> submitReview(
      int contractId, {
        required int rating,
        String? comment,
      }) async {
    if (contractId <= 0) {
      throw const PilotContractException(
        'Invalid contract.',
      );
    }

    if (rating < 1 || rating > 5) {
      throw const PilotContractException(
        'Rating must be between 1 and 5.',
      );
    }

    final cleanComment =
        comment?.trim() ?? '';

    if (cleanComment.length > 2000) {
      throw const PilotContractException(
        'Review comment cannot exceed 2000 characters.',
      );
    }

    final token =
    await _getToken();

    final data =
    <String, dynamic>{
      'rating': rating,
      if (cleanComment.isNotEmpty)
        'comment': cleanComment,
    };

    try {
      final response =
      await apiClient.post(
        ApiEndpoints.contractReview(
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
      throw PilotContractException(
        _dioErrorMessage(
          e,
          fallback:
          'Unable to submit your review.',
        ),
      );
    }
  }

  _ContractPage _extractPaginator(
      dynamic raw,
      ) {
    if (raw is List) {
      return _ContractPage(
        items: raw
            .whereType<Map>()
            .map(
              (item) =>
          Map<String, dynamic>.from(
            item,
          ),
        )
            .toList(),
        lastPage: 1,
      );
    }

    if (raw is Map) {
      final map =
      Map<String, dynamic>.from(
        raw,
      );

      final nested =
      map['data'];

      if (nested is List) {
        return _ContractPage(
          items: nested
              .whereType<Map>()
              .map(
                (item) =>
            Map<String, dynamic>.from(
              item,
            ),
          )
              .toList(),
          lastPage:
          _asInt(
            map['last_page'],
          ) ??
              1,
        );
      }

      final items =
      map.values
          .whereType<Map>()
          .map(
            (item) =>
        Map<String, dynamic>.from(
          item,
        ),
      )
          .where(
            (item) =>
            item.containsKey(
              'id',
            ),
      )
          .toList();

      if (items.isNotEmpty) {
        return _ContractPage(
          items: items,
          lastPage: 1,
        );
      }
    }

    if (raw == null) {
      return const _ContractPage(
        items: [],
        lastPage: 1,
      );
    }

    throw const PilotContractException(
      'Contract list data is invalid.',
    );
  }

  PilotContractModel _parseContract(
      dynamic raw, {
        required String fallback,
      }) {
    if (raw is Map) {
      return PilotContractModel.fromJson(
        Map<String, dynamic>.from(
          raw,
        ),
      );
    }

    throw PilotContractException(
      fallback,
    );
  }

  Map<String, dynamic> _parseBody(
      dynamic raw,
      ) {
    if (raw is! Map) {
      throw const PilotContractException(
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

    throw PilotContractException(
      _messageFromBody(
        body,
        fallback: fallback,
      ),
    );
  }

  Future<String> _getToken() async {
    final token =
    await TokenStorage
        .getAccessToken();

    if (token == null ||
        token.trim().isEmpty) {
      throw const PilotContractException(
        'Authentication token not found.',
      );
    }

    return token.trim();
  }

  Options _authOptions(
      String token,
      ) {
    return Options(
      headers: {
        'Accept':
        'application/json',
        'Authorization':
        'Bearer $token',
      },
    );
  }

  Options _jsonAuthOptions(
      String token,
      ) {
    return Options(
      headers: {
        'Accept':
        'application/json',
        'Content-Type':
        'application/json',
        'Authorization':
        'Bearer $token',
      },
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

        if (value != null) {
          final text =
          value
              .toString()
              .trim();

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

  int? _asInt(
      dynamic value,
      ) {
    if (value == null) {
      return null;
    }

    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(
      value.toString(),
    );
  }
}

class _ContractPage {
  final List<Map<String, dynamic>> items;
  final int lastPage;

  const _ContractPage({
    required this.items,
    required this.lastPage,
  });
}

class PilotContractException
    implements Exception {
  final String message;

  const PilotContractException(
      this.message,
      );

  @override
  String toString() =>
      message;
}

class PilotSubmitWorkResult {
  final ContractSubmissionModel submission;
  // Optional: upload success must not depend on a second network request.
  final PilotContractModel? contract;

  const PilotSubmitWorkResult({
    required this.submission,
    required this.contract,
  });
}