class CompanyWorkRegion {
  const CompanyWorkRegion({
    required this.country,
    this.state,
    this.city,
  });

  final String country;
  final String? state;
  final String? city;
}

class CompanyRegisterRequestModel {
  const CompanyRegisterRequestModel({
    required this.name,
    required this.username,
    required this.email,
    required this.password,
    required this.passwordConfirmation,
    required this.companyName,
    required this.phone,
    required this.industryType,
    this.logoPath,
    this.description,
    this.country,
    this.state,
    this.city,
    this.address,
    this.website,
    this.workRegions = const [],
    this.fcmToken = '',
    this.apnToken = '',
    this.deviceType = 'android',
  });

  // Account
  final String name;
  final String username;
  final String email;
  final String password;
  final String passwordConfirmation;
  final String phone;

  // Company
  final String companyName;
  final String industryType;
  final String? logoPath;
  final String? description;
  final String? country;
  final String? state;
  final String? city;
  final String? address;
  final String? website;
  final List<CompanyWorkRegion> workRegions;

  // Device
  final String fcmToken;
  final String apnToken;
  final String deviceType;

  CompanyRegisterRequestModel copyWith({
    String? name,
    String? username,
    String? email,
    String? password,
    String? passwordConfirmation,
    String? companyName,
    String? phone,
    String? industryType,
    String? logoPath,
    String? description,
    String? country,
    String? state,
    String? city,
    String? address,
    String? website,
    List<CompanyWorkRegion>? workRegions,
    String? fcmToken,
    String? apnToken,
    String? deviceType,
  }) {
    return CompanyRegisterRequestModel(
      name: name ?? this.name,
      username: username ?? this.username,
      email: email ?? this.email,
      password: password ?? this.password,
      passwordConfirmation:
      passwordConfirmation ?? this.passwordConfirmation,
      companyName: companyName ?? this.companyName,
      phone: phone ?? this.phone,
      industryType: industryType ?? this.industryType,
      logoPath: logoPath ?? this.logoPath,
      description: description ?? this.description,
      country: country ?? this.country,
      state: state ?? this.state,
      city: city ?? this.city,
      address: address ?? this.address,
      website: website ?? this.website,
      workRegions: workRegions ?? this.workRegions,
      fcmToken: fcmToken ?? this.fcmToken,
      apnToken: apnToken ?? this.apnToken,
      deviceType: deviceType ?? this.deviceType,
    );
  }
}
