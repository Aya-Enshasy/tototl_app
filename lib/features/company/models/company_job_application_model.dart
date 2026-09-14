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

  /// Applicants endpoints return the application plus a nested pilot profile
  /// and the drone committed to this application. Both are parsed defensively
  /// because older responses may omit one of the relations.
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
    final droneRaw = json['drone'] ?? json['committed_drone'];

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

  Map<String, dynamic> toJson() => {
    'id': id,
    'job_posting_id': jobPostingId,
    'pilot_profile_id': pilotProfileId,
    'drone_id': droneId,
    'cover_message': coverMessage,
    'status': status,
    'decided_at': decidedAt?.toIso8601String(),
    'withdrawn_at': withdrawnAt?.toIso8601String(),
    'created_at': createdAt?.toIso8601String(),
    'updated_at': updatedAt?.toIso8601String(),
    'rejection_reason': rejectionReason,
    'pilot_profile': pilotProfile?.toJson(),
    'drone': drone?.toJson(),
  };

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
      coverMessage: coverMessage ?? this.coverMessage,
      status: status ?? this.status,
      decidedAt: decidedAt ?? this.decidedAt,
      withdrawnAt: withdrawnAt ?? this.withdrawnAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      pilotProfile: pilotProfile ?? this.pilotProfile,
      drone: drone ?? this.drone,
    );
  }

  bool get isPending => status.trim().toLowerCase() == 'pending';
  bool get isAccepted => status.trim().toLowerCase() == 'accepted';
  bool get isRejected => status.trim().toLowerCase() == 'rejected';
  bool get isWithdrawn => status.trim().toLowerCase() == 'withdrawn';

  String get statusLabel => _pretty(status.isEmpty ? 'pending' : status);
}

class CompanyApplicantPilotModel {
  final int id;
  final int? userId;

  final String name;
  final String profilePhoto;
  final bool? verified;

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
  final List<CompanyPilotWorkRegionModel> workRegions;
  final List<CompanyPilotCredentialModel> licenses;

  const CompanyApplicantPilotModel({
    required this.id,
    this.userId,
    this.name = '',
    this.profilePhoto = '',
    this.verified,
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
    this.workRegions = const [],
    this.licenses = const [],
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
        json['profile_photo'] ?? json['photo'] ?? user['profile_photo'];

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
      id: _asInt(json['id']) ?? 0,
      userId: _asInt(json['user_id'] ?? user['id']),
      name: resolvedName,
      profilePhoto: photo,
      verified: _asNullableBool(
        json['verified'] ?? user['verified'],
      ),
      bio: _asString(json['bio']),
      experienceYears: _asInt(
        json['experience_years'] ?? json['years_experience'],
      ),
      nationality: _asString(json['nationality']),
      dateOfBirth: _asDate(json['date_of_birth']),
      linkedinUrl: _asString(json['linkedin_url']),
      previousCompany: _asString(json['previous_company']),
      languages: _asStringList(json['languages']),
      country: _asString(
        json['current_country'] ?? json['country'],
      ),
      state: _asString(
        json['current_state'] ?? json['state'],
      ),
      city: _asString(
        json['current_city'] ?? json['city'],
      ),
      workRegions: _asMapList(json['work_regions'])
          .map(CompanyPilotWorkRegionModel.fromJson)
          .toList(growable: false),
      licenses: _asMapList(json['licenses'])
          .map(CompanyPilotCredentialModel.fromJson)
          .toList(growable: false),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'name': name,
    'profile_photo': profilePhoto,
    'verified': verified,
    'bio': bio,
    'experience_years': experienceYears,
    'nationality': nationality,
    'date_of_birth': dateOfBirth?.toIso8601String(),
    'linkedin_url': linkedinUrl,
    'previous_company': previousCompany,
    'languages': languages,
    'current_country': country,
    'current_state': state,
    'current_city': city,
    'work_regions': workRegions.map((e) => e.toJson()).toList(),
    'licenses': licenses.map((e) => e.toJson()).toList(),
  };

  CompanyApplicantPilotModel mergeWith(
      CompanyApplicantPilotModel other,
      ) {
    return CompanyApplicantPilotModel(
      id: other.id > 0 ? other.id : id,
      userId: other.userId ?? userId,
      name: other.name.trim().isNotEmpty ? other.name : name,
      profilePhoto: other.profilePhoto.trim().isNotEmpty
          ? other.profilePhoto
          : profilePhoto,
      verified: other.verified ?? verified,
      bio: other.bio.trim().isNotEmpty ? other.bio : bio,
      experienceYears: other.experienceYears ?? experienceYears,
      nationality: other.nationality.trim().isNotEmpty
          ? other.nationality
          : nationality,
      dateOfBirth: other.dateOfBirth ?? dateOfBirth,
      linkedinUrl: other.linkedinUrl.trim().isNotEmpty
          ? other.linkedinUrl
          : linkedinUrl,
      previousCompany: other.previousCompany.trim().isNotEmpty
          ? other.previousCompany
          : previousCompany,
      languages: other.languages.isNotEmpty ? other.languages : languages,
      country: other.country.trim().isNotEmpty ? other.country : country,
      state: other.state.trim().isNotEmpty ? other.state : state,
      city: other.city.trim().isNotEmpty ? other.city : city,
      workRegions:
      other.workRegions.isNotEmpty ? other.workRegions : workRegions,
      licenses: other.licenses.isNotEmpty ? other.licenses : licenses,
    );
  }

  String get displayName {
    final clean = name.trim();
    return clean.isNotEmpty ? clean : 'Pilot #$id';
  }

  String get location {
    final parts = <String>[city, state, country]
        .where((item) => item.trim().isNotEmpty)
        .toList();
    return parts.join(', ');
  }

  String get experienceLabel {
    if (experienceYears == null) return '';
    return '$experienceYears year${experienceYears == 1 ? '' : 's'} experience';
  }
}

class CompanyPilotWorkRegionModel {
  final int id;
  final int? pilotProfileId;
  final String country;
  final String state;
  final String city;

