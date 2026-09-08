
import 'package:tototl_app/features/pilot/models/pilot_job_model.dart';

class PilotDashboardModel {
  const PilotDashboardModel({
    required this.applicationsByStatus,
    required this.recentPublishedJobs,
    required this.dronesCount,
  });

  final PilotDashboardApplicationCounts applicationsByStatus;
  final List<PilotJobModel> recentPublishedJobs;
  final int dronesCount;

  factory PilotDashboardModel.fromJson(Map<String, dynamic> json) {
    return PilotDashboardModel(
      applicationsByStatus: PilotDashboardApplicationCounts.fromRaw(
        json['applications_by_status'],
      ),
      recentPublishedJobs: _parseJobs(
        json['recent_published_jobs'],
      ),
      dronesCount: _asInt(json['drones_count']) ?? 0,
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

    // Defensive support in case a generated schema exposes the aggregate
    // as a list. The real API response currently returns an object/map.
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

int? _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '');
}
