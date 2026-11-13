class NotificationListModel {
  final int unreadCount;
  final List<AppNotificationModel> notifications;
  final NotificationPaginationModel pagination;

  const NotificationListModel({
    this.unreadCount = 0,
    this.notifications = const [],
    this.pagination = const NotificationPaginationModel(),
  });

  factory NotificationListModel.fromJson(
      Map<String, dynamic> json,
      ) {
    final rawNotifications = json['notifications'];
    final rawPagination = json['pagination'];

    return NotificationListModel(
      unreadCount: _asInt(
        json['unread_count'],
      ) ??
          0,
      notifications: rawNotifications is List
          ? rawNotifications
          .whereType<Map>()
          .map(
            (item) => AppNotificationModel.fromJson(
          Map<String, dynamic>.from(item),
        ),
      )
          .toList(
        growable: false,
      )
          : const [],
      pagination: rawPagination is Map
          ? NotificationPaginationModel.fromJson(
        Map<String, dynamic>.from(
          rawPagination,
        ),
      )
          : const NotificationPaginationModel(),
    );
  }

  bool get isEmpty =>
      notifications.isEmpty;

  bool get isNotEmpty =>
      notifications.isNotEmpty;

  bool get hasUnread =>
      unreadCount > 0;

  bool get hasMore =>
      pagination.currentPage <
          pagination.lastPage;
}

class AppNotificationModel {
  final String id;
  final String type;

  final String title;
  final String body;

  final String relatedType;
  final int? relatedId;

  final bool read;
  final DateTime? readAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  final String notifiableType;
  final int? notifiableId;

  const AppNotificationModel({
    required this.id,
    required this.type,
    this.title = '',
    this.body = '',
    this.relatedType = '',
    this.relatedId,
    this.read = false,
    this.readAt,
    this.createdAt,
    this.updatedAt,
    this.notifiableType = '',
    this.notifiableId,
  });

  factory AppNotificationModel.fromJson(
      Map<String, dynamic> json,
      ) {
    final payload =
    _notificationPayload(
      json['data'],
    );

    final title =
    _firstNonEmpty([
      json['title'],
      payload['title'],
    ]);

    final body =
    _firstNonEmpty([
      json['body'],
      payload['body'],
      payload['message'],
    ]);

    final relatedType =
    _firstNonEmpty([
      json['related_type'],
      payload['related_type'],
      payload['related_entity_type'],
    ]).toLowerCase();

    final relatedId =
    _asInt(
      json['related_id'] ??
          payload['related_id'] ??
          payload['related_entity_id'],
    );

    final readAt =
    _asDate(
      json['read_at'],
    );

    final rawRead =
    json['read'];

    return AppNotificationModel(
      id: _asString(
        json['id'],
      ),
      type: _asString(
        json['type'],
      ).toLowerCase(),
      title: title,
      body: body,
      relatedType: relatedType,
      relatedId: relatedId,
      read: rawRead is bool
          ? rawRead
          : readAt != null,
      readAt: readAt,
      createdAt: _asDate(
        json['created_at'],
      ),
      updatedAt: _asDate(
        json['updated_at'],
      ),
      notifiableType: _asString(
        json['notifiable_type'],
      ),
      notifiableId: _asInt(
        json['notifiable_id'],
      ),
    );
  }

  bool get isUnread =>
      !read;

  bool get isRead =>
      read;

  bool get hasTitle =>
      title.trim().isNotEmpty;

  bool get hasBody =>
      body.trim().isNotEmpty;

  bool get hasRelatedEntity =>
      relatedType.isNotEmpty &&
          relatedId != null &&
          relatedId! > 0;

  bool get isAccountStatusChanged =>
      type == 'account_status_changed';

  bool get isApplicationReceived =>
      type == 'application_received';

  bool get isApplicationStatusChanged =>
      type == 'application_status_changed';

  bool get isContractCreated =>
      type == 'contract_created';

  bool get isContractStatusChanged =>
      type == 'contract_status_changed';

  bool get isWorkSubmitted =>
      type == 'work_submitted';

  bool get isWorkReviewed =>
      type == 'work_reviewed';

  bool get isPaymentStatusChanged =>
      type == 'payment_status_changed';

  bool get isSubscriptionStatusChanged =>
      type == 'subscription_status_changed';

  bool get isReviewReceived =>
      type == 'review_received';

  bool get relatesToUser =>
      relatedType == 'user';

  bool get relatesToApplication =>
      relatedType == 'job_application';

  bool get relatesToContract =>
      relatedType == 'contract';

  bool get relatesToSubmission =>
      relatedType == 'contract_submission';

  bool get relatesToPayment =>
      relatedType == 'payment';

  bool get relatesToSubscription =>
      relatedType == 'user_subscription';

  bool get relatesToReview =>
      relatedType == 'review';

