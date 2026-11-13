import 'package:flutter/foundation.dart';

import '../models/notification_model.dart';
import '../services/notification_service.dart';

class NotificationController extends ChangeNotifier {
  final NotificationService service;

  NotificationController(
      this.service,
      );

  // ===========================================================================
  // DATA
  // ===========================================================================

  NotificationListModel? _data;

  NotificationListModel? get data =>
      _data;

  List<AppNotificationModel> get notifications =>
      _data?.notifications ??
          const [];

  NotificationPaginationModel get pagination =>
      _data?.pagination ??
          const NotificationPaginationModel();

  int get unreadCount =>
      _data?.unreadCount ??
          0;

  bool get hasUnread =>
      unreadCount > 0;

  bool get isEmpty =>
      !_isLoading &&
          notifications.isEmpty;

  bool get hasNotifications =>
      notifications.isNotEmpty;

  // ===========================================================================
  // STATE
  // ===========================================================================

  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _isMarkingAllRead = false;

  bool _unreadOnly = false;

  String? _errorMessage;

  final Set<String> _markingReadIds =
  <String>{};

  bool get isLoading =>
      _isLoading;

  bool get isLoadingMore =>
      _isLoadingMore;

  bool get isMarkingAllRead =>
      _isMarkingAllRead;

  bool get unreadOnly =>
      _unreadOnly;

  String? get errorMessage =>
      _errorMessage;

  bool get isBusy =>
      _isLoading ||
          _isLoadingMore ||
          _isMarkingAllRead;

  bool get canLoadMore =>
      !_isLoading &&
          !_isLoadingMore &&
          pagination.hasNextPage;

  bool isMarkingRead(
      String notificationId,
      ) {
    return _markingReadIds.contains(
      notificationId.trim(),
    );
  }

  // ===========================================================================
  // LOAD
  // ===========================================================================

  Future<bool> loadNotifications({
    bool refresh = false,
    bool? unreadOnly,
  }) async {
    if (_isLoading) {
      return false;
    }

    if (unreadOnly != null) {
      _unreadOnly =
          unreadOnly;
    }

    _isLoading = true;
    _errorMessage = null;

    if (!refresh) {
      _data = null;
    }

    notifyListeners();

    try {
      final result =
      await service.getNotifications(
        unreadOnly:
        _unreadOnly,
        page: 1,
        perPage: 20,
      );

      _data =
          result;

      _isLoading = false;

      notifyListeners();

      return true;
    } on NotificationException catch (e) {
      _isLoading = false;
      _errorMessage =
          e.message;

      notifyListeners();

      return false;
    } catch (_) {
      _isLoading = false;
      _errorMessage =
      'Unable to load notifications.';

      notifyListeners();

      return false;
    }
  }

  // ===========================================================================
  // REFRESH
  // ===========================================================================

  Future<bool> refresh() {
    return loadNotifications(
      refresh: true,
    );
  }

  // ===========================================================================
  // FILTER
  // ===========================================================================

  Future<bool> showAll() async {
    if (!_unreadOnly &&
        _data != null) {
      return true;
    }

    _unreadOnly = false;

    return loadNotifications(
      refresh: false,
      unreadOnly: false,
    );
  }

  Future<bool> showUnreadOnly() async {
    if (_unreadOnly &&
        _data != null) {
      return true;
    }

    _unreadOnly = true;

    return loadNotifications(
      refresh: false,
      unreadOnly: true,
    );
  }

  Future<bool> setUnreadOnly(
      bool value,
      ) {
    return value
        ? showUnreadOnly()
        : showAll();
  }

  // ===========================================================================
  // LOAD MORE
  // ===========================================================================

  Future<bool> loadMore() async {
    if (!canLoadMore) {
      return false;
    }

    _isLoadingMore = true;
    _errorMessage = null;

    notifyListeners();

    try {
      final result =
      await service.getNotifications(
        unreadOnly:
        _unreadOnly,
        page:
        pagination.currentPage +
            1,
        perPage:
        pagination.perPage,
      );

      final combined =
      <AppNotificationModel>[
        ...notifications,
        ...result.notifications,
      ];

      final seenIds =
      <String>{};

      final merged =
      <AppNotificationModel>[];

      for (final item
      in combined) {
        final id =
        item.id.trim();

        if (id.isEmpty) {
          merged.add(
            item,
          );

          continue;
        }

        if (seenIds.add(id)) {
          merged.add(
            item,
          );
        }
      }

      _data =
          NotificationListModel(
            unreadCount:
            result.unreadCount,
            notifications:
            List<AppNotificationModel>.unmodifiable(
              merged,
            ),
            pagination:
            result.pagination,
          );

      _isLoadingMore = false;

      notifyListeners();

      return true;
    } on NotificationException catch (e) {
      _isLoadingMore = false;
      _errorMessage =
          e.message;

      notifyListeners();

      return false;
    } catch (_) {
      _isLoadingMore = false;
      _errorMessage =
      'Unable to load more notifications.';

      notifyListeners();

      return false;
    }
  }

  // ===========================================================================
  // MARK ONE AS READ
  // ===========================================================================

