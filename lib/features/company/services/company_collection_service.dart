import 'package:dio/dio.dart';

import 'stripe_checkout_url.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/storage/token_storage.dart';

/// Sanitized payment failure. Never logs request bodies or Stripe tokens.
/// A 422 can mean many things (contract state, price policy, expired quote),
/// so the backend's actual message is kept instead of guessing the cause.
class CompanyPaymentApiException implements Exception {
  const CompanyPaymentApiException({
    required this.operation,
    required this.statusCode,
    required this.message,
    this.errorCode,
    this.requestId,
    this.retryAfterSeconds,
  });

  final String operation;
  final int? statusCode;
  final String message;
  final String? errorCode;
  final String? requestId;
  final int? retryAfterSeconds;

  /// A 422 pending-attempt conflict is NOT an expired quote.
  bool get isPendingAttemptConflict => statusCode == 422 &&
      RegExp(r'\battempt\s*#?\s*\d+\s+is\s+still\s+pending\b',
          caseSensitive: false).hasMatch(message);

  int? get pendingAttemptId {
    final match = RegExp(r'\battempt\s*#\s*(\d+)',
        caseSensitive: false).firstMatch(message);
    return match == null ? null : int.tryParse(match.group(1)!);
  }

  static CompanyPaymentApiException fromDio(
    DioException error, {
    required String operation,
  }) {
    final response = error.response;
    final data = response?.data;
    final body = data is Map ? data : const <String, dynamic>{};
    final rawMessage = body['message'];
    var candidate = rawMessage is String ? rawMessage.trim() : '';
    final errors = body['errors'];
    if ((candidate.isEmpty || candidate.toLowerCase().contains('given data')) &&
        errors is Map) {
      for (final value in errors.values) {
        final first = value is List && value.isNotEmpty
            ? value.first
            : value;
        if (first is String && first.trim().isNotEmpty) {
          candidate = first.trim();
          break;
        }
      }
    }
    // Do not surface HTML error pages or long internal traces to end users.
    final safeMessage = candidate.isNotEmpty &&
            candidate.length <= 220 &&
            !candidate.contains('<') &&
            !candidate.contains('\n')
        ? candidate
        : 'The server could not complete the payment request.';
    final rawCode = body['error_code'] ?? body['code'];
    final code = rawCode is String && rawCode.length <= 80 ? rawCode : null;
    final requestId = response?.headers.value('x-request-id') ??
        response?.headers.value('cf-ray');
    final rawRetry = response?.headers.value('retry-after');
    final retrySeconds = int.tryParse(rawRetry ?? '');
    return CompanyPaymentApiException(
      operation: operation,
      statusCode: response?.statusCode,
      message: safeMessage,
      errorCode: code,
      requestId: requestId,
      retryAfterSeconds: retrySeconds == null
          ? null
          : retrySeconds.clamp(1, 120).toInt(),
    );
  }

  @override
  String toString() => 'CompanyPaymentApiException('
      'operation=$operation, http=$statusCode, code=$errorCode, '
      'requestId=$requestId)';
}

/// Parses payment metadata returned by /fund or /contracts/{id}. The payment
/// provider, not the client, is the authority for whether funds arrived.
class ContractFundingSnapshot {
  const ContractFundingSnapshot({
    required this.contractStatus,
    required this.paymentStatus,
    this.paymentId,
    this.checkoutUri,
    this.isTestSession = false,
  });

  final String contractStatus;
  final String paymentStatus;
  final int? paymentId;
  final Uri? checkoutUri;
  final bool isTestSession;

  bool get isFunded => const {
        'active', 'in_progress', 'submitted', 'completed',
      }.contains(contractStatus);

  bool get hasPendingPayment => !isFunded &&
      const {'pending', 'processing', 'requires_action'}
          .contains(paymentStatus);

