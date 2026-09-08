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

  /// GET /company/job-postings/{id}/applicants is documented as returning
  /// the applicant with pilot profile + committed drone.
  ///
  /// The generated schema still references JobApplication, so both relations
  /// remain nullable and are parsed defensively.
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
        json['pilot_profile'] ??
        json['pilot'] ??
        json['profile'];

    final droneRaw =
        json['drone'] ??
        json['committed_drone'];

    return CompanyJobApplicationModel(
      id: _asInt(json['id']) ?? 0,
      jobPostingId:
          _asInt(json['job_posting_id']) ?? 0,
      pilotProfileId:
          _asInt(json['pilot_profile_id']) ?? 0,
      droneId:
          _asInt(json['drone_id']) ?? 0,
      coverMessage:
          _asString(json['cover_message']),
      status:
          _asString(json['status']),
      decidedAt:
          _asDate(json['decided_at']),
      withdrawnAt:
          _asDate(json['withdrawn_at']),
      createdAt:
          _asDate(json['created_at']),
      updatedAt:
          _asDate(json['updated_at']),
      rejectionReason:
          _asString(json['rejection_reason']),
      pilotProfile: pilotRaw is Map
          ? CompanyApplicantPilotModel.fromJson(
              Map<String, dynamic>.from(
                pilotRaw,
              ),
            )
          : null,
      drone: droneRaw is Map
          ? CompanyApplicantDroneModel.fromJson(
              Map<String, dynamic>.from(
                droneRaw,
              ),
            )
          : null,
    );
  }

  CompanyJobApplicationModel copyWith({
    String? coverMessage,
    String? status,
    DateTime? decidedAt,
    DateTime? withdrawnAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? rejectionReason,
    CompanyApplicantPilotModel? pilotProfile,
    CompanyApplicantDroneModel? drone,
  }) {
    return CompanyJobApplicationModel(
      id: id,
      jobPostingId: jobPostingId,
      pilotProfileId: pilotProfileId,
      droneId: droneId,
      coverMessage:
          coverMessage ?? this.coverMessage,
      status:
          status ?? this.status,
      decidedAt:
          decidedAt ?? this.decidedAt,
      withdrawnAt:
          withdrawnAt ?? this.withdrawnAt,
      createdAt:
          createdAt ?? this.createdAt,
      updatedAt:
          updatedAt ?? this.updatedAt,
      rejectionReason:
          rejectionReason ?? this.rejectionReason,
      pilotProfile:
          pilotProfile ?? this.pilotProfile,
      drone:
          drone ?? this.drone,
    );
  }

  bool get isPending =>
      status.trim().toLowerCase() == 'pending';

  bool get isAccepted =>
      status.trim().toLowerCase() == 'accepted';

  bool get isRejected =>
      status.trim().toLowerCase() == 'rejected';

  bool get isWithdrawn =>
      status.trim().toLowerCase() == 'withdrawn';

  String get statusLabel =>
      _pretty(status.isEmpty ? 'pending' : status);
}

class CompanyApplicantPilotModel {
  final int id;
  final int? userId;

  final String name;
  final String profilePhoto;

  final String bio;
  final int? experienceYears;
  final String nationality;
  final DateTime? dateOfBirth;
  final String linkedinUrl;
  final String previousCompany;
  final List<String> languages;

  final String country;
  final String state;
  final String city;

  const CompanyApplicantPilotModel({
    required this.id,
    this.userId,
    this.name = '',
    this.profilePhoto = '',
    this.bio = '',
    this.experienceYears,
    this.nationality = '',
    this.dateOfBirth,
    this.linkedinUrl = '',
    this.previousCompany = '',
    this.languages = const [],
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

    final rawPhoto =
        json['profile_photo'] ??
        json['photo'] ??
        user['profile_photo'];

    String photo = '';

    if (rawPhoto is String) {
      photo = rawPhoto.trim();
    } else if (rawPhoto is Map) {
      photo = _firstNonEmpty([
        _asString(rawPhoto['url']),
        _asString(rawPhoto['original_url']),
        _asString(rawPhoto['path']),
      ]);
    }

    return CompanyApplicantPilotModel(
      id:
          _asInt(json['id']) ?? 0,
      userId:
          _asInt(json['user_id'] ?? user['id']),
      name:
          resolvedName,
      profilePhoto:
          photo,
      bio:
          _asString(json['bio']),
      experienceYears:
          _asInt(
        json['experience_years'] ??
            json['years_experience'],
      ),
      nationality:
          _asString(json['nationality']),
      dateOfBirth:
          _asDate(json['date_of_birth']),
      linkedinUrl:
          _asString(json['linkedin_url']),
      previousCompany:
          _asString(json['previous_company']),
      languages:
          _asStringList(json['languages']),
      country:
          _asString(
        json['current_country'] ??
            json['country'],
      ),
      state:
          _asString(
        json['current_state'] ??
            json['state'],
      ),
      city:
          _asString(
        json['current_city'] ??
            json['city'],
      ),
    );
  }

  String get displayName {
    final clean = name.trim();

    return clean.isNotEmpty
        ? clean
        : 'Pilot #$id';
  }

  String get location {
    final parts = <String>[
      city,
      state,
      country,
    ]
        .where(
          (item) =>
              item.trim().isNotEmpty,
        )
        .toList();

    return parts.join(', ');
  }

  String get experienceLabel {
    if (experienceYears == null) {
      return '';
    }

    return '$experienceYears year'
        '${experienceYears == 1 ? '' : 's'} experience';
  }
}

class CompanyApplicantDroneModel {
  final int id;
  final int? pilotProfileId;