  Future<bool> markAsRead(
      AppNotificationModel notification,
      ) async {
    final id =
    notification.id.trim();

    if (id.isEmpty) {
      _errorMessage =
      'Invalid notification.';

      notifyListeners();

      return false;
    }

    if (notification.isRead) {
      return true;
    }

    if (_markingReadIds.contains(
      id,
    )) {
      return false;
    }

    _markingReadIds.add(
      id,
    );

    _errorMessage = null;

    notifyListeners();

    try {
      await service.markAsRead(
        id,
      );

      _applyReadState(
        id,
      );

      _markingReadIds.remove(
        id,
      );

      notifyListeners();

      return true;
    } on NotificationException catch (e) {
      _markingReadIds.remove(
        id,
      );

      _errorMessage =
          e.message;

      notifyListeners();

      return false;
    } catch (_) {
      _markingReadIds.remove(
        id,
      );

      _errorMessage =
      'Unable to mark notification as read.';

      notifyListeners();

      return false;
    }
  }

  // ===========================================================================
  // MARK ONE BY ID
  // ===========================================================================

  Future<bool> markAsReadById(
      String notificationId,
      ) async {
    final id =
    notificationId.trim();

    if (id.isEmpty) {
      return false;
    }

    AppNotificationModel? item;

    for (final notification
    in notifications) {
      if (notification.id ==
          id) {
        item =
            notification;

        break;
      }
    }

    if (item != null) {
      return markAsRead(
        item,
      );
    }

    if (_markingReadIds.contains(
      id,
    )) {
      return false;
    }

    _markingReadIds.add(
      id,
    );

    _errorMessage = null;

    notifyListeners();

    try {
      await service.markAsRead(
        id,
      );

      _markingReadIds.remove(
        id,
      );

      notifyListeners();

      return true;
    } on NotificationException catch (e) {
      _markingReadIds.remove(
        id,
      );

      _errorMessage =
          e.message;

      notifyListeners();

      return false;
    } catch (_) {
      _markingReadIds.remove(
        id,
      );

      _errorMessage =
      'Unable to mark notification as read.';

      notifyListeners();

      return false;
    }
  }

  // ===========================================================================
  // MARK ALL AS READ
  // ===========================================================================

  Future<MarkAllNotificationsReadResult?>
  markAllAsRead() async {
    if (_isMarkingAllRead) {
      return null;
    }

    if (unreadCount <= 0) {
      return const MarkAllNotificationsReadResult(
        markedRead: 0,
        message:
        'All notifications are already read.',
      );
    }

    _isMarkingAllRead = true;
    _errorMessage = null;

    notifyListeners();

    try {
      final result =
      await service.markAllAsRead();

      final current =
          _data;

      if (current != null) {
        if (_unreadOnly) {
          _data =
              NotificationListModel(
                unreadCount: 0,
                notifications:
                const [],
                pagination:
                const NotificationPaginationModel(
                  currentPage: 1,
                  perPage: 20,
                  total: 0,
                  lastPage: 1,
                ),
              );
        } else {
          final updated =
          current.notifications
              .map(
                (item) =>
            item.isRead
                ? item
                : item.markRead(),
          )
              .toList(
            growable:
            false,
          );

          _data =
              NotificationListModel(
                unreadCount: 0,
                notifications:
                List<AppNotificationModel>.unmodifiable(
                  updated,
                ),
                pagination:
                current.pagination,
              );
        }
      }

      _isMarkingAllRead = false;

      notifyListeners();

      return result;
    } on NotificationException catch (e) {
      _isMarkingAllRead = false;
      _errorMessage =
          e.message;

      notifyListeners();

      return null;
    } catch (_) {
      _isMarkingAllRead = false;
      _errorMessage =
      'Unable to mark all notifications as read.';

      notifyListeners();

      return null;
    }
  }

  // ===========================================================================
  // LOCAL READ STATE
  // ===========================================================================

  void _applyReadState(
      String notificationId,
      ) {
    final current =
        _data;

    if (current == null) {
      return;
    }

    final updated =
    <AppNotificationModel>[];

    var changed =
    false;

    for (final item
    in current.notifications) {
      if (item.id !=
          notificationId) {
        updated.add(
          item,
        );

        continue;
      }

      if (item.isRead) {
        updated.add(
          item,
        );

        continue;
      }

      changed = true;

      if (!_unreadOnly) {
        updated.add(
          item.markRead(),
        );
      }
    }

    if (!changed) {
      return;
    }

    final nextUnreadCount =
    current.unreadCount > 0
        ? current.unreadCount -
        1
        : 0;

    var pagination =
        current.pagination;

    if (_unreadOnly) {
      final total =
      pagination.total > 0
          ? pagination.total -
          1
          : 0;

      var lastPage =
          pagination.lastPage;

      if (total == 0) {
        lastPage = 1;
      } else {
        lastPage =
            (total /
                pagination
                    .perPage)
                .ceil();

        if (lastPage < 1) {
          lastPage = 1;
        }
      }

      var currentPage =
          pagination.currentPage;

      if (currentPage >
          lastPage) {
        currentPage =
            lastPage;
      }

      pagination =
          NotificationPaginationModel(
            currentPage:
            currentPage,
            perPage:
            pagination.perPage,
            total:
            total,
            lastPage:
            lastPage,
          );
    }

    _data =
        NotificationListModel(
          unreadCount:
          nextUnreadCount,
          notifications:
          List<AppNotificationModel>.unmodifiable(
            updated,
          ),
          pagination:
          pagination,
        );
  }

  // ===========================================================================
  // ERROR
  // ===========================================================================

  void clearError() {
    if (_errorMessage == null) {
      return;
    }

    _errorMessage = null;

    notifyListeners();
  }

  // ===========================================================================
  // RESET
  // ===========================================================================

  void clear() {
    _data = null;

    _isLoading = false;
    _isLoadingMore = false;
    _isMarkingAllRead = false;

    _unreadOnly = false;

    _errorMessage = null;

    _markingReadIds.clear();

    notifyListeners();
  }
}