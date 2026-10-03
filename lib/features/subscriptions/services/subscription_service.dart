import 'package:dio/dio.dart';

import 'package:tototl_app/core/network/api_client.dart';
import 'package:tototl_app/core/storage/token_storage.dart';
import 'package:tototl_app/features/subscriptions/models/subscription_models.dart';

class _SubscriptionRoutes {
  static const String plans = '/subscription-plans';
  static const String current = '/subscription';
  static const String subscriptions = '/subscriptions';
  static const String history = '/subscriptions/history';
  static const String payments = '/subscription-payments';

  static String cancel(int id) => '/subscriptions/$id/cancel';
  static String changePlan(int id) => '/subscriptions/$id/change-plan';
}

class SubscriptionService {
  final ApiClient apiClient;

  SubscriptionService(this.apiClient);

  Future<List<SubscriptionPlanModel>> getPlans() async {
    final body = await _get(_SubscriptionRoutes.plans, 'Unable to load subscription plans.');
    final raw = body['data'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((item) => SubscriptionPlanModel.fromJson(Map<String, dynamic>.from(item)))
        .where((plan) => plan.id > 0 && plan.isActive)
        .toList(growable: false);
  }

  Future<UserSubscriptionModel?> getCurrent() async {
    final body = await _get(_SubscriptionRoutes.current, 'Unable to load current subscription.');
    final raw = body['data'];
    if (raw == null) return null;
    if (raw is Map) {
      return UserSubscriptionModel.fromJson(Map<String, dynamic>.from(raw));
    }
    final text = raw.toString().trim().toLowerCase();
    if (text.isEmpty || text == 'null') return null;
    throw const SubscriptionException('Invalid current subscription response.');
  }

  Future<UserSubscriptionModel> subscribe(int planId) async {
    return _subscriptionAction(
      _SubscriptionRoutes.subscriptions,
      data: <String, dynamic>{'subscription_plan_id': planId},
      fallback: 'Unable to start this subscription.',
    );
  }

  Future<UserSubscriptionModel> changePlan({
    required int subscriptionId,
    required int planId,
  }) async {
    return _subscriptionAction(
      _SubscriptionRoutes.changePlan(subscriptionId),
      data: <String, dynamic>{'subscription_plan_id': planId},
      fallback: 'Unable to change subscription plan.',
    );
  }

  Future<UserSubscriptionModel> cancel(int subscriptionId) async {
    return _subscriptionAction(
      _SubscriptionRoutes.cancel(subscriptionId),
      fallback: 'Unable to cancel subscription.',
    );
  }

  Future<List<UserSubscriptionModel>> getHistory() async {
    final body = await _get(_SubscriptionRoutes.history, 'Unable to load subscription history.');
    final raw = body['data'];
    if (raw is! List) return const [];
    final rows = raw
        .whereType<Map>()
        .map((item) => UserSubscriptionModel.fromJson(Map<String, dynamic>.from(item)))
        .toList(growable: false);
    rows.sort((a, b) => (b.updatedAt ?? b.createdAt ?? b.startDate)
        .compareTo(a.updatedAt ?? a.createdAt ?? a.startDate));
    return List.unmodifiable(rows);
  }

  Future<List<SubscriptionPaymentModel>> getPayments() async {
    final body = await _get(_SubscriptionRoutes.payments, 'Unable to load subscription payments.');
    final raw = body['data'];
    if (raw is! List) return const [];
    final rows = raw
        .whereType<Map>()
        .map((item) => SubscriptionPaymentModel.fromJson(Map<String, dynamic>.from(item)))
        .toList(growable: false);
    rows.sort((a, b) {
      final ad = a.updatedAt ?? a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bd = b.updatedAt ?? b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bd.compareTo(ad);
    });
    return List.unmodifiable(rows);
  }

  Future<Map<String, dynamic>> _get(String endpoint, String fallback) async {
    final token = await _getToken();
    try {
      final response = await apiClient.get(endpoint, options: _authOptions(token));
      final body = _parseBody(response.data);
      _ensureSuccess(body, fallback: fallback);
      return body;
    } on DioException catch (e) {
      throw SubscriptionException(_dioErrorMessage(e, fallback: fallback));
    }
  }

  Future<UserSubscriptionModel> _subscriptionAction(
    String endpoint, {
    Map<String, dynamic>? data,
    required String fallback,
  }) async {
    final token = await _getToken();
    try {
      final response = await apiClient.post(
        endpoint,
        data: data,
        options: data == null ? _authOptions(token) : _jsonAuthOptions(token),
      );
      final body = _parseBody(response.data);
      _ensureSuccess(body, fallback: fallback);
      final raw = body['data'];
      if (raw is! Map) throw const SubscriptionException('Subscription data is missing.');
      return UserSubscriptionModel.fromJson(Map<String, dynamic>.from(raw));
    } on DioException catch (e) {
      throw SubscriptionException(_dioErrorMessage(e, fallback: fallback));
    }
  }

  Future<String> _getToken() async {
    final token = await TokenStorage.getAccessToken();
    if (token == null || token.trim().isEmpty) {
      throw const SubscriptionException('Authentication token not found.');
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
    if (raw is! Map) throw const SubscriptionException('Invalid server response.');
    return Map<String, dynamic>.from(raw);
  }

  void _ensureSuccess(Map<String, dynamic> body, {required String fallback}) {
    if (body['success'] == true) return;
    throw SubscriptionException(_messageFromBody(body, fallback: fallback));
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
    if (e.type == DioExceptionType.connectionTimeout || e.type == DioExceptionType.receiveTimeout) {
      return 'Connection timed out. Please try again.';
    }
    return fallback;
  }
}

class SubscriptionException implements Exception {
  final String message;
  const SubscriptionException(this.message);
  @override
  String toString() => message;
}