  /// Read a provider-issued Checkout redirect without trusting arbitrary URLs.
  /// Response envelopes differ across /fund, contract details and payment rows.
  /// Never turn a session ID into a URL: the complete URL must be present.
  static Uri? extractCheckoutUri(Object? raw, {int depth = 0}) {
    if (depth > 5) return null;
    if (raw is String) {
      final uri = Uri.tryParse(raw.trim());
      return isTrustedStripeCheckoutUri(uri) ? uri : null;
    }
    if (raw is! Map) return null;
    final map = Map<String, dynamic>.from(raw);
    // Prefer named provider redirect fields. Never use payment receipt URLs.
    for (final key in const [
      'checkout_url', 'checkoutUrl', 'redirect_url', 'redirectUrl',
      'payment_url', 'client_secret_url', 'url', 'token',
    ]) {
      final uri = extractCheckoutUri(map[key], depth: depth + 1);
      if (uri != null) return uri;
    }
    for (final key in const [
      'client_action', 'next_action', 'payment', 'attempt',
      'checkout', 'provider', 'provider_data', 'data',
      'payment_attempt', 'collection', 'session',
    ]) {
      final uri = extractCheckoutUri(map[key], depth: depth + 1);
      if (uri != null) return uri;
    }
    return null;
  }

  static ContractFundingSnapshot fromResponse(Object? response) {
    if (response is! Map) {
      throw const FormatException('Unexpected contract response.');
    }
    final payload = response['data'];
    if (payload is! Map) {
      throw const FormatException('Missing contract response data.');
    }
    final contract = Map<String, dynamic>.from(payload);
    Map<String, dynamic>? payment;
    final directPayment = contract['payment'];
    if (directPayment is Map) {
      payment = Map<String, dynamic>.from(directPayment);
    } else if (contract['payments'] is List) {
      final items = (contract['payments'] as List)
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
      if (items.isNotEmpty) {
        items.sort((a, b) {
          final ai = int.tryParse('${a['id']}') ?? 0;
          final bi = int.tryParse('${b['id']}') ?? 0;
          return ai.compareTo(bi);
        });
        payment = items.last;
      }
    }

    final actionRaw = payment?['client_action'];
    final action = actionRaw is Map ? actionRaw : const <String, dynamic>{};
    // Some API versions put client_action directly under data, not payment.
    final checkout = extractCheckoutUri(payment) ?? extractCheckoutUri(contract);
    final idRaw = payment?['id'] ?? payment?['attempt_id'];
    final id = idRaw is int ? idRaw : int.tryParse('$idRaw');
    final sessionId = action['session_id']?.toString() ?? '';
    return ContractFundingSnapshot(
      contractStatus: (contract['status'] ?? '').toString().toLowerCase(),
      paymentStatus: (payment?['status'] ?? '').toString().toLowerCase(),
      paymentId: id,
      checkoutUri: checkout,
      isTestSession: sessionId.startsWith('cs_test_'),
    );
  }
}

class CompanyCollectionService {
  CompanyCollectionService(this.api);
  final ApiClient api;

  Future<Options> _auth() async {
    final token = await TokenStorage.getAccessToken();
    if (token == null || token.isEmpty) {
      throw StateError('Please sign in again.');
    }
    return Options(
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
      contentType: Headers.jsonContentType,
    );
  }

  Map<String, dynamic> _body(Object? raw) {
    if (raw is! Map) {
      throw const FormatException('Unexpected payment response.');
    }
    final body = Map<String, dynamic>.from(raw);
    if (body['success'] != true) {
      throw StateError(body['message']?.toString() ?? 'Payment request failed.');
    }
    return body;
  }

  /// The server computes and stores all fees; Flutter never submits an amount.
  Future<Map<String, dynamic>> quote(int contractId) async {
    late final Response<dynamic> response;
    try {
      response = await api.post(
        ApiEndpoints.quoteCompanyContract(contractId),
        data: {'payment_method': 'unspecified'},
        options: await _auth(),
      );
    } on DioException catch (e) {
      throw CompanyPaymentApiException.fromDio(e, operation: 'quote');
    }
    final body = _body(response.data);
    final payload = body['data'];
    if (payload is! Map) {
      throw const FormatException('Quote details are unavailable.');
    }
    final quote = Map<String, dynamic>.from(payload);
    if ((quote['quote_reference']?.toString().trim() ?? '').isEmpty) {
      throw const FormatException('The quote reference is missing.');
    }
    return quote;
  }

