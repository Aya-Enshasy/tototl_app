class Phase3AccountSummary {
  final Map<String, int> contractsByStatus;
  final int contractsAwaitingActionCount;
  final int submissionsAwaitingReviewCount;
  final double fundedTotal;
  final double releasedTotal;
  final double pendingReleaseTotal;
  final Phase3SubscriptionSummary? currentSubscription;

  const Phase3AccountSummary({
    this.contractsByStatus = const <String, int>{},
    this.contractsAwaitingActionCount = 0,
    this.submissionsAwaitingReviewCount = 0,
    this.fundedTotal = 0,
    this.releasedTotal = 0,
    this.pendingReleaseTotal = 0,
    this.currentSubscription,
  });

  factory Phase3AccountSummary.fromPilotDashboardJson(
    Map<String, dynamic> json,
  ) {
    final payment = _asMap(json['payment_summary']);
    return Phase3AccountSummary(
      contractsByStatus: parsePhase3StatusCounts(json['contracts_by_status']),
      contractsAwaitingActionCount:
          _asInt(json['contracts_awaiting_my_action_count']) ?? 0,
      releasedTotal: _asDouble(payment['released_total']) ?? 0,
      pendingReleaseTotal:
          _asDouble(payment['pending_release_total']) ?? 0,
      currentSubscription:
          Phase3SubscriptionSummary.tryParse(json['current_subscription']),
    );
  }

  factory Phase3AccountSummary.fromCompanyDashboardJson(
    Map<String, dynamic> json,
  ) {
    final payment = _asMap(json['payment_summary']);
    return Phase3AccountSummary(
      contractsByStatus: parsePhase3StatusCounts(json['contracts_by_status']),
      contractsAwaitingActionCount:
          _asInt(json['contracts_awaiting_pilot_action_count']) ?? 0,
      submissionsAwaitingReviewCount:
          _asInt(json['submissions_awaiting_review_count']) ?? 0,
      fundedTotal: _asDouble(payment['funded_total']) ?? 0,
      releasedTotal: _asDouble(payment['released_total']) ?? 0,
      pendingReleaseTotal:
          _asDouble(payment['pending_release_total']) ?? 0,
      currentSubscription:
          Phase3SubscriptionSummary.tryParse(json['current_subscription']),
    );
  }

  int count(String status) =>
      contractsByStatus[status.trim().toLowerCase()] ?? 0;

  int get activeContracts => count('active');
  int get inProgressContracts => count('in_progress');
  int get submittedContracts => count('submitted');
  int get completedContracts => count('completed');
}

class Phase3SubscriptionSummary {
  final int id;
  final int planId;
  final String status;
  final DateTime? expirationDate;
  final DateTime? renewalDate;

  const Phase3SubscriptionSummary({
    required this.id,
    required this.planId,
    this.status = '',
    this.expirationDate,
    this.renewalDate,
  });

  static Phase3SubscriptionSummary? tryParse(dynamic raw) {
    if (raw is! Map) return null;
    final json = Map<String, dynamic>.from(raw);
    final id = _asInt(json['id']);
    if (id == null || id <= 0) return null;
    return Phase3SubscriptionSummary(
      id: id,
      planId: _asInt(json['subscription_plan_id']) ?? 0,
      status: _asString(json['status']).toLowerCase(),
      expirationDate: _asDate(json['expiration_date']),
      renewalDate: _asDate(json['renewal_date']),
    );
  }

  bool get isActive => status == 'active';

  String get statusLabel {
    final clean = status.trim();
    if (clean.isEmpty) return 'No subscription';
    return clean
        .split('_')
        .where((e) => e.isNotEmpty)
        .map((e) => '${e[0].toUpperCase()}${e.substring(1)}')
        .join(' ');
  }
}

Map<String, int> parsePhase3StatusCounts(dynamic raw) {
  final result = <String, int>{};

  void put(String key, dynamic value) {
    final k = key.trim().toLowerCase();
    if (k.isEmpty) return;
    final count = _asInt(value);
    if (count != null) result[k] = count;
  }

  if (raw is Map) {
    for (final entry in raw.entries) {
      put(entry.key.toString(), entry.value);
    }
  } else if (raw is List) {
    for (final item in raw) {
      if (item is Map) {
        final map = Map<String, dynamic>.from(item);
        final status = _asString(map['status'] ?? map['name'] ?? map['key']);
        final count = map['count'] ?? map['total'] ?? map['value'];
        if (status.isNotEmpty && count != null) {
          put(status, count);
        } else {
          for (final entry in map.entries) {
            put(entry.key, entry.value);
          }
        }
      } else {
        final status = _asString(item).toLowerCase();
        if (status.isNotEmpty) result[status] = (result[status] ?? 0) + 1;
      }
    }
  }

  return Map<String, int>.unmodifiable(result);
}

Map<String, dynamic> _asMap(dynamic value) =>
    value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};

String _asString(dynamic value) => value?.toString().trim() ?? '';

int? _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '');
}

double? _asDouble(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '');
}

DateTime? _asDate(dynamic value) {
  final text = _asString(value);
  return text.isEmpty ? null : DateTime.tryParse(text);
}
