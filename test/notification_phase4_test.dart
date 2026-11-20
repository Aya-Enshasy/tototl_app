import 'package:flutter_test/flutter_test.dart';
import 'package:tototl_app/core/notifications/push_notification_coordinator.dart';
import 'package:tototl_app/features/notifications/models/notification_model.dart';

void main() {
  const uuid = '90b8c74e-5973-4eb1-ac17-6d2bb0ffcc1f';

  test('Phase 4 inbox supports UUID ids, unread count and page envelope', () {
    final list = NotificationListModel.fromJson({
      'unread_count': 3,
      'notifications': [
        {
          'id': uuid,
          'type': 'review_received',
          'title': 'You received a review',
          'body': 'A rating was received.',
          'related_type': 'review',
          'related_id': 2,
          'read': false,
          'read_at': null,
          'created_at': '2026-10-25T14:10:41.000000Z',
        }
      ],
      'pagination': {'current_page': 1, 'per_page': 20,
        'total': 1, 'last_page': 1},
    });
    expect(list.unreadCount, 3);
    expect(list.notifications.single.id, uuid);
    expect(list.notifications.single.isReviewReceived, true);
    expect(list.notifications.single.relatedType, 'review');
    expect(list.notifications.single.relatedId, 2);
    expect(list.notifications.single.isUnread, true);
    expect(list.notifications.single.markRead().isRead, true);
  });

  test('All ten backend notification types parse with expected entity types', () {
    const types = {
      'account_status_changed': 'user',
      'application_received': 'job_application',
      'application_status_changed': 'job_application',
      'contract_created': 'contract',
      'contract_status_changed': 'contract',
      'work_submitted': 'contract_submission',
      'work_reviewed': 'contract_submission',
      'payment_status_changed': 'payment',
      'subscription_status_changed': 'user_subscription',
      'review_received': 'review',
    };
    for (final entry in types.entries) {
      final item = AppNotificationModel.fromJson({
        'id': uuid, 'type': entry.key,
        'related_type': entry.value, 'related_id': 42,
        'read': false,
      });
      expect(item.type, entry.key);
      expect(item.relatedType, entry.value);
      expect(item.relatedId, 42);
      expect(item.hasRelatedEntity, true);
    }
  });

  test('FCM notification data and nested JSON use the same routing metadata', () {
    final item = PushNotificationCoordinator.notificationFromPayload({
      'notification_id': uuid,
      'data': '{"type":"contract_created","related_type":"contract",'
          '"related_id":73}',
    }, title: 'New contract');
    expect(item.id, uuid);
    expect(item.type, 'contract_created');
    expect(item.relatedType, 'contract');
    expect(item.relatedId, 73);
    expect(item.title, 'New contract');
  });

  test('An FCM message missing an API UUID still renders safely', () {
    final item = PushNotificationCoordinator.notificationFromPayload({
      'type': 'application_status_changed',
      'related_type': 'job_application',
      'related_id': '11',
    }, notificationId: '0:firebasemessageid');
    expect(item.relatedId, 11);
    expect(item.id, '0:firebasemessageid');
  });
}
