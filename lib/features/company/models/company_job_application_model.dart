class CompanyJobApplicationModel {
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

  /// The API documentation describes the company applicants endpoint as
  /// returning the pilot profile + committed drone. These nested values are
  /// parsed when the backend includes them, but the model also works safely
  /// when only the scalar IDs are returned.
  final CompanyApplicantPilotModel? pilotProfile;
  final CompanyApplicantDroneModel? drone;

  const CompanyJobApplicationModel({
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
    this.pilotProfile,
    this.drone,
  });

  factory CompanyJobApplicationModel.fromJson(
    Map<String, dynamic> json,
  ) {
    final pilotRaw =
        json['pilot_profile'] ?? json['pilot'] ?? json['profile'];

    final droneRaw =
        json['drone'] ?? json['committed_drone'];

    return CompanyJobApplicationModel(
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
      pilotProfile: pilotRaw is Map
          ? CompanyApplicantPilotModel.fromJson(
              Map<String, dynamic>.from(pilotRaw),
            )
          : null,
      drone: droneRaw is Map
          ? CompanyApplicantDroneModel.fromJson(
              Map<String, dynamic>.from(droneRaw),
            )
          : null,
    );
  }
}

class CompanyApplicantPilotModel {
  final int id;
  final String name;
  final String profilePhoto;
  final int? experienceYears;
  final String nationality;
  final String country;
  final String state;
  final String city;

  const CompanyApplicantPilotModel({
    required this.id,
    this.name = '',
    this.profilePhoto = '',
    this.experienceYears,
    this.nationality = '',
    this.country = '',
    this.state = '',
    this.city = '',
  });

  factory CompanyApplicantPilotModel.fromJson(
    Map<String, dynamic> json,
  ) {
    final userRaw = json['user'];
    final user = userRaw is Map
        ? Map<String, dynamic>.from(userRaw)
        : const <String, dynamic>{};

    final resolvedName = _firstNonEmpty([
      _asString(json['name']),
      _asString(json['full_name']),
      _asString(user['name']),
      _asString(user['username']),
    ]);

    return CompanyApplicantPilotModel(
      id: _asInt(json['id']) ?? 0,
      name: resolvedName,
      profilePhoto: _firstNonEmpty([
        _asString(json['profile_photo']),
        _asString(json['photo']),
      ]),
      experienceYears:
          _asInt(json['experience_years'] ?? json['years_experience']),
      nationality: _asString(json['nationality']),
      country:
          _asString(json['current_country'] ?? json['country']),
      state:
          _asString(json['current_state'] ?? json['state']),
      city:
          _asString(json['current_city'] ?? json['city']),
    );
  }

  String get location {
    final parts = [city, state, country]
        .where((item) => item.trim().isNotEmpty)
        .toList();

    return parts.join(', ');
  }
}

class CompanyApplicantDroneModel {
  final int id;
  final String make;
  final String model;
  final List<String> capabilities;

  const CompanyApplicantDroneModel({
    required this.id,
    this.make = '',
    this.model = '',
    this.capabilities = const [],
  });

  factory CompanyApplicantDroneModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return CompanyApplicantDroneModel(
      id: _asInt(json['id']) ?? 0,
      make: _asString(json['make']),
      model: _asString(json['model']),
      capabilities: _asStringList(json['capabilities']),
    );
  }

  String get displayName {
    final value = [make, model]
        .where((item) => item.trim().isNotEmpty)
        .join(' ');

    return value.isEmpty ? 'Drone #$id' : value;
  }
}

String _firstNonEmpty(List<String> values) {
  for (final value in values) {
    if (value.trim().isNotEmpty) return value.trim();
  }
  return '';
}

String _asString(dynamic value) =>
    value == null ? '' : value.toString().trim();

int? _asInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  return int.tryParse(value.toString());
}

DateTime? _asDate(dynamic value) {
  if (value == null) return null;
  final text = value.toString().trim();
  return text.isEmpty ? null : DateTime.tryParse(text);
}

List<String> _asStringList(dynamic value) {
  if (value is! List) return const [];

  return value
      .map((item) => item?.toString().trim() ?? '')
      .where((item) => item.isNotEmpty)
      .toList();
}
