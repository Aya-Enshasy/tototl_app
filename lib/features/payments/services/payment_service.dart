import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/storage/token_storage.dart';
import '../models/payment_model.dart';

enum PaymentAudience { pilot, company }

class PaymentService {
  final ApiClient apiClient;

  PaymentService(this.apiClient);

  Future<List<PaymentModel>> getPayments({
    required PaymentAudience audience,
    String? status,
  }) async {
    final token = await _getToken();
    final result = <PaymentModel>[];
    var page = 1;
    var lastPage = 1;

    do {
      final query = <String>[
        if ((status ?? '').trim().isNotEmpty)
          'status=${Uri.encodeQueryComponent(status!.trim().toLowerCase())}',
        'per_page=50',
        'page=$page',
      ].join('&');

      final base = audience == PaymentAudience.company
          ? ApiEndpoints.companyPayments
          : ApiEndpoints.payments;

      try {
        final response = await apiClient.get(
          '$base?$query',
          options: _authOptions(token),
        );

        final body = _parseBody(response.data);
        _ensureSuccess(body, fallback: 'Unable to load payment history.');

        final rawData = body['data'];
        List<dynamic> rawRows = const [];

        if (rawData is List) {
          rawRows = rawData;
          final meta = body['meta'];
          if (meta is Map) {
            lastPage = _asInt(meta['last_page']) ?? page;
          } else {
            lastPage = page;
          }
        } else if (rawData is Map) {
          final paginator = Map<String, dynamic>.from(rawData);
          final rows = paginator['data'];
          if (rows is List) rawRows = rows;
          lastPage = _asInt(paginator['last_page']) ?? page;
        } else {
          lastPage = page;
        }

        for (final raw in rawRows) {
          if (raw is Map) {
            result.add(PaymentModel.fromJson(Map<String, dynamic>.from(raw)));
          }
        }
      } on DioException catch (e) {
        throw PaymentException(
          _dioErrorMessage(e, fallback: 'Unable to load payment history.'),
        );
      }

      page++;
    } while (page <= lastPage);

    final unique = <int, PaymentModel>{};
    for (final payment in result) {
      if (payment.id > 0) unique[payment.id] = payment;
    }
    final values = unique.values.toList()
      ..sort((a, b) {
        final ad = a.updatedAt ?? a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bd = b.updatedAt ?? b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bd.compareTo(ad);
      });
    return List.unmodifiable(values);
  }

  Future<PaymentModel> getPayment({
    required int paymentId,
    required PaymentAudience audience,
  }) async {
    final token = await _getToken();
    final endpoint = audience == PaymentAudience.company
        ? ApiEndpoints.companyPayment(paymentId)
        : ApiEndpoints.payment(paymentId);

    try {
      final response = await apiClient.get(endpoint, options: _authOptions(token));
      final body = _parseBody(response.data);
      _ensureSuccess(body, fallback: 'Unable to load payment details.');
      final raw = body['data'];
      if (raw is! Map) {
        throw const PaymentException('Payment details are missing.');
      }
      return PaymentModel.fromJson(Map<String, dynamic>.from(raw));
    } on DioException catch (e) {
      throw PaymentException(
        _dioErrorMessage(e, fallback: 'Unable to load payment details.'),
      );
    }
  }

  Future<String> _getToken() async {
    final token = await TokenStorage.getAccessToken();
    if (token == null || token.trim().isEmpty) {
      throw const PaymentException('Authentication token not found.');
    }
    return token.trim();
  }

  Options _authOptions(String token) => Options(
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

  Map<String, dynamic> _parseBody(dynamic raw) {
    if (raw is! Map) throw const PaymentException('Invalid server response.');
    return Map<String, dynamic>.from(raw);
  }

  void _ensureSuccess(Map<String, dynamic> body, {required String fallback}) {
    if (body['success'] == true) return;
    throw PaymentException(_messageFromBody(body, fallback: fallback));
  }

  String _messageFromBody(Map<String, dynamic> body, {required String fallback}) {
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

  String _dioErrorMessage(DioException e, {required String fallback}) {
    final raw = e.response?.data;
    if (raw is Map) {
      return _messageFromBody(Map<String, dynamic>.from(raw), fallback: fallback);
    }
    if (e.type == DioExceptionType.connectionError) return 'No internet connection.';
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return 'Connection timed out. Please try again.';
    }
    return fallback;
  }
}

int? _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '');
}

class PaymentException implements Exception {
  final String message;
  const PaymentException(this.message);
  @override
  String toString() => message;
}