  final String make;
  final String model;
  final int? manufactureYear;
  final String serialNumber;
  final double? weightKg;

  final List<String> capabilities;

  final int? flightTimePerBatteryMinutes;
  final int? totalBatteries;
  final String batteryType;

  final double? batteryUsageFee;
  final double? hourlyRate;
  final double? dailyRate;
  final double? emergencyCalloutFee;

  final String imageUrl;

  const CompanyApplicantDroneModel({
    required this.id,
    this.pilotProfileId,
    this.make = '',
    this.model = '',
    this.manufactureYear,
    this.serialNumber = '',
    this.weightKg,
    this.capabilities = const [],
    this.flightTimePerBatteryMinutes,
    this.totalBatteries,
    this.batteryType = '',
    this.batteryUsageFee,
    this.hourlyRate,
    this.dailyRate,
    this.emergencyCalloutFee,
    this.imageUrl = '',
  });

  factory CompanyApplicantDroneModel.fromJson(
    Map<String, dynamic> json,
  ) {
    String image = '';

    final rawImage =
        json['image'] ??
        json['image_url'] ??
        json['photo'];

    if (rawImage is String) {
      image = rawImage.trim();
    } else if (rawImage is Map) {
      image = _firstNonEmpty([
        _asString(rawImage['url']),
        _asString(rawImage['original_url']),
      ]);
    }

    final rawMedia = json['media'];

    if (image.isEmpty && rawMedia is List) {
      for (final item in rawMedia) {
        if (item is Map) {
          final value = _firstNonEmpty([
            _asString(item['url']),
            _asString(item['original_url']),
          ]);

          if (value.isNotEmpty) {
            image = value;
            break;
          }
        }
      }
    }

    return CompanyApplicantDroneModel(
      id:
          _asInt(json['id']) ?? 0,
      pilotProfileId:
          _asInt(json['pilot_profile_id']),
      make:
          _asString(json['make']),
      model:
          _asString(json['model']),
      manufactureYear:
          _asInt(json['manufacture_year']),
      serialNumber:
          _asString(json['serial_number']),
      weightKg:
          _asDouble(json['weight_kg']),
      capabilities:
          _asStringList(json['capabilities']),
      flightTimePerBatteryMinutes:
          _asInt(
        json['flight_time_per_battery_minutes'],
      ),
      totalBatteries:
          _asInt(json['total_batteries']),
      batteryType:
          _asString(json['battery_type']),
      batteryUsageFee:
          _asDouble(json['battery_usage_fee']),
      hourlyRate:
          _asDouble(json['hourly_rate']),
      dailyRate:
          _asDouble(json['daily_rate']),
      emergencyCalloutFee:
          _asDouble(json['emergency_callout_fee']),
      imageUrl:
          image,
    );
  }

  String get displayName {
    final value = <String>[
      make,
      model,
    ]
        .where(
          (item) =>
              item.trim().isNotEmpty,
        )
        .join(' ');

    return value.isEmpty
        ? 'Drone #$id'
        : value;
  }
}

String _firstNonEmpty(
  List<String> values,
) {
  for (final value in values) {
    if (value.trim().isNotEmpty) {
      return value.trim();
    }
  }

  return '';
}

String _asString(dynamic value) =>
    value == null
        ? ''
        : value.toString().trim();

int? _asInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;

  return int.tryParse(
    value.toString(),
  );
}

double? _asDouble(dynamic value) {
  if (value == null) return null;
  if (value is num) {
    return value.toDouble();
  }

  return double.tryParse(
    value.toString(),
  );
}

DateTime? _asDate(dynamic value) {
  if (value == null) return null;

  final text =
      value.toString().trim();

  if (text.isEmpty) return null;

  return DateTime.tryParse(text);
}

List<String> _asStringList(
  dynamic value,
) {
  if (value == null) {
    return const [];
  }

  if (value is List) {
    return value
        .map(
          (item) =>
              item?.toString().trim() ?? '',
        )
        .where(
          (item) => item.isNotEmpty,
        )
        .toList();
  }

  return value
      .toString()
      .split(',')
      .map((item) => item.trim())
      .where((item) => item.isNotEmpty)
      .toList();
}

String _pretty(String value) {
  final clean = value.trim();

  if (clean.isEmpty) {
    return '';
  }

  return clean
      .split(
        RegExp(r'[_\s-]+'),
      )
      .where(
        (part) => part.isNotEmpty,
      )
      .map(
        (part) =>
            '${part[0].toUpperCase()}'
            '${part.substring(1).toLowerCase()}',
      )
      .join(' ');
}