  String get displayTitle {
    final value =
    title.trim();

    if (value.isNotEmpty) {
      return value;
    }

    switch (type) {
      case 'account_status_changed':
        return 'Account Update';

      case 'application_received':
        return 'New Application';

      case 'application_status_changed':
        return 'Application Update';

      case 'contract_created':
        return 'New Contract';

      case 'contract_status_changed':
        return 'Contract Update';

      case 'work_submitted':
        return 'Work Submitted';

      case 'work_reviewed':
        return 'Work Review';

      case 'payment_status_changed':
        return 'Payment Update';

      case 'subscription_status_changed':
        return 'Subscription Update';

      case 'review_received':
        return 'New Review';

      default:
        return 'Notification';
    }
  }

  String get displayBody {
    final value =
    body.trim();

    if (value.isNotEmpty) {
      return value;
    }

    return 'You have a new update.';
  }

  String get createdLabel =>
      _friendlyDateTime(
        createdAt,
      );

  AppNotificationModel copyWith({
    String? id,
    String? type,
    String? title,
    String? body,
    String? relatedType,
    int? relatedId,
    bool? read,
    DateTime? readAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? notifiableType,
    int? notifiableId,
  }) {
    return AppNotificationModel(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      body: body ?? this.body,
      relatedType:
      relatedType ??
          this.relatedType,
      relatedId:
      relatedId ??
          this.relatedId,
      read: read ?? this.read,
      readAt:
      readAt ??
          this.readAt,
      createdAt:
      createdAt ??
          this.createdAt,
      updatedAt:
      updatedAt ??
          this.updatedAt,
      notifiableType:
      notifiableType ??
          this.notifiableType,
      notifiableId:
      notifiableId ??
          this.notifiableId,
    );
  }

  AppNotificationModel markRead({
    DateTime? at,
  }) {
    return copyWith(
      read: true,
      readAt:
      readAt ??
          at ??
          DateTime.now().toUtc(),
    );
  }
}

class NotificationPaginationModel {
  final int currentPage;
  final int perPage;
  final int total;
  final int lastPage;

  const NotificationPaginationModel({
    this.currentPage = 1,
    this.perPage = 20,
    this.total = 0,
    this.lastPage = 1,
  });

  factory NotificationPaginationModel.fromJson(
      Map<String, dynamic> json,
      ) {
    return NotificationPaginationModel(
      currentPage: _asInt(
        json['current_page'],
      ) ??
          1,
      perPage: _asInt(
        json['per_page'],
      ) ??
          20,
      total: _asInt(
        json['total'],
      ) ??
          0,
      lastPage: _asInt(
        json['last_page'],
      ) ??
          1,
    );
  }

  bool get hasNextPage =>
      currentPage <
          lastPage;
}

Map<String, dynamic> _notificationPayload(
    dynamic raw,
    ) {
  if (raw is Map) {
    return Map<String, dynamic>.from(
      raw,
    );
  }

  if (raw is List) {
    final result =
    <String, dynamic>{};

    for (final item in raw) {
      if (item is! Map) {
        continue;
      }

      final map =
      Map<String, dynamic>.from(
        item,
      );

      final key =
      _asString(
        map['key'] ??
            map['name'],
      );

      if (key.isNotEmpty) {
        result[key] =
        map['value'];
        continue;
      }

      result.addAll(
        map,
      );
    }

    return result;
  }

  return const {};
}

String _firstNonEmpty(
    List<dynamic> values,
    ) {
  for (final value in values) {
    final text =
    _asString(
      value,
    );

    if (text.isNotEmpty) {
      return text;
    }
  }

  return '';
}

String _asString(
    dynamic value,
    ) {
  if (value == null) {
    return '';
  }

  final text =
  value
      .toString()
      .trim();

  if (text.toLowerCase() ==
      'null') {
    return '';
  }

  return text;
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

DateTime? _asDate(
    dynamic value,
    ) {
  if (value == null) {
    return null;
  }

  final text =
  value
      .toString()
      .trim();

  if (text.isEmpty) {
    return null;
  }

  return DateTime.tryParse(
    text,
  );
}

String _friendlyDateTime(
    DateTime? value,
    ) {
  if (value == null) {
    return '';
  }

  final local =
  value.toLocal();

  final now =
  DateTime.now();

  final difference =
  now.difference(
    local,
  );

  if (!difference.isNegative) {
    if (difference.inSeconds <
        60) {
      return 'Just now';
    }

    if (difference.inMinutes <
        60) {
      final minutes =
          difference.inMinutes;

      return minutes == 1
          ? '1 min ago'
          : '$minutes mins ago';
    }

    if (difference.inHours <
        24) {
      final hours =
          difference.inHours;

      return hours == 1
          ? '1 hour ago'
          : '$hours hours ago';
    }

    if (difference.inDays <
        7) {
      final days =
          difference.inDays;

      return days == 1
          ? 'Yesterday'
          : '$days days ago';
    }
  }

  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  return '${months[local.month - 1]} '
      '${local.day}, '
      '${local.year}';
}