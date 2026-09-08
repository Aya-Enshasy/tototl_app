import 'package:tototl_app/features/pilot/models/pilot_application_model.dart';

import 'drone_model.dart';

class PilotHomeSnapshot {
  const PilotHomeSnapshot({
    this.drones = const <PilotHomeDroneItem>[],
    this.applications = const <PilotHomeApplicationItem>[],
    this.cachedAt,
  });

  final List<PilotHomeDroneItem> drones;
  final List<PilotHomeApplicationItem> applications;
  final DateTime? cachedAt;

  bool get hasContent => drones.isNotEmpty || applications.isNotEmpty;

  PilotHomeSnapshot copyWith({
    List<PilotHomeDroneItem>? drones,
    List<PilotHomeApplicationItem>? applications,
    DateTime? cachedAt,
  }) {
    return PilotHomeSnapshot(
      drones: drones ?? this.drones,
      applications: applications ?? this.applications,
      cachedAt: cachedAt ?? this.cachedAt,
    );
  }

  factory PilotHomeSnapshot.fromJson(Map<String, dynamic> json) {
    final rawDrones = json['drones'];
    final rawApplications = json['applications'];

    return PilotHomeSnapshot(
      drones: rawDrones is List
          ? rawDrones
              .whereType<Map>()
              .map(
                (item) => PilotHomeDroneItem.fromJson(
                  Map<String, dynamic>.from(item),
                ),
              )
              .where((item) => item.id > 0)
              .toList(growable: false)
          : const <PilotHomeDroneItem>[],
      applications: rawApplications is List
          ? rawApplications
              .whereType<Map>()
              .map(
                (item) => PilotHomeApplicationItem.fromJson(
                  Map<String, dynamic>.from(item),
                ),
              )
              .where((item) => item.id > 0)
              .toList(growable: false)
          : const <PilotHomeApplicationItem>[],
      cachedAt: _asDate(json['cached_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'drones': drones.map((item) => item.toJson()).toList(growable: false),
      'applications':
          applications.map((item) => item.toJson()).toList(growable: false),
      'cached_at': cachedAt?.toIso8601String(),
    };
  }
}

class PilotHomeDroneItem {
  const PilotHomeDroneItem({
    required this.id,
    this.title = 'Drone',
    this.year = '',
    this.serialNumber = '',
    this.imageUrl = '',
    this.capabilities = const <String>[],
  });

  final int id;
  final String title;
  final String year;
  final String serialNumber;
  final String imageUrl;
  final List<String> capabilities;

  factory PilotHomeDroneItem.fromDrone(DroneModel drone) {
    return PilotHomeDroneItem(
      id: drone.id,
      title: drone.title.trim().isEmpty ? 'Drone' : drone.title.trim(),
      year: drone.yearLabel.trim(),
      serialNumber: drone.serialNumber.trim(),
      imageUrl: drone.imageUrl.trim(),
      capabilities: drone.capabilities
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty)
          .take(4)
          .toList(growable: false),
    );
  }

  factory PilotHomeDroneItem.fromJson(Map<String, dynamic> json) {
    final rawCapabilities = json['capabilities'];

    return PilotHomeDroneItem(
      id: _asInt(json['id']) ?? 0,
      title: _asString(json['title'], fallback: 'Drone'),
      year: _asString(json['year']),
      serialNumber: _asString(json['serial_number']),
      imageUrl: _asString(json['image_url']),
      capabilities: rawCapabilities is List
          ? rawCapabilities
              .map((item) => item?.toString().trim() ?? '')
              .where((item) => item.isNotEmpty)
              .take(4)
              .toList(growable: false)
          : const <String>[],
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'title': title,
      'year': year,
      'serial_number': serialNumber,
      'image_url': imageUrl,
      'capabilities': capabilities,
    };
  }
}

class PilotHomeApplicationItem {
  const PilotHomeApplicationItem({
    required this.id,
    required this.jobPostingId,
    this.jobTitle = 'Job Application',
    this.company = '',
    this.location = '',
    this.status = 'pending',
    this.createdAt,
  });

  final int id;
  final int jobPostingId;
  final String jobTitle;
  final String company;
  final String location;
  final String status;
  final DateTime? createdAt;

  factory PilotHomeApplicationItem.fromApplication(
    PilotApplicationModel application,
  ) {
    final job = application.job;

    return PilotHomeApplicationItem(
      id: application.id,
      jobPostingId: application.jobPostingId,
      jobTitle: application.jobTitle,
      company: application.companyLabel,
      location: job?.locationLabel.trim() ?? '',
      status: application.status.trim().isEmpty
          ? 'pending'
          : application.status.trim().toLowerCase(),
      createdAt: application.createdAt,
    );
  }

  factory PilotHomeApplicationItem.fromJson(Map<String, dynamic> json) {
    return PilotHomeApplicationItem(
      id: _asInt(json['id']) ?? 0,
      jobPostingId: _asInt(json['job_posting_id']) ?? 0,
      jobTitle: _asString(json['job_title'], fallback: 'Job Application'),
      company: _asString(json['company']),
      location: _asString(json['location']),
      status: _asString(json['status'], fallback: 'pending').toLowerCase(),
      createdAt: _asDate(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'job_posting_id': jobPostingId,
      'job_title': jobTitle,
      'company': company,
      'location': location,
      'status': status,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  String get statusLabel => _pretty(status);

  String get submittedLabel {
    final value = createdAt;
    if (value == null) return 'Recently submitted';

    final local = value.toLocal();
    const months = <String>[
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

    return '${months[local.month - 1]} ${local.day}, ${local.year}';
  }
}

String _asString(dynamic value, {String fallback = ''}) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? fallback : text;
}

int? _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '');
}

DateTime? _asDate(dynamic value) {
  final text = value?.toString().trim() ?? '';
  if (text.isEmpty) return null;
  return DateTime.tryParse(text);
}

String _pretty(String value) {
  final clean = value.trim();
  if (clean.isEmpty) return '';

  return clean
      .split(RegExp(r'[_\s-]+'))
      .where((item) => item.isNotEmpty)
      .map(
        (item) =>
            '${item[0].toUpperCase()}${item.substring(1).toLowerCase()}',
      )
      .join(' ');
}
