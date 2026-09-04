import 'admin_user_model.dart';

class AdminPendingPilotModel {
  final AdminUserModel user;
  final AdminPilotProfileModel profile;

  const AdminPendingPilotModel({
    required this.user,
    this.profile = const AdminPilotProfileModel(),
  });

  factory AdminPendingPilotModel.fromJson(Map<String, dynamic> json) {
    final raw = json['pilot_profile'];

    return AdminPendingPilotModel(
      user: AdminUserModel.fromJson(json),
      profile: raw is Map
          ? AdminPilotProfileModel.fromJson(
              Map<String, dynamic>.from(raw),
            )
          : const AdminPilotProfileModel(),
    );
  }

  AdminPendingPilotModel copyWithUser(
    AdminUserModel updatedUser,
  ) {
    return AdminPendingPilotModel(
      user: updatedUser,
      profile: profile,
    );
  }

  String get searchableText => [
        user.name,
        user.username,
        user.email,
        user.phone,
        profile.nationality,
        profile.currentCountry,
        profile.currentState,
        profile.currentCity,
        profile.previousCompany,
      ].join(' ').toLowerCase();
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
    this.currentCountry = '',
    this.currentState = '',
    this.currentCity = '',
  });

  factory AdminPilotProfileModel.fromJson(Map<String, dynamic> json) {
    final langs = <String>[];
    final raw = json['languages'];

    if (raw is List) {
      for (final item in raw) {
        final value = item?.toString().trim() ?? '';
        if (value.isNotEmpty) langs.add(value);
      }
    } else if (raw != null) {
      langs.addAll(
        raw.toString()
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty),
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
      languages: langs,
      currentCountry: _asString(json['current_country']),
      currentState: _asString(json['current_state']),
      currentCity: _asString(json['current_city']),
    );
  }

  String get experienceLabel {
    if (experienceYears == null) return 'Not provided';
    if (experienceYears! <= 0) return 'Less than 1 year';
    return '${experienceYears!} ${experienceYears == 1 ? 'year' : 'years'}';
  }

  String get locationLabel {
    final parts = [
      currentCity,
      currentState,
      currentCountry,
    ].where((e) => e.trim().isNotEmpty).toList();

    return parts.isEmpty ? 'Not provided' : parts.join(', ');
  }

  String get languagesLabel =>
      languages.isEmpty ? 'Not provided' : languages.join(', ');
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
  if (text.isEmpty) return null;
  return DateTime.tryParse(text);
}