  /// Updated November 18 contract endpoint. This starts Stripe redirect
  /// checkout but DOES NOT mean the transaction has settled.
  Future<ContractFundingSnapshot> fundWithRedirect(
    int contractId,
    String quoteReference,
  ) async {
    late final Response<dynamic> response;
    try {
      response = await api.post(
        ApiEndpoints.fundCompanyContract(contractId),
        data: {
          'quote_reference': quoteReference,
          'method': 'redirect',
        },
        options: await _auth(),
      );
    } on DioException catch (e) {
      throw CompanyPaymentApiException.fromDio(e, operation: 'fund');
    }
    final body = _body(response.data);
    return ContractFundingSnapshot.fromResponse(body);
  }

  Future<ContractFundingSnapshot> contractSnapshot(int contractId) async {
    final response = await api.get(
      ApiEndpoints.companyContract(contractId),
      options: await _auth(),
    );
    return ContractFundingSnapshot.fromResponse(_body(response.data));
  }

  /// Read the status returned by GET /collect/{attempt}. Different Laravel
  /// releases nest it under payment or attempt; missing means unknown.
  /// This pure parser allows unit tests without making network requests.
  static String? collectionAttemptStatus(Object? payload) {
    if (payload is! Map) return null;
    final raw = Map<String, dynamic>.from(payload);
    for (final field in const ['status', 'payment_status', 'state']) {
      final status = _asStatus(raw[field]);
      if (status != null) return status;
    }
    for (final field in const ['payment', 'attempt', 'payment_attempt', 'collection']) {
      final inner = collectionAttemptStatus(raw[field]);
      if (inner != null) return inner;
    }
    return null;
  }

  Future<Map<String, dynamic>> paymentAttemptStatus(
    int contractId,
    int paymentId,
  ) async {
    final response = await api.get(
      ApiEndpoints.collectionStatus(contractId, paymentId),
      options: await _auth(),
    );
    print('STRIPE ATTEMPT RESPONSE: ${response.data}');
    return _body(response.data);
  }
  /// The payment attempt ID used by /fund is not guaranteed to be the ID
  /// exposed by GET /company/payments. The two must not be treated as
  /// interchangeable. Reconcile by contract ID and prefer an exact payment ID.
  /// If IDs differ, a status is unambiguous only when the company has exactly
  /// ONE payment record for that contract. Never guess from other contracts.
  static String? resolveCompanyPaymentStatus(
    List<Map<String, dynamic>> records, {
    required int contractId,
    int? paymentId,
  }) {
    final sameContract = records.where((record) =>
        _asPositiveId(record['contract_id']) == contractId).toList();
    if (paymentId != null) {
      for (final row in sameContract) {
        if (_asPositiveId(row['id']) == paymentId) {
          return _asStatus(row['status']);
        }
      }
    }
    // Different collection-attempt ID vs payment-row ID is observed on some
    // servers. Contract-only fallback is safe only for a unique record.
    return sameContract.length == 1
        ? _asStatus(sameContract.single['status'])
        : null;
  }

  static String? _asStatus(Object? raw) {
    final value = raw?.toString().trim().toLowerCase();
    return value == null || value.isEmpty ? null : value;
  }

  static int? _asPositiveId(Object? value) {
    final result = value is int ? value : int.tryParse('${value ?? ''}');
    return result != null && result > 0 ? result : null;
  }

  /// Fetch every declared paginator page. A partial list or transient HTTP
  /// error MUST NOT be mistaken for an absent or failed payment.
  Future<List<Map<String, dynamic>>> _listCompanyPayments({
    String? statusFilter,
  }) async {
    final options = await _auth();
    final rows = <Map<String, dynamic>>[];
    var page = 1;
    var lastPage = 1;
    do {
      late final Response<dynamic> response;
      try {
        response = await api.get(
          ApiEndpoints.companyPayments,
          queryParameters: {
            'page': page,
            'per_page': 50,
            if (statusFilter != null) 'status': statusFilter,
          },
          options: options,
        );
      } on DioException catch (e) {
        throw CompanyPaymentApiException.fromDio(
          e,
          operation: 'companyPayments',
        );
      }
      final body = _body(response.data);
      final raw = body['data'];
      final Object? items = raw is Map ? raw['data'] : raw;
      if (items is! List) {
        throw const FormatException('Company payment list was not returned.');
      }
      final pagination = raw is Map ? raw : body['meta'];
      final pageCount = pagination is Map
          ? int.tryParse('${pagination['last_page'] ?? 1}')
          : 1;
      if (pageCount == null || pageCount < 1 || pageCount > 500) {
        throw const FormatException('Invalid company payment pagination.');
      }
      lastPage = pageCount;
      for (final item in items) {
        if (item is Map) rows.add(Map<String, dynamic>.from(item));
      }
      page++;
    } while (page <= lastPage);
    return rows;
  }

