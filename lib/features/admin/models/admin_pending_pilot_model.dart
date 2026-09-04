class AdminPendingPilotModel {
  final int id;
  final String name;
  final String email;
  final DateTime? emailVerifiedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String username;
  final String status;
  final String phone;
  final AdminPilotProfileModel profile;

  const AdminPendingPilotModel({
    required this.id,
    this.name = '',
    this.email = '',
    this.emailVerifiedAt,
    this.createdAt,
    this.updatedAt,
    this.username = '',
    this.status = '',
    this.phone = '',
    this.profile = const AdminPilotProfileModel(),
  });

  factory AdminPendingPilotModel.fromJson(Map<String, dynamic> json) {
    final rawProfile = json['pilot_profile'];

    return AdminPendingPilotModel(
      id: _asInt(json['id']) ?? 0,
      name: _asString(json['name']),
      email: _asString(json['email']),
      emailVerifiedAt: _asDate(json['email_verified_at']),
      createdAt: _asDate(json['created_at']),
      updatedAt: _asDate(json['updated_at']),
      username: _asString(json['username']),
      status: _asString(json['status']),
      phone: _asString(json['phone']),
      profile: rawProfile is Map
          ? AdminPilotProfileModel.fromJson(
              Map<String, dynamic>.from(rawProfile),
            )
          : const AdminPilotProfileModel(),
    );
  }

  String get displayName {
    final value = name.trim();
    return value.isEmpty ? 'Unnamed Pilot' : value;
  }

  String get displayUsername {
    final value = username.trim();
    if (value.isEmpty) return 'No username';
    return value.startsWith('@') ? value : '@$value';
  }

  String get displayPhone {
    final value = phone.trim();
    return value.isEmpty ? 'Not provided' : value;
  }

  String get searchableText {
    return [
      name,
      username,
      email,
      phone,
      profile.nationality,
      profile.currentCountry,
      profile.currentState,
      profile.currentCity,
      profile.previousCompany,
    ].join(' ').toLowerCase();
  }
}

class AdminPilotProfileModel {
  final int? id;
  final int? userId;
  final String bio;
  final int? experienceYears;
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

  const AdminPilotProfileModel({
    this.id,
    this.userId,
    this.bio = '',
    this.experienceYears,
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
  });

  factory AdminPilotProfileModel.fromJson(Map<String, dynamic> json) {
    final languages = <String>[];
    final rawLanguages = json['languages'];

    if (rawLanguages is List) {
      for (final item in rawLanguages) {
        final value = item?.toString().trim() ?? '';
        if (value.isNotEmpty) languages.add(value);
      }
    } else if (rawLanguages != null) {
      languages.addAll(
        rawLanguages
            .toString()
            .split(',')
            .map((item) => item.trim())
            .where((item) => item.isNotEmpty),
      );
    }

    return AdminPilotProfileModel(
      id: _asInt(json['id']),
      userId: _asInt(json['user_id']),
      bio: _asString(json['bio']),
      experienceYears: _asInt(json['experience_years']),
      nationality: _asString(json['nationality']),
      dateOfBirth: _asDate(json['date_of_birth']),
      linkedinUrl: _asString(json['linkedin_url']),
      previousCompany: _asString(json['previous_company']),
      languages: languages,
      createdAt: _asDate(json['created_at']),
      updatedAt: _asDate(json['updated_at']),
      currentCountry: _asString(json['current_country']),
      currentState: _asString(json['current_state']),
      currentCity: _asString(json['current_city']),
    );
  }

  String get locationLabel {
    final parts = <String>[
      currentCity,
      currentState,
      currentCountry,
    ].map((item) => item.trim()).where((item) => item.isNotEmpty).toList();

    return parts.isEmpty ? 'Location not provided' : parts.join(', ');
  }

  String get experienceLabel {
    final years = experienceYears;
    if (years == null) return 'Experience not provided';
    if (years <= 0) return 'Less than 1 year';
    return '$years ${years == 1 ? 'year' : 'years'} experience';
  }

  String get languagesLabel {
    if (languages.isEmpty) return 'Languages not provided';
    return languages.join(', ');
  }
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
