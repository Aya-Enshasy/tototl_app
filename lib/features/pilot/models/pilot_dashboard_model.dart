import 'package:tototl_app/features/pilot/models/pilot_job_model.dart';

class PilotDashboardModel {
  const PilotDashboardModel({
    required this.applicationsByStatus,
    required this.recentPublishedJobs,
    required this.dronesCount,
    this.contractsByStatus = const {},
    this.contractsAwaitingMyActionCount = 0,
    this.paymentSummary = const PilotDashboardPaymentSummary(),
    this.currentSubscription,
  });

  final PilotDashboardApplicationCounts applicationsByStatus;
  final List<PilotJobModel> recentPublishedJobs;
  final int dronesCount;

  final Map<String, int> contractsByStatus;
  final int contractsAwaitingMyActionCount;
  final PilotDashboardPaymentSummary paymentSummary;
  final PilotDashboardSubscription? currentSubscription;

  factory PilotDashboardModel.fromJson(Map<String, dynamic> json) {
    final rawSubscription = json['current_subscription'];

    return PilotDashboardModel(
      applicationsByStatus: PilotDashboardApplicationCounts.fromRaw(
        json['applications_by_status'],
      ),
      recentPublishedJobs: _parseJobs(
        json['recent_published_jobs'],
      ),
      dronesCount: _asInt(json['drones_count']) ?? 0,
      contractsByStatus: _asIntMap(json['contracts_by_status']),
      contractsAwaitingMyActionCount:
          _asInt(json['contracts_awaiting_my_action_count']) ?? 0,
      paymentSummary: PilotDashboardPaymentSummary.fromRaw(
        json['payment_summary'],
      ),
      currentSubscription: rawSubscription is Map
          ? PilotDashboardSubscription.fromJson(
              Map<String, dynamic>.from(rawSubscription),
            )
          : null,
    );
  }

  static List<PilotJobModel> _parseJobs(dynamic raw) {
    if (raw is! List) {
      return const <PilotJobModel>[];
    }

    return raw
        .whereType<Map>()
        .map(
          (item) => PilotJobModel.fromJson(
            Map<String, dynamic>.from(item),
          ),
        )
        .where((job) => job.id > 0)
        .toList(growable: false);
  }

  int get activeContracts {
    const activeKeys = {
      'accepted',
      'active',
      'in_progress',
      'submitted',
    };

    var total = 0;
    for (final entry in contractsByStatus.entries) {
      if (activeKeys.contains(entry.key.trim().toLowerCase())) {
        total += entry.value;
      }
    }
    return total;
  }
}

class PilotDashboardApplicationCounts {
  const PilotDashboardApplicationCounts({
    this.pending = 0,
    this.accepted = 0,
    this.rejected = 0,
    this.withdrawn = 0,
  });

  final int pending;
  final int accepted;
  final int rejected;
  final int withdrawn;

  int get total => pending + accepted + rejected + withdrawn;

  factory PilotDashboardApplicationCounts.fromRaw(dynamic raw) {
    if (raw is Map) {
      final map = Map<String, dynamic>.from(raw);

      return PilotDashboardApplicationCounts(
        pending: _asInt(map['pending']) ?? 0,
        accepted: _asInt(map['accepted']) ?? 0,
        rejected: _asInt(map['rejected']) ?? 0,
        withdrawn: _asInt(map['withdrawn']) ?? 0,
      );
    }

    if (raw is List) {
      int pending = 0;
      int accepted = 0;
      int rejected = 0;
      int withdrawn = 0;

      for (final item in raw) {
        if (item is! Map) continue;
        final map = Map<String, dynamic>.from(item);
        final status = map['status']?.toString().trim().toLowerCase() ?? '';
        final count = _asInt(map['count']) ?? 0;

        switch (status) {
          case 'pending':
            pending = count;
            break;
          case 'accepted':
            accepted = count;
            break;
          case 'rejected':
            rejected = count;
            break;
          case 'withdrawn':
            withdrawn = count;
            break;
        }
      }

      return PilotDashboardApplicationCounts(
        pending: pending,
        accepted: accepted,
        rejected: rejected,
        withdrawn: withdrawn,
      );
    }

    return const PilotDashboardApplicationCounts();
  }
}

class PilotDashboardPaymentSummary {
  const PilotDashboardPaymentSummary({
    this.releasedTotal = 0,
    this.pendingReleaseTotal = 0,
  });

  final double releasedTotal;
  final double pendingReleaseTotal;

  factory PilotDashboardPaymentSummary.fromRaw(dynamic raw) {
    if (raw is! Map) {
      return const PilotDashboardPaymentSummary();
    }

    final map = Map<String, dynamic>.from(raw);
    return PilotDashboardPaymentSummary(
      releasedTotal: _asDouble(map['released_total']) ?? 0,
      pendingReleaseTotal:
          _asDouble(map['pending_release_total']) ?? 0,
    );
  }
}

class PilotDashboardSubscription {
  const PilotDashboardSubscription({
    required this.id,
    this.userId = 0,
    this.subscriptionPlanId = 0,
    this.status = '',
    this.startDate,
    this.expirationDate,
    this.renewalDate,
    this.cancelledAt,
  });

  final int id;
  final int userId;
  final int subscriptionPlanId;
  final String status;
  final DateTime? startDate;
  final DateTime? expirationDate;
  final DateTime? renewalDate;
  final DateTime? cancelledAt;

  factory PilotDashboardSubscription.fromJson(
    Map<String, dynamic> json,
  ) {
    return PilotDashboardSubscription(
      id: _asInt(json['id']) ?? 0,
      userId: _asInt(json['user_id']) ?? 0,
      subscriptionPlanId:
          _asInt(json['subscription_plan_id']) ?? 0,
      status: _asString(json['status']).toLowerCase(),
      startDate: _asDate(json['start_date']),
      expirationDate: _asDate(json['expiration_date']),
      renewalDate: _asDate(json['renewal_date']),
      cancelledAt: _asDate(json['cancelled_at']),
    );
  }

  bool get isActive => status == 'active';
}

int? _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '');
}

double? _asDouble(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '');
}

String _asString(dynamic value) =>
    value == null ? '' : value.toString().trim();

DateTime? _asDate(dynamic value) {
  final text = _asString(value);
  return text.isEmpty ? null : DateTime.tryParse(text);
}

Map<String, int> _asIntMap(dynamic value) {
  final result = <String, int>{};

  if (value is Map) {
    for (final entry in value.entries) {
      final key = entry.key.toString().trim();
      if (key.isEmpty) continue;
      result[key] = _asInt(entry.value) ?? 0;
    }
  } else if (value is List) {
    for (final item in value) {
      if (item is! Map) continue;
      final map = Map<String, dynamic>.from(item);
      final key = _asString(map['status']).toLowerCase();
      if (key.isEmpty) continue;
      result[key] = _asInt(map['count']) ?? 0;
    }
  }

  return Map<String, int>.unmodifiable(result);
}