  const CompanyPilotWorkRegionModel({
    this.id = 0,
    this.pilotProfileId,
    this.country = '',
    this.state = '',
    this.city = '',
  });

  factory CompanyPilotWorkRegionModel.fromJson(Map<String, dynamic> json) {
    return CompanyPilotWorkRegionModel(
      id: _asInt(json['id']) ?? 0,
      pilotProfileId: _asInt(json['pilot_profile_id']),
      country: _asString(json['country']),
      state: _asString(json['state']),
      city: _asString(json['city']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'pilot_profile_id': pilotProfileId,
    'country': country,
    'state': state,
    'city': city,
  };

  String get label {
    final parts = <String>[city, state, country]
        .where((item) => item.trim().isNotEmpty)
        .toList();
    return parts.join(', ');
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

  /// Backend field: flight_time (minutes per battery).
  final int? flightTimePerBatteryMinutes;
  final int? chargingTimeMinutes;
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
    this.chargingTimeMinutes,
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

    final rawImage = json['image'] ?? json['image_url'] ?? json['photo'];
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
      id: _asInt(json['id']) ?? 0,
      pilotProfileId: _asInt(json['pilot_profile_id']),
      make: _asString(json['make']),
      model: _asString(json['model']),
      manufactureYear: _asInt(json['manufacture_year']),
      serialNumber: _asString(json['serial_number']),
      weightKg: _asDouble(json['weight_kg']),
      capabilities: _asStringList(json['capabilities']),
      flightTimePerBatteryMinutes: _asInt(
        json['flight_time_per_battery_minutes'] ?? json['flight_time'],
      ),
      chargingTimeMinutes: _asInt(json['charging_time']),
      totalBatteries: _asInt(json['total_batteries']),
      batteryType: _asString(json['battery_type']),
      batteryUsageFee: _asDouble(json['battery_usage_fee']),
      hourlyRate: _asDouble(json['hourly_rate']),
      dailyRate: _asDouble(json['daily_rate']),
      emergencyCalloutFee: _asDouble(json['emergency_callout_fee']),
      imageUrl: image,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'pilot_profile_id': pilotProfileId,
    'make': make,
    'model': model,
    'manufacture_year': manufactureYear,
    'serial_number': serialNumber,
    'weight_kg': weightKg,
    'capabilities': capabilities,
    'flight_time': flightTimePerBatteryMinutes,
    'charging_time': chargingTimeMinutes,
    'total_batteries': totalBatteries,
    'battery_type': batteryType,
    'battery_usage_fee': batteryUsageFee,
    'hourly_rate': hourlyRate,
    'daily_rate': dailyRate,
    'emergency_callout_fee': emergencyCalloutFee,
    if (imageUrl.isNotEmpty)
      'media': [
        {
          'collection_name': 'image',
          'url': imageUrl,
        }
      ],
  };

  String get displayName {
    final value = <String>[make, model]
        .where((item) => item.trim().isNotEmpty)
        .join(' ');
    return value.isEmpty ? 'Drone #$id' : value;
  }
}

class CompanyPilotCredentialModel {
  final int id;
  final int pilotProfileId;
  final String licenseType;
  final String licenseNumber;
  final String issuingAuthority;
  final DateTime? expiresAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<CompanyPilotMediaModel> media;

  const CompanyPilotCredentialModel({
    required this.id,
    required this.pilotProfileId,
    this.licenseType = '',
    this.licenseNumber = '',
    this.issuingAuthority = '',
    this.expiresAt,
    this.createdAt,
    this.updatedAt,
    this.media = const [],
  });

  factory CompanyPilotCredentialModel.fromJson(
      Map<String, dynamic> json,
      ) {
    return CompanyPilotCredentialModel(
      id: _asInt(json['id']) ?? 0,
      pilotProfileId: _asInt(json['pilot_profile_id']) ?? 0,
      licenseType: _asString(json['license_type']),
      licenseNumber: _asString(json['license_number']),
      issuingAuthority: _asString(json['issuing_authority']),
      expiresAt: _asDate(json['expires_at']),
      createdAt: _asDate(json['created_at']),
      updatedAt: _asDate(json['updated_at']),
      media: _asMapList(json['media'])
          .map(CompanyPilotMediaModel.fromJson)
          .toList(growable: false),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'pilot_profile_id': pilotProfileId,
    'license_type': licenseType,
    'license_number': licenseNumber,
    'issuing_authority': issuingAuthority,
    'expires_at': expiresAt?.toIso8601String(),
    'created_at': createdAt?.toIso8601String(),
    'updated_at': updatedAt?.toIso8601String(),
    'media': media.map((e) => e.toJson()).toList(),
  };

  bool get isExpired {
    final expiry = expiresAt;
    if (expiry == null) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(expiry.year, expiry.month, expiry.day);
    return date.isBefore(today);
  }

  List<CompanyPilotMediaModel> get licenseDocuments => media
      .where((item) => item.collectionName == 'license_document')
      .toList(growable: false);

  List<CompanyPilotMediaModel> get permitOrInsuranceDocuments => media
      .where(
        (item) => item.collectionName == 'permit_or_insurance_document',
  )
      .toList(growable: false);
}

class CompanyPilotMediaModel {
  final int id;
  final String collectionName;
  final String fileName;
  final String mimeType;
  final int? size;
  final String url;
  final String downloadUrl;
  final DateTime? createdAt;

  const CompanyPilotMediaModel({
    required this.id,
    this.collectionName = '',
    this.fileName = '',
    this.mimeType = '',
    this.size,
    this.url = '',
    this.downloadUrl = '',
    this.createdAt,
  });

  factory CompanyPilotMediaModel.fromJson(Map<String, dynamic> json) {
    return CompanyPilotMediaModel(
      id: _asInt(json['id']) ?? 0,
      collectionName: _asString(json['collection_name']),
      fileName: _asString(json['file_name']),
      mimeType: _asString(json['mime_type']),
      size: _asInt(json['size']),
      url: _asString(json['url']),
      downloadUrl: _asString(json['download_url']),
      createdAt: _asDate(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'collection_name': collectionName,
    'file_name': fileName,
    'mime_type': mimeType,
    'size': size,
    'url': url,
    'download_url': downloadUrl,
    'created_at': createdAt?.toIso8601String(),
  };

  String get bestDownloadUrl =>
      downloadUrl.trim().isNotEmpty ? downloadUrl.trim() : url.trim();

  String get displayLabel {
    switch (collectionName.trim().toLowerCase()) {
      case 'license_document':
        return 'License document';
      case 'permit_or_insurance_document':
        return 'Permit / insurance';
      default:
        return 'Document';
    }
  }

  bool get isPdf => mimeType.toLowerCase() == 'application/pdf' ||
      fileName.toLowerCase().endsWith('.pdf');
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
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}

double? _asDouble(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}

bool? _asNullableBool(dynamic value) {
  if (value == null) return null;
  if (value is bool) return value;
  if (value is num) return value != 0;
  final text = value.toString().trim().toLowerCase();
  if (text == 'true' || text == '1' || text == 'yes') return true;
  if (text == 'false' || text == '0' || text == 'no') return false;
  return null;
}

DateTime? _asDate(dynamic value) {
  if (value == null) return null;
  final text = value.toString().trim();
  if (text.isEmpty) return null;
  return DateTime.tryParse(text);
}

List<String> _asStringList(dynamic value) {
  if (value == null) return const [];
  if (value is List) {
    return value
        .map((item) => item?.toString().trim() ?? '')
        .where((item) => item.isNotEmpty)
        .toList();
  }
  return value
      .toString()
      .split(',')
      .map((item) => item.trim())
      .where((item) => item.isNotEmpty)
      .toList();
}

List<Map<String, dynamic>> _asMapList(dynamic value) {
  if (value is! List) return const [];
  return value
      .whereType<Map>()
      .map((item) => Map<String, dynamic>.from(item))
      .toList(growable: false);
}

String _pretty(String value) {
  final clean = value.trim();
  if (clean.isEmpty) return '';
  return clean
      .split(RegExp(r'[_\s-]+'))
      .where((part) => part.isNotEmpty)
      .map(
        (part) =>
    '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}',
  )
      .join(' ');
}