  /// Read an existing pending payment before creating any new quote.
  /// Returns null only after all pages were fetched successfully.
  Future<int?> findPendingAttemptForContract(int contractId) async {
    final rows = await _listCompanyPayments(statusFilter: 'pending');
    final candidates = rows.where((record) =>
        _asPositiveId(record['contract_id']) == contractId &&
        _asStatus(record['status']) == 'pending').toList();
    if (candidates.isEmpty) return null;
    candidates.sort((a, b) =>
        (_asPositiveId(a['id']) ?? 0).compareTo(_asPositiveId(b['id']) ?? 0));
    return _asPositiveId(candidates.last['id']);
  }

  /// Read-only recovery of the SAME Checkout session. The server must include
  /// a complete hosted Stripe URL in a company-owned payment row; no POST /fund.
  /// A paid/ambiguous/mismatched record is never opened again.
  Future<Uri?> existingCheckoutForContract(int contractId, {int? paymentId}) async {
    final records = await _listCompanyPayments();
    return resolveCompanyCheckoutUri(
      records, contractId: contractId, paymentId: paymentId);
  }

  /// Pure selector. Never open a different contract's link or choose an
  /// ambiguous attempt, even if the URL is otherwise a valid Stripe URL.
  static Uri? resolveCompanyCheckoutUri(
    List<Map<String, dynamic>> records, {
    required int contractId,
    int? paymentId,
  }) {
    final sameContract = records.where((row) =>
      _asPositiveId(row['contract_id']) == contractId).toList();
    Map<String, dynamic>? selected;
    if (paymentId != null) {
      for (final row in sameContract) {
        if (_asPositiveId(row['id']) == paymentId ||
            _asPositiveId(row['attempt_id']) == paymentId) {
          selected = row;
          break;
        }
      }
    }
    if (selected == null && sameContract.length == 1) {
      selected = sameContract.single;
    }
    if (selected == null) return null;
    final status = _asStatus(selected['status']);
    if (status == null || status == 'failed' || status == 'cancelled' ||
        isProviderPaymentConfirmedStatus(status)) return null;
    return ContractFundingSnapshot.extractCheckoutUri(selected);
  }

  /// Optional read-only provider attempt lookup for API versions exposing
  /// GET /company/contracts/{contract}/collect/{attempt}. Some deployments
  /// return only status, and others do not expose this route. Never POST here.
  Future<Uri?> recoverExistingCheckout(int contractId, {int? paymentId}) async {
    if (paymentId != null && paymentId > 0) {
      try {
        final response = await api.get(
          ApiEndpoints.collectionStatus(contractId, paymentId),
          options: await _auth(),
        );
        final raw = response.data;
        if (raw is Map && raw['success'] == true) {
          final payload = raw['data'];
          final status = payload is Map
              ? (payload['status'] ?? payload['payment_status'])?.toString()
                  .trim().toLowerCase()
              : null;
          if (status != null && isProviderPaymentConfirmedStatus(status)) {
            return null;
          }
          final uri = ContractFundingSnapshot.extractCheckoutUri(payload);
          if (uri != null) return uri;
        }
      } catch (_) { /* This endpoint is optional across API versions. */ }
    }
    try {
      return await existingCheckoutForContract(
        contractId, paymentId: paymentId);
    } catch (_) {
      return null;
    }
  }

  /// Prefer payment ID, but an attempt ID can differ from the payment row ID.
  /// Only use a contract-level fallback if there is exactly one matching row.
  /// A missing/ambiguous row never implies the company can fund again.
  Future<String?> paymentStatusById(int paymentId, {int? contractId}) async {
    final rows = await _listCompanyPayments();
    if (contractId == null) {
      for (final row in rows) {
        if (_asPositiveId(row['id']) == paymentId) {
          return _asStatus(row['status']);
        }
      }
      return null;
    }
    return resolveCompanyPaymentStatus(
      rows, contractId: contractId, paymentId: paymentId,
    );
  }

}
