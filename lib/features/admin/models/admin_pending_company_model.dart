class AdminPendingCompanyModel {
  final int id;
  final String name;
  final String email;
  final DateTime? emailVerifiedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String username;
  final String status;
  final String phone;
  final AdminCompanyProfileModel profile;

  const AdminPendingCompanyModel({
    required this.id,
    this.name = '',
    this.email = '',
    this.emailVerifiedAt,
    this.createdAt,
    this.updatedAt,
    this.username = '',
    this.status = '',
    this.phone = '',
    this.profile = const AdminCompanyProfileModel(),
  });

  factory AdminPendingCompanyModel.fromJson(Map<String, dynamic> json) {
    final rawProfile = json['company_profile'];

    return AdminPendingCompanyModel(
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
          ? AdminCompanyProfileModel.fromJson(
              Map<String, dynamic>.from(rawProfile),
            )
          : const AdminCompanyProfileModel(),
    );
  }

  String get displayCompanyName {
    final company = profile.companyName.trim();
    if (company.isNotEmpty) return company;

    final account = name.trim();
    return account.isEmpty ? 'Unnamed Company' : account;
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
      profile.companyName,
      profile.industryType,
      profile.country,
      profile.state,
      profile.city,
      profile.address,
      profile.website,
    ].join(' ').toLowerCase();
  }
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
  final DateTime? createdAt;
  final DateTime? updatedAt;

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
    this.createdAt,
    this.updatedAt,
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
      createdAt: _asDate(json['created_at']),
      updatedAt: _asDate(json['updated_at']),
    );
  }

  String get locationLabel {
    final values = <String>[
      city,
      state,
      country,
    ].map((item) => item.trim()).where((item) => item.isNotEmpty).toList();

    return values.isEmpty ? 'Location not provided' : values.join(', ');
  }

  String get industryLabel {
    final value = industryType.trim();
    return value.isEmpty ? 'Industry not provided' : value;
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
