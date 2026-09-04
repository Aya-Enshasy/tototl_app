import 'admin_user_model.dart';

class AdminPendingCompanyModel {
  final AdminUserModel user;
  final AdminCompanyProfileModel profile;

  const AdminPendingCompanyModel({
    required this.user,
    this.profile = const AdminCompanyProfileModel(),
  });

  factory AdminPendingCompanyModel.fromJson(Map<String, dynamic> json) {
    final raw = json['company_profile'];

    return AdminPendingCompanyModel(
      user: AdminUserModel.fromJson(json),
      profile: raw is Map
          ? AdminCompanyProfileModel.fromJson(
              Map<String, dynamic>.from(raw),
            )
          : const AdminCompanyProfileModel(),
    );
  }

  String get displayCompanyName {
    final value = profile.companyName.trim();
    return value.isEmpty ? user.displayName : value;
  }

  String get searchableText => [
        displayCompanyName,
        user.name,
        user.username,
        user.email,
        user.phone,
        profile.industryType,
        profile.country,
        profile.state,
        profile.city,
        profile.address,
        profile.website,
      ].join(' ').toLowerCase();
}

class AdminCompanyProfileModel {
  final int? id;
  final int? userId;
  final String companyName;
  final String industryType;
  final String description;
  final String country;
  final String state;
  final String city;
  final String address;
  final String website;

  const AdminCompanyProfileModel({
    this.id,
    this.userId,
    this.companyName = '',
    this.industryType = '',
    this.description = '',
    this.country = '',
    this.state = '',
    this.city = '',
    this.address = '',
    this.website = '',
  });

  factory AdminCompanyProfileModel.fromJson(Map<String, dynamic> json) {
    return AdminCompanyProfileModel(
      id: _asInt(json['id']),
      userId: _asInt(json['user_id']),
      companyName: _asString(json['company_name']),
      industryType: _asString(json['industry_type']),
      description: _asString(json['description']),
      country: _asString(json['country']),
      state: _asString(json['state']),
      city: _asString(json['city']),
      address: _asString(json['address']),
      website: _asString(json['website']),
    );
  }

  String get locationLabel {
    final parts = [city, state, country]
        .where((e) => e.trim().isNotEmpty)
        .toList();

    return parts.isEmpty ? 'Not provided' : parts.join(', ');
  }
}

String _asString(dynamic value) =>
    value == null ? '' : value.toString().trim();

int? _asInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  return int.tryParse(value.toString());
}
