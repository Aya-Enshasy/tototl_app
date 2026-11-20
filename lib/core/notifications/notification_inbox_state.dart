import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../features/notifications/services/notification_service.dart';
import '../network/api_client.dart';
import '../storage/token_storage.dart';

/// Account-scoped unread badge. Reuses the inbox response's unread_count.
/// No background polling: refresh on entry, foreground push and after mutations.
class NotificationInboxState {
  NotificationInboxState._();
  static final NotificationInboxState instance = NotificationInboxState._();

  final ValueNotifier<int?> unreadCount = ValueNotifier<int?>(null);
  final ValueNotifier<int> incomingRevision = ValueNotifier<int>(0);
  int _openInboxes = 0;

  void inboxOpened() => _openInboxes++;
  void inboxClosed() {
    if (_openInboxes > 0) _openInboxes--;
  }

  /// In-place refresh if the inbox is visible; otherwise only fetch the badge.
  void onIncomingNotification() {
    if (_openInboxes > 0) {
      incomingRevision.value++;
    } else {
      unawaited(refresh(force: true));
    }
  }

  final NotificationService _service = NotificationService(ApiClient());

  Future<void>? _inFlight;
  DateTime? _lastRequest;

  Future<void> refresh({bool force = false}) {
    if (_inFlight != null) return _inFlight!;
    final last = _lastRequest;
    if (!force && last != null &&
        DateTime.now().difference(last) < const Duration(seconds: 45)) {
      return Future<void>.value();
    }
    _lastRequest = DateTime.now();
    final future = _load();
    _inFlight = future;
    return future.whenComplete(() { _inFlight = null; });
  }

  Future<void> _load() async {
    final token = await TokenStorage.getAccessToken();
    if (token == null || token.trim().isEmpty) {
      unreadCount.value = null;
      return;
    }
    try {
      final response = await _service.getNotifications(perPage: 1);
      // Avoid populating the badge after sign-out/account switch.
      if (await TokenStorage.getAccessToken() == token) {
        unreadCount.value = response.unreadCount;
      }
    } catch (_) {
      // Preserve a previously correct badge; the inbox itself displays errors.
    }
  }

  void setCount(int value) => unreadCount.value = value < 0 ? 0 : value;

  void clear() {
    unreadCount.value = null;
    _lastRequest = null;
  }
}
