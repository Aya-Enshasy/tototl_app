class PilotWorkRegion {
  const PilotWorkRegion({
    required this.country,
    this.state,
    this.city,
  });

  final String country;
  final String? state;
  final String? city;
}

class PilotDroneRequest {
  const PilotDroneRequest({
    this.imagePath,
    required this.make,
    required this.model,
    required this.manufactureYear,
    required this.serialNumber,
    required this.weightKg,
    required this.capabilities,
    required this.flightTimePerBatteryMinutes,
    required this.totalBatteries,
    this.batteryType,
    this.batteryUsageFee,
    required this.hourlyRate,
    required this.dailyRate,
    required this.emergencyCalloutFee,
  });

  final String? imagePath;
  final String make;
  final String model;
  final int manufactureYear;
  final String serialNumber;
  final double weightKg;
  final List<String> capabilities;
  final int flightTimePerBatteryMinutes;
  final int totalBatteries;
  final String? batteryType;
  final double? batteryUsageFee;
  final double hourlyRate;
  final double dailyRate;
  final double emergencyCalloutFee;
}

class PilotLicenseRequest {
  const PilotLicenseRequest({
    required this.licenseType,
    required this.licenseNumber,
    required this.issuingAuthority,
    required this.expiresAt,
    required this.licenseDocumentPath,
    this.permitOrInsuranceDocumentPath,
  });

  final String licenseType;
  final String licenseNumber;
  final String issuingAuthority;
  final String expiresAt;
  final String licenseDocumentPath;
  final String? permitOrInsuranceDocumentPath;
}

/// One draft/request object travels through all 4 registration screens.
/// Step 1 fills account data, Step 2 fills profile data, Step 3 adds one drone,
/// and Step 4 adds one license/certification then sends the whole object once.
class PilotRegisterRequestModel {
  const PilotRegisterRequestModel({
    required this.name,
    required this.email,
    required this.password,
    required this.passwordConfirmation,
    required this.username,
    required this.phone,
    required this.profilePhotoPath,
    required this.dateOfBirth,
    required this.nationality,
    this.linkedinUrl,
    this.experienceYears,
    this.languages = const [],
    this.currentCountry,
    this.currentState,
    this.currentCity,
    this.workRegions = const [],
    this.previousCompany,
    this.bio,
    this.drone,
    this.pilotLicense,
    this.fcmToken = '',
    this.apnToken = '',
    this.deviceType = 'android',
  });

  // Step 1 — Account
  final String name;
  final String email;
  final String password;
  final String passwordConfirmation;
  final String username;
  final String phone;
  final String profilePhotoPath;
  final String dateOfBirth;
  final String nationality;
  final String? linkedinUrl;

  // Step 2 — Experience / profile
  final int? experienceYears;
  final List<String> languages;
  final String? currentCountry;
  final String? currentState;
  final String? currentCity;
  final List<PilotWorkRegion> workRegions;
  final String? previousCompany;
  final String? bio;

  // Step 3 — At most one drone
  final PilotDroneRequest? drone;

  // Step 4 — At most one certification/license
  final PilotLicenseRequest? pilotLicense;

  // Device
  final String fcmToken;
  final String apnToken;
  final String deviceType;

  PilotRegisterRequestModel copyWith({
    String? name,
    String? email,
    String? password,
    String? passwordConfirmation,
    String? username,
    String? phone,
    String? profilePhotoPath,
    String? dateOfBirth,
    String? nationality,
    String? linkedinUrl,
    int? experienceYears,
    List<String>? languages,
    String? currentCountry,
    String? currentState,
    String? currentCity,
    List<PilotWorkRegion>? workRegions,
    String? previousCompany,
    String? bio,
    PilotDroneRequest? drone,
    PilotLicenseRequest? pilotLicense,
    String? fcmToken,
    String? apnToken,
    String? deviceType,
  }) {
    return PilotRegisterRequestModel(
      name: name ?? this.name,
      email: email ?? this.email,
      password: password ?? this.password,
      passwordConfirmation:
      passwordConfirmation ?? this.passwordConfirmation,
      username: username ?? this.username,
      phone: phone ?? this.phone,
      profilePhotoPath: profilePhotoPath ?? this.profilePhotoPath,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      nationality: nationality ?? this.nationality,
      linkedinUrl: linkedinUrl ?? this.linkedinUrl,
      experienceYears: experienceYears ?? this.experienceYears,
      languages: languages ?? this.languages,
      currentCountry: currentCountry ?? this.currentCountry,
      currentState: currentState ?? this.currentState,
      currentCity: currentCity ?? this.currentCity,
      workRegions: workRegions ?? this.workRegions,
      previousCompany: previousCompany ?? this.previousCompany,
      bio: bio ?? this.bio,
      drone: drone ?? this.drone,
      pilotLicense: pilotLicense ?? this.pilotLicense,
      fcmToken: fcmToken ?? this.fcmToken,
      apnToken: apnToken ?? this.apnToken,
      deviceType: deviceType ?? this.deviceType,
    );
  }
}
