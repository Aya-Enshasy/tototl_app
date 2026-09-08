
import 'package:tototl_app/features/pilot/models/pilot_job_model.dart';

import 'drone_model.dart';

class PilotApplicationModel {
  final int id;
  final int jobPostingId;
  final int pilotProfileId;
  final int droneId;
  final String coverMessage;
  final String status;
  final DateTime? decidedAt;
  final DateTime? withdrawnAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String rejectionReason;
  final PilotJobModel? job;
  final DroneModel? drone;

  const PilotApplicationModel({
    required this.id,
    required this.jobPostingId,
    required this.pilotProfileId,
    required this.droneId,
    this.coverMessage = '',
    this.status = '',
    this.decidedAt,
    this.withdrawnAt,
    this.createdAt,
    this.updatedAt,
    this.rejectionReason = '',
    this.job,
    this.drone,
  });

  factory PilotApplicationModel.fromJson(Map<String, dynamic> json) {
    final rawJob = json['job'] ?? json['job_posting'] ?? json['posting'];
    final rawDrone = json['drone'];

    return PilotApplicationModel(
      id: _asInt(json['id']) ?? 0,
      jobPostingId: _asInt(json['job_posting_id']) ?? 0,
      pilotProfileId: _asInt(json['pilot_profile_id']) ?? 0,
      droneId: _asInt(json['drone_id']) ?? 0,
      coverMessage: _asString(json['cover_message']),
      status: _asString(json['status']),
      decidedAt: _asDate(json['decided_at']),
      withdrawnAt: _asDate(json['withdrawn_at']),
      createdAt: _asDate(json['created_at']),
      updatedAt: _asDate(json['updated_at']),
      rejectionReason: _asString(json['rejection_reason']),
      job: rawJob is Map
          ? PilotJobModel.fromJson(Map<String, dynamic>.from(rawJob))
          : null,
      drone: rawDrone is Map
          ? DroneModel.fromJson(Map<String, dynamic>.from(rawDrone))
          : null,
    );
  }

  PilotApplicationModel copyWith({
    String? status,
    DateTime? decidedAt,
    DateTime? withdrawnAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? coverMessage,
    String? rejectionReason,
    PilotJobModel? job,
    DroneModel? drone,
  }) {
    return PilotApplicationModel(
      id: id,
      jobPostingId: jobPostingId,
      pilotProfileId: pilotProfileId,
      droneId: droneId,
      coverMessage: coverMessage ?? this.coverMessage,
      status: status ?? this.status,
      decidedAt: decidedAt ?? this.decidedAt,
      withdrawnAt: withdrawnAt ?? this.withdrawnAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      job: job ?? this.job,
      drone: drone ?? this.drone,
    );
  }

  bool get isPending => status.toLowerCase() == 'pending';
  bool get isAccepted => status.toLowerCase() == 'accepted';
  bool get isRejected => status.toLowerCase() == 'rejected';
  bool get isWithdrawn => status.toLowerCase() == 'withdrawn';

  String get statusLabel {
    final value = status.trim();
    if (value.isEmpty) return 'Pending';

    return value
        .split(RegExp(r'[_\s-]+'))
        .where((part) => part.isNotEmpty)
        .map((part) => '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}')
        .join(' ');
  }

  String get jobTitle {
    final value = job?.title.trim() ?? '';
    if (value.isNotEmpty) return value;
    return jobPostingId > 0 ? 'Job #$jobPostingId' : 'Job Application';
  }

  String get companyLabel {
    final value = job?.company?.displayName.trim() ?? '';
    return value;
  }

  String get droneTitle {
    final value = drone?.title.trim() ?? '';
    if (value.isNotEmpty) return value;
    return droneId > 0 ? 'Drone #$droneId' : 'Selected drone';
  }

  String get submittedLabel =>
      createdAt == null ? 'Submitted' : _friendlyDateTime(createdAt!);

  String get decisionLabel =>
      decidedAt == null ? '' : _friendlyDateTime(decidedAt!);

  String get withdrawnLabel =>
      withdrawnAt == null ? '' : _friendlyDateTime(withdrawnAt!);
}

String _asString(dynamic value) {
  if (value == null) return '';
  return value.toString().trim();
}

int? _asInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  return int.tryParse(value.toString());
}

DateTime? _asDate(dynamic value) {
  if (value == null) return null;
  final text = value.toString().trim();
  if (text.isEmpty) return null;
  return DateTime.tryParse(text);
}

String _friendlyDateTime(DateTime value) {
  final local = value.toLocal();
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  final hour = local.hour == 0
      ? 12
      : local.hour > 12
          ? local.hour - 12
          : local.hour;
  final minute = local.minute.toString().padLeft(2, '0');
  final period = local.hour >= 12 ? 'PM' : 'AM';

  return '${months[local.month - 1]} ${local.day}, ${local.year} · '
      '$hour:$minute $period';
}
