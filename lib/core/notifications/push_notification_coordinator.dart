import 'dart:async';
import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import '../../features/notifications/models/notification_model.dart';
import '../../features/notifications/screens/notifications_screen.dart';
import '../localization/app_language.dart';
import '../storage/token_storage.dart';
import '../storage/user_session_storage.dart';
import 'notification_inbox_state.dart';

/// Handles *receiving* Firebase pushes and notification taps. A trusted sender
/// is required on the server; the app cannot send pushes to other users.
class PushNotificationCoordinator with WidgetsBindingObserver {
  PushNotificationCoordinator._();
  static final PushNotificationCoordinator instance =
      PushNotificationCoordinator._();

  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  final GlobalKey<ScaffoldMessengerState> messengerKey =
      GlobalKey<ScaffoldMessengerState>();

  StreamSubscription<RemoteMessage>? _foreground;
  StreamSubscription<RemoteMessage>? _opened;
  AppNotificationModel? _pending;
  bool _pendingTap = false;
  bool _authenticatedReady = false;
  bool _opening = false;
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    WidgetsBinding.instance.addObserver(this);

    try {
      await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
    } catch (error) {
      debugPrint('Push presentation options unavailable: $error');
    }

    _foreground = FirebaseMessaging.onMessage.listen((message) {
      if (!_authenticatedReady) return;
      NotificationInboxState.instance.onIncomingNotification();
      final item = _modelFromMessage(message);
      final title = (message.notification?.title ?? item.displayTitle).trim();
      final body = (message.notification?.body ?? item.displayBody).trim();
      messengerKey.currentState
        ?..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          content: Text(body.isEmpty ? title : '$title\n$body',
              maxLines: 3, overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12)),
          action: SnackBarAction(
            label: AppLanguage.text('View'),
            onPressed: () => unawaited(_queueTap(item)),
          ),
          behavior: SnackBarBehavior.floating,
        ));
    });

    _opened = FirebaseMessaging.onMessageOpenedApp.listen((message) {
      unawaited(_queueTap(_modelFromMessage(message)));
    });

    // Tap that launched a fully terminated app.
    final first = await FirebaseMessaging.instance.getInitialMessage();
    if (first != null) await _queueTap(_modelFromMessage(first));
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _authenticatedReady) {
      unawaited(NotificationInboxState.instance.refresh());
    }
  }

  void onAuthenticatedScreenReady() {
    _authenticatedReady = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(NotificationInboxState.instance.refresh());
      unawaited(_openPending());
    });
  }

  void onSignedOut() {
    _authenticatedReady = false;
    _pendingTap = false;
    _pending = null;
    NotificationInboxState.instance.clear();
  }

  Future<void> _queueTap(AppNotificationModel item) async {
    // Drop taps for signed-out users rather than leaking old-account pushes
    // to the next user who logs in on this device.
    final token = await TokenStorage.getAccessToken();
    if (token == null || token.trim().isEmpty) return;
    _pending = item;
    _pendingTap = true;
    unawaited(_openPending());
  }

  Future<void> _openPending() async {
    if (!_pendingTap || !_authenticatedReady || _opening) return;
    final token = await TokenStorage.getAccessToken();
    final role = (await UserSessionStorage.getRole())?.toLowerCase().trim();
    if (token == null || token.isEmpty ||
        (role != 'pilot' && role != 'company' && role != 'admin')) return;

    final navigator = navigatorKey.currentState;
    if (navigator == null || !navigator.mounted || _opening) return;
    _opening = true;
    final item = _pending;
    _pendingTap = false;
    _pending = null;
    try {
      await navigator.push<void>(MaterialPageRoute(
        builder: (_) => NotificationsScreen(initialNotification: item),
      ));
    } catch (error) {
      debugPrint('Unable to open notification: $error');
    } finally {
      _opening = false;
      if (_pendingTap) unawaited(_openPending());
    }
  }

  static AppNotificationModel _modelFromMessage(RemoteMessage message) =>
      notificationFromPayload(
        message.data,
        notificationId: message.messageId,
        title: message.notification?.title,
        body: message.notification?.body,
      );

  /// Pure parser, also testable without a Firebase device.
  static AppNotificationModel notificationFromPayload(
    Map<String, dynamic> data, {
    String? notificationId,
    String? title,
    String? body,
  }) {
    final raw = <String, dynamic>{...data};
    final nested = raw['data'];
    if (nested is String) {
      try {
        final decoded = jsonDecode(nested);
        if (decoded is Map) {
          raw.addAll(Map<String, dynamic>.from(decoded));
        }
      } catch (_) { /* No nested data; use top-level FCM fields. */ }
    } else if (nested is Map) {
      raw.addAll(Map<String, dynamic>.from(nested));
    }
    raw['id'] ??= raw['notification_id'] ?? notificationId ?? '';
    raw['title'] ??= title;
    raw['body'] ??= body;
    return AppNotificationModel.fromJson(raw);
  }
}
