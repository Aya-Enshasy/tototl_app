class PilotProfileViewData {
  final PilotAccountModel account;
  final PilotProfileModel profile;

  const PilotProfileViewData({
    required this.account,
    required this.profile,
  });

  PilotProfileViewData copyWith({
    PilotAccountModel? account,
    PilotProfileModel? profile,
  }) {
    return PilotProfileViewData(
      account:
      account ?? this.account,
      profile:
      profile ?? this.profile,
    );
  }
}

// ============================================================
// USER / ACCOUNT
// ============================================================

class PilotAccountModel {
  final int? id;
  final String name;
  final String email;
  final String username;
  final String status;
  final String phone;

  const PilotAccountModel({
    this.id,
    this.name = '',
    this.email = '',
    this.username = '',
    this.status = '',
    this.phone = '',
  });

  factory PilotAccountModel.fromJson(
      Map<String, dynamic> json,
      ) {
    return PilotAccountModel(
      id: _asInt(
        json['id'],
      ),
      name: _asString(
        json['name'],
      ),
      email: _asString(
        json['email'],
      ),
      username: _asString(
        json['username'],
      ),
      status: _asString(
        json['status'],
      ),
      phone: _asString(
        json['phone'],
      ),
    );
  }

  String get displayName {
    final value = name.trim();

    if (value.isEmpty) {
      return 'Pilot';
    }

    return value;
  }

  String get displayUsername {
    final value =
    username.trim();

    if (value.isEmpty) {
      return '';
    }

    if (value.startsWith('@')) {
      return value;
    }

    return '@$value';
  }
}

// ============================================================
// PILOT PROFILE
// ============================================================

class PilotProfileModel {
  final int? id;
  final int? userId;

  final String bio;

  final int experienceYears;

  final String nationality;

  final DateTime? dateOfBirth;

  final String linkedinUrl;

  final String previousCompany;

  final List<String> languages;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  final String currentCountry;
  final String currentState;
  final String currentCity;

  final List<PilotWorkRegionModel>
  workRegions;

  const PilotProfileModel({
    this.id,
    this.userId,
    this.bio = '',
    this.experienceYears = 0,
    this.nationality = '',
    this.dateOfBirth,
    this.linkedinUrl = '',
    this.previousCompany = '',
    this.languages = const [],
    this.createdAt,
    this.updatedAt,
    this.currentCountry = '',
    this.currentState = '',
    this.currentCity = '',
    this.workRegions = const [],
  });

  factory PilotProfileModel.fromJson(
      Map<String, dynamic> json,
      ) {
    final rawLanguages =
    json['languages'];

    final rawWorkRegions =
    json['work_regions'];

    final languages =
    <String>[];

    if (rawLanguages is List) {
      for (final item
      in rawLanguages) {
        final value =
            item?.toString().trim() ??
                '';

        if (value.isNotEmpty) {
          languages.add(value);
        }
      }
    }

    final workRegions =
    <PilotWorkRegionModel>[];

    if (rawWorkRegions is List) {
      for (final item
      in rawWorkRegions) {
        if (item is Map) {
          workRegions.add(
            PilotWorkRegionModel.fromJson(
              Map<String, dynamic>.from(
                item,
              ),
            ),
          );
        }
      }
    }

    return PilotProfileModel(
      id: _asInt(
        json['id'],
      ),

      userId: _asInt(
        json['user_id'],
      ),

      bio: _asString(
        json['bio'],
      ),

      experienceYears:
      _asInt(
        json['experience_years'],
      ) ??
          0,

      nationality:
      _asString(
        json['nationality'],
      ),

      dateOfBirth:
      _asDate(
        json['date_of_birth'],
      ),

      linkedinUrl:
      _asString(
        json['linkedin_url'],
      ),

      previousCompany:
      _asString(
        json['previous_company'],
      ),

      languages: languages,

      createdAt:
      _asDate(
        json['created_at'],
      ),

      updatedAt:
      _asDate(
        json['updated_at'],
      ),

      currentCountry:
      _asString(
        json['current_country'],
      ),

      currentState:
      _asString(
        json['current_state'],
      ),

      currentCity:
      _asString(
        json['current_city'],
      ),

      workRegions:
      workRegions,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'bio': bio,
      'experience_years':
      experienceYears,
      'nationality':
      nationality,
      'date_of_birth':
      dateOfBirth
          ?.toIso8601String(),
      'linkedin_url':
      linkedinUrl,
      'previous_company':
      previousCompany,
      'languages':
      languages,
      'created_at':
      createdAt
          ?.toIso8601String(),
      'updated_at':
      updatedAt
          ?.toIso8601String(),
      'current_country':
      currentCountry,
      'current_state':
      currentState,
      'current_city':
      currentCity,
      'work_regions':
      workRegions
          .map(
            (item) =>
            item.toJson(),
      )
          .toList(),
    };
  }

  // ============================================================
  // DISPLAY LOCATION
  // ============================================================

  String get currentLocationLabel {
    final parts = <String>[
      currentCity,
      currentState,
      currentCountry,
    ].where(
          (item) =>
      item.trim().isNotEmpty,
    ).toList();

    if (parts.isEmpty) {
      return 'Not specified';
    }

    return parts.join(', ');
  }
}

// ============================================================
// WORK REGION
// ============================================================

class PilotWorkRegionModel {
  final int? id;

  final int? pilotProfileId;

  final String country;

  final String state;

  final String city;

  final DateTime? createdAt;

  final DateTime? updatedAt;

  const PilotWorkRegionModel({
    this.id,
    this.pilotProfileId,
    this.country = '',
    this.state = '',
    this.city = '',
    this.createdAt,
    this.updatedAt,
  });

  factory PilotWorkRegionModel.fromJson(
      Map<String, dynamic> json,
      ) {
    return PilotWorkRegionModel(
      id: _asInt(
        json['id'],
      ),

      pilotProfileId:
      _asInt(
        json['pilot_profile_id'],
      ),

      country:
      _asString(
        json['country'],
      ),

      state:
      _asString(
        json['state'],
      ),

      city:
      _asString(
        json['city'],
      ),

      createdAt:
      _asDate(
        json['created_at'],
      ),

      updatedAt:
      _asDate(
        json['updated_at'],
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'pilot_profile_id':
      pilotProfileId,
      'country':
      country,
      'state':
      state.isEmpty
          ? null
          : state,
      'city':
      city.isEmpty
          ? null
          : city,
      'created_at':
      createdAt
          ?.toIso8601String(),
      'updated_at':
      updatedAt
          ?.toIso8601String(),
    };
  }

  String get displayLabel {
    final parts = <String>[
      city,
      state,
      country,
    ].where(
          (item) =>
      item.trim().isNotEmpty,
    ).toList();

    if (parts.isEmpty) {
      return 'Region';
    }

    return parts.join(', ');
  }
}

// ============================================================
// HELPERS
// ============================================================

String _asString(
    dynamic value,
    ) {
  if (value == null) {
    return '';
  }

  return value
      .toString()
      .trim();
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
  value.toString().trim();

  if (text.isEmpty) {
    return null;
  }

  return DateTime.tryParse(
    text,
  );
}