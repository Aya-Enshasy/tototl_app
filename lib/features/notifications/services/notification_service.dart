import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/storage/token_storage.dart';
import '../models/notification_model.dart';

class NotificationService {
  final ApiClient apiClient;

  NotificationService(
      this.apiClient,
      );

  static const String _notificationsEndpoint =
      '/notifications';

  static const String _readAllEndpoint =
      '/notifications/read-all';

  // ===========================================================================
  // GET NOTIFICATIONS
  // GET /notifications
  // ===========================================================================

  Future<NotificationListModel> getNotifications({
    bool unreadOnly = false,
    int page = 1,
    int perPage = 20,
  }) async {
    final token =
    await _getToken();

    final safePage =
    page < 1
        ? 1
        : page;

    final safePerPage =
    perPage
        .clamp(
      1,
      50,
    )
        .toInt();

    final query = <String>[
      if (unreadOnly)
        'unread=1',
      'page=$safePage',
      'per_page=$safePerPage',
    ].join('&');

    try {
      final response =
      await apiClient.get(
        '$_notificationsEndpoint?$query',
        options:
        _authOptions(
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
        'Unable to load notifications.',
      );

      final rawData =
      body['data'];

      if (rawData is! Map) {
        throw const NotificationException(
          'Notifications data is missing.',
        );
      }

      return NotificationListModel.fromJson(
        Map<String, dynamic>.from(
          rawData,
        ),
      );
    } on DioException catch (e) {
      throw NotificationException(
        _dioErrorMessage(
          e,
          fallback:
          'Unable to load notifications.',
        ),
      );
    }
  }

  // ===========================================================================
  // GET UNREAD NOTIFICATIONS
  // ===========================================================================

  Future<NotificationListModel>
  getUnreadNotifications({
    int page = 1,
    int perPage = 20,
  }) {
    return getNotifications(
      unreadOnly: true,
      page: page,
      perPage: perPage,
    );
  }

  // ===========================================================================
  // MARK ONE AS READ
  // POST /notifications/{uuid}/read
  // ===========================================================================

  Future<String> markAsRead(
      String notificationId,
      ) async {
    final id =
    notificationId.trim();

    if (id.isEmpty) {
      throw const NotificationException(
        'Invalid notification.',
      );
    }

    final token =
    await _getToken();

    try {
      final response =
      await apiClient.post(
        '/notifications/$id/read',
        options:
        _authOptions(
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
        'Unable to mark notification as read.',
      );

      final message =
      body['message']
          ?.toString()
          .trim();

      if (message != null &&
          message.isNotEmpty) {
        return message;
      }

      return 'Notification marked as read.';
    } on DioException catch (e) {
      throw NotificationException(
        _dioErrorMessage(
          e,
          fallback:
          'Unable to mark notification as read.',
        ),
      );
    }
  }

  // ===========================================================================
  // MARK ALL AS READ
  // POST /notifications/read-all
  // ===========================================================================

  Future<MarkAllNotificationsReadResult>
  markAllAsRead() async {
    final token =
    await _getToken();

    try {
      final response =
      await apiClient.post(
        _readAllEndpoint,
        options:
        _authOptions(
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
        'Unable to mark all notifications as read.',
      );

      final rawData =
      body['data'];

      var markedRead = 0;

      if (rawData is Map) {
        markedRead =
            _asInt(
              rawData[
              'marked_read'],
            ) ??
                0;
      }

      final message =
      body['message']
          ?.toString()
          .trim();

      return MarkAllNotificationsReadResult(
        markedRead:
        markedRead,
        message:
        message != null &&
            message.isNotEmpty
            ? message
            : 'All notifications marked as read.',
      );
    } on DioException catch (e) {
      throw NotificationException(
        _dioErrorMessage(
          e,
          fallback:
          'Unable to mark all notifications as read.',
        ),
      );
    }
  }

  // ===========================================================================
  // TOKEN
  // ===========================================================================

  Future<String> _getToken() async {
    final token =
    await TokenStorage
        .getAccessToken();

    if (token == null ||
        token.trim().isEmpty) {
      throw const NotificationException(
        'Authentication token not found.',
      );
    }

    return token.trim();
  }

  // ===========================================================================
  // REQUEST OPTIONS
  // ===========================================================================

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

  // ===========================================================================
  // RESPONSE
  // ===========================================================================

  Map<String, dynamic> _parseBody(
      dynamic raw,
      ) {
    if (raw is! Map) {
      throw const NotificationException(
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

    throw NotificationException(
      _messageFromBody(
        body,
        fallback:
        fallback,
      ),
    );
  }

  // ===========================================================================
  // ERROR PARSING
  // ===========================================================================

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

          if (text.isNotEmpty &&
              text.toLowerCase() !=
                  'null') {
            return text;
          }
        }
      }
    }

    if (errors is List &&
        errors.isNotEmpty) {
      final first =
      errors.first
          .toString()
          .trim();

      if (first.isNotEmpty) {
        return first;
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
        fallback:
        fallback,
      );
    }

    switch (error.type) {
      case DioExceptionType
          .connectionTimeout:
      case DioExceptionType
          .sendTimeout:
      case DioExceptionType
          .receiveTimeout:
        return 'Connection timed out. Please try again.';

      case DioExceptionType
          .connectionError:
        return 'No internet connection.';

      case DioExceptionType
          .badCertificate:
        return 'Unable to establish a secure connection.';

      case DioExceptionType
          .cancel:
        return 'Request was cancelled.';

      case DioExceptionType
          .badResponse:
      case DioExceptionType
          .unknown:
        return fallback;
      case DioExceptionType.transformTimeout:
        // TODO: Handle this case.
        throw UnimplementedError();
    }
  }
}

class MarkAllNotificationsReadResult {
  final int markedRead;
  final String message;

  const MarkAllNotificationsReadResult({
    this.markedRead = 0,
    this.message = '',
  });

  bool get hasChanges =>
      markedRead > 0;
}

class NotificationException
    implements Exception {
  final String message;

  const NotificationException(
      this.message,
      );

  @override
  String toString() =>
      message;
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