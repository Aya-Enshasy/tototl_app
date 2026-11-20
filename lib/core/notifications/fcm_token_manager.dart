import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../network/api_client.dart';
import '../network/api_endpoints.dart';
import '../storage/token_storage.dart';

class FcmTokenManager {
  FcmTokenManager._();

  static final FcmTokenManager instance =
  FcmTokenManager._();

  final FirebaseMessaging _messaging =
      FirebaseMessaging.instance;

  final FcmTokenService _service =
  FcmTokenService(
    ApiClient(),
  );

  StreamSubscription<String>? _subscription;

  Future<void> initialize() async {
    // ============================================================
    // PERMISSION
    // ============================================================

    try {
      await _messaging.requestPermission();
    } catch (error) {
      print('Notification permission request failed: $error');
    }

    // ============================================================
    // CURRENT TOKEN
    // ============================================================

    String? currentToken;
    try {
      currentToken = await _messaging.getToken();
    } catch (error) {
      // On iOS the APNs token can arrive after app startup. Keep the token
      // refresh listener registered so future tokens are not missed.
      print('FCM token is not ready yet: $error');
    }

    if (currentToken != null &&
        currentToken.trim().isNotEmpty) {
      print(
        '================ FCM CURRENT TOKEN ================',
      );
      // Never write device push tokens to logs.
      print(
        '===================================================',
      );

      await _handleCurrentToken(
        currentToken.trim(),
      );
    }

    // ============================================================
    // LISTEN FOR TOKEN CHANGES
    // ============================================================

    await _subscription?.cancel();

    _subscription =
        _messaging.onTokenRefresh.listen(
              (newToken) async {
            final clean =
            newToken.trim();

            if (clean.isEmpty) {
              return;
            }

            print(
              '================ FCM TOKEN CHANGED ================',
            );

            await _handleNewToken(clean);
          },
          onError: (Object error) {
            print(
              'FCM TOKEN REFRESH LISTENER ERROR: $error',
            );
          },
        );
  }

  // ==============================================================
  // FIRST/CURRENT TOKEN
  // ==============================================================

  Future<void> _handleCurrentToken(
      String currentToken,
      ) async {
    final savedToken =
    await FcmLocalTokenStorage.getToken();

    // First time we know this device token.
    if (savedToken == null ||
        savedToken.trim().isEmpty) {
      await FcmLocalTokenStorage.saveToken(
        currentToken,
      );

      print(
        'FCM TOKEN SAVED LOCALLY.',
      );
      // The API requires old_token + token to rotate. There is currently
      // no endpoint to register a first token outside login. Login sends
      // fcm_token; the server should add a separate register-token endpoint.
      return;
    }

    if (savedToken == currentToken) {
      print(
        'FCM TOKEN DID NOT CHANGE.',
      );

      return;
    }

    // If app was closed while Firebase rotated the token,
    // synchronize it now.
    await _refreshBackend(
      oldToken: savedToken,
      newToken: currentToken,
    );
  }

  // ==============================================================
  // FIREBASE onTokenRefresh
  // ==============================================================

  Future<void> _handleNewToken(
      String newToken,
      ) async {
    final oldToken =
    await FcmLocalTokenStorage.getToken();

    if (oldToken == null ||
        oldToken.trim().isEmpty) {
      await FcmLocalTokenStorage.saveToken(
        newToken,
      );

      print(
        'FCM NEW TOKEN SAVED — NO OLD TOKEN AVAILABLE.',
      );
      // A newly issued token after login cannot be attached with /refresh,
      // because its old_token parameter is mandatory. Needs backend support.
      return;
    }

    if (oldToken == newToken) {
      return;
    }

    await _refreshBackend(
      oldToken: oldToken,
      newToken: newToken,
    );
  }

  // ==============================================================
  // BACKEND SYNC
  // ==============================================================

  Future<void> _refreshBackend({
    required String oldToken,
    required String newToken,
  }) async {
    final accessToken =
    await TokenStorage.getAccessToken();

    // User is logged out.
    // Save current token locally.
    // Login will send the new FCM token later.
    if (accessToken == null ||
        accessToken.trim().isEmpty) {
      await FcmLocalTokenStorage.saveToken(
        newToken,
      );

      print(
        'FCM USER NOT LOGGED IN — TOKEN SAVED LOCALLY.',
      );

      return;
    }

    String? apnToken;

    if (Platform.isIOS) {
      apnToken =
      await _messaging.getAPNSToken();
    }

    try {
      await _service.refreshToken(
        oldToken: oldToken,
        newToken: newToken,
        apnToken: apnToken,
        deviceType:
        Platform.isIOS
            ? 'ios'
            : 'android',
      );

      // Only replace the stored old token after
      // the backend confirms success.
      await FcmLocalTokenStorage.saveToken(
        newToken,
      );

      print(
        'FCM TOKEN REFRESHED ON BACKEND SUCCESSFULLY.',
      );
    } catch (e) {
      print(
        'FCM TOKEN BACKEND REFRESH FAILED: $e',
      );

      // Important:
      // don't overwrite oldToken here.
      // On next app launch we can retry.
    }
  }
}

// ============================================================================
// API SERVICE
// ============================================================================

class FcmTokenService {
  final ApiClient apiClient;

  FcmTokenService(this.apiClient);

  Future<void> refreshToken({
    required String oldToken,
    required String newToken,
    required String deviceType,
    String? apnToken,
  }) async {
    final accessToken =
    await TokenStorage.getAccessToken();

    if (accessToken == null ||
        accessToken.trim().isEmpty) {
      throw const FcmTokenException(
        'Authentication token not found.',
      );
    }

    print(
      '================ FCM REFRESH REQUEST ================',
    );
    print(
      'ENDPOINT: ${ApiEndpoints.fcmTokenRefresh}',
    );
    print(
      'DEVICE: $deviceType',
    );

    final response =
    await apiClient.post(
      ApiEndpoints.fcmTokenRefresh,
      data: {
        'old_token': oldToken,
        'token': newToken,
        'apn_token': apnToken,
        'device_type': deviceType,
      },
      options: Options(
        headers: {
          'Accept':
          'application/json',
          'Content-Type':
          'application/json',
          'Authorization':
          'Bearer ${accessToken.trim()}',
        },
      ),
    );

    print(
      'FCM REFRESH STATUS: ${response.statusCode}',
    );
    // Do not log raw token-refresh responses or any device credentials.
    print('FCM REFRESH RESPONSE RECEIVED.');

    final raw =
        response.data;

    if (raw is! Map) {
      throw const FcmTokenException(
        'Invalid server response.',
      );
    }

    final body =
    Map<String, dynamic>.from(raw);

    if (body['success'] != true) {
      final message =
      body['message']
          ?.toString()
          .trim();

      throw FcmTokenException(
        message != null &&
            message.isNotEmpty
            ? message
            : 'Unable to refresh FCM token.',
      );
    }

    print(
      '================ FCM REFRESH SUCCESS ================',
    );
  }
}

// ============================================================================
// LOCAL FCM TOKEN STORAGE
// ============================================================================

class FcmLocalTokenStorage {
  FcmLocalTokenStorage._();

  static const FlutterSecureStorage _storage =
  FlutterSecureStorage();

  static const String _key =
      'current_fcm_token';

  static Future<void> saveToken(
      String token,
      ) async {
    await _storage.write(
      key: _key,
      value: token.trim(),
    );
  }

  static Future<String?> getToken() async {
    return _storage.read(
      key: _key,
    );
  }

  static Future<void> clear() async {
    await _storage.delete(
      key: _key,
    );
  }
}

// ============================================================================
// EXCEPTION
// ============================================================================

class FcmTokenException
    implements Exception {
  final String message;

  const FcmTokenException(
      this.message,
      );

  @override
  String toString() => message;
}