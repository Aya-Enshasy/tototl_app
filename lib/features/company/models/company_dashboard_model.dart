class CompanyDashboardModel {
  final CompanyDashboardJobsByStatus jobsByStatus;
  final int incomingApplicationsCount;
  final List<CompanyDashboardApplicant> recentApplicants;

  final int applicationsCount;
  final Map<String, int> contractsByStatus;
  final int contractsAwaitingPilotActionCount;
  final int submissionsAwaitingReviewCount;
  final List<Map<String, dynamic>> submissionsAwaitingReview;
  final CompanyDashboardPaymentSummary paymentSummary;
  final Map<String, int> paymentsByStatus;
  final CompanyDashboardSubscription? currentSubscription;

  final List<CompanyDashboardJobPosting> jobPostings;
  final List<Map<String, dynamic>> payments;
  final List<CompanyDashboardComplianceRecord> complianceRecords;
  final List<Map<String, dynamic>> contractsAwaitingFunding;

  const CompanyDashboardModel({
    this.jobsByStatus = const CompanyDashboardJobsByStatus(),
    this.incomingApplicationsCount = 0,
    this.recentApplicants = const [],
    this.applicationsCount = 0,
    this.contractsByStatus = const {},
    this.contractsAwaitingPilotActionCount = 0,
    this.submissionsAwaitingReviewCount = 0,
    this.submissionsAwaitingReview = const [],
    this.paymentSummary = const CompanyDashboardPaymentSummary(),
    this.paymentsByStatus = const {},
    this.currentSubscription,
    this.jobPostings = const [],
    this.payments = const [],
    this.complianceRecords = const [],
    this.contractsAwaitingFunding = const [],
  });

  factory CompanyDashboardModel.fromJson(Map<String, dynamic> json) {
    final rawStatus = json['jobs_by_status'];
    final rawApplicants = json['recent_applicants'];
    final rawSubscription = json['current_subscription'];

    return CompanyDashboardModel(
      jobsByStatus: rawStatus is Map
          ? CompanyDashboardJobsByStatus.fromJson(
              Map<String, dynamic>.from(rawStatus),
            )
          : const CompanyDashboardJobsByStatus(),
      incomingApplicationsCount:
          _asInt(json['incoming_applications_count']) ?? 0,
      recentApplicants: rawApplicants is List
          ? rawApplicants
              .whereType<Map>()
              .map(
                (item) => CompanyDashboardApplicant.fromJson(
                  Map<String, dynamic>.from(item),
                ),
              )
              .toList(growable: false)
          : const [],
      applicationsCount: _asInt(json['applications_count']) ?? 0,
      contractsByStatus: _asIntMap(json['contracts_by_status']),
      contractsAwaitingPilotActionCount:
          _asInt(json['contracts_awaiting_pilot_action_count']) ?? 0,
      submissionsAwaitingReviewCount:
          _asInt(json['submissions_awaiting_review_count']) ?? 0,
      submissionsAwaitingReview:
          _asMapList(json['submissions_awaiting_review']),
      paymentSummary: CompanyDashboardPaymentSummary.fromRaw(
        json['payment_summary'],
      ),
      paymentsByStatus: _asIntMap(json['payments_by_status']),
      currentSubscription: rawSubscription is Map
          ? CompanyDashboardSubscription.fromJson(
              Map<String, dynamic>.from(rawSubscription),
            )
          : null,
      jobPostings: _asDashboardJobs(json['job_postings']),
      payments: _asMapList(json['payments']),
      complianceRecords:
          _asComplianceRecords(json['compliance_records']),
      contractsAwaitingFunding:
          _asMapList(json['contracts_awaiting_funding']),
    );
  }

  int get totalContracts =>
      contractsByStatus.values.fold<int>(0, (sum, value) => sum + value);

  int get activeContracts {
    const activeKeys = {
      'accepted',
      'active',
      'in_progress',
      'submitted',
    };

    var total = 0;
    for (final entry in contractsByStatus.entries) {
      if (activeKeys.contains(entry.key.trim().toLowerCase())) {
        total += entry.value;
      }
    }
    return total;
  }
}

class CompanyDashboardJobsByStatus {
  final int draft;
  final int published;
  final int closed;
  final int cancelled;

  const CompanyDashboardJobsByStatus({
    this.draft = 0,
    this.published = 0,
    this.closed = 0,
    this.cancelled = 0,
  });

  factory CompanyDashboardJobsByStatus.fromJson(Map<String, dynamic> json) {
    return CompanyDashboardJobsByStatus(
      draft: _asInt(json['draft']) ?? 0,
      published: _asInt(json['published']) ?? 0,
      closed: _asInt(json['closed']) ?? 0,
      cancelled: _asInt(json['cancelled']) ?? 0,
    );
  }
}

class CompanyDashboardPaymentSummary {
  final double fundedTotal;
  final double releasedTotal;
  final double pendingReleaseTotal;

  const CompanyDashboardPaymentSummary({
    this.fundedTotal = 0,
    this.releasedTotal = 0,
    this.pendingReleaseTotal = 0,
  });

  factory CompanyDashboardPaymentSummary.fromRaw(dynamic raw) {
    if (raw is! Map) {
      return const CompanyDashboardPaymentSummary();
    }

    final map = Map<String, dynamic>.from(raw);
    return CompanyDashboardPaymentSummary(
      fundedTotal: _asDouble(map['funded_total']) ?? 0,
      releasedTotal: _asDouble(map['released_total']) ?? 0,
      pendingReleaseTotal: _asDouble(map['pending_release_total']) ?? 0,
    );
  }
}

class CompanyDashboardSubscription {
  final int id;
  final int userId;
  final int subscriptionPlanId;
  final String status;
  final DateTime? startDate;
  final DateTime? expirationDate;
  final DateTime? renewalDate;
  final DateTime? cancelledAt;

  const CompanyDashboardSubscription({
    required this.id,
    this.userId = 0,
    this.subscriptionPlanId = 0,
    this.status = '',
    this.startDate,
    this.expirationDate,
    this.renewalDate,
    this.cancelledAt,
  });

  factory CompanyDashboardSubscription.fromJson(
    Map<String, dynamic> json,
  ) {
    return CompanyDashboardSubscription(
      id: _asInt(json['id']) ?? 0,
      userId: _asInt(json['user_id']) ?? 0,
      subscriptionPlanId:
          _asInt(json['subscription_plan_id']) ?? 0,
      status: _asString(json['status']).toLowerCase(),
      startDate: _asDate(json['start_date']),
      expirationDate: _asDate(json['expiration_date']),
      renewalDate: _asDate(json['renewal_date']),
      cancelledAt: _asDate(json['cancelled_at']),
    );
  }

  bool get isActive => status == 'active';
}

class CompanyDashboardApplicant {
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
  final CompanyDashboardPilotProfile? pilotProfile;
  final CompanyDashboardJobPosting? jobPosting;
  final CompanyDashboardDrone? drone;

  const CompanyDashboardApplicant({
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
    this.jobPosting,
    this.drone,
  });

  factory CompanyDashboardApplicant.fromJson(Map<String, dynamic> json) {
    final rawPilot = json['pilot_profile'];
    final rawJob = json['job_posting'];
    final rawDrone = json['drone'];

    return CompanyDashboardApplicant(
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
      pilotProfile: rawPilot is Map
          ? CompanyDashboardPilotProfile.fromJson(
              Map<String, dynamic>.from(rawPilot),
            )
          : null,
      jobPosting: rawJob is Map
          ? CompanyDashboardJobPosting.fromJson(
              Map<String, dynamic>.from(rawJob),
            )
          : null,
      drone: rawDrone is Map
          ? CompanyDashboardDrone.fromJson(
              Map<String, dynamic>.from(rawDrone),
            )
          : null,
    );
  }
}

class CompanyDashboardPilotProfile {
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

  const CompanyDashboardPilotProfile({
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

  factory CompanyDashboardPilotProfile.fromJson(Map<String, dynamic> json) {
    return CompanyDashboardPilotProfile(
      id: _asInt(json['id']) ?? 0,
      userId: _asInt(json['user_id']),
      name: _asString(json['name']),
      profilePhoto: _asString(json['profile_photo']),
      bio: _asString(json['bio']),
      experienceYears: _asInt(json['experience_years']),
      nationality: _asString(json['nationality']),
      dateOfBirth: _asDate(json['date_of_birth']),
      linkedinUrl: _asString(json['linkedin_url']),
      previousCompany: _asString(json['previous_company']),
      languages: _asStringList(json['languages']),
      country: _asString(json['current_country'] ?? json['country']),
      state: _asString(json['current_state'] ?? json['state']),
      city: _asString(json['current_city'] ?? json['city']),
    );
  }

  String get displayName => name.trim().isEmpty ? 'Pilot #$id' : name.trim();

  String get location {
    final result = <String>[];
    final seen = <String>{};

    for (final value in [city, state, country]) {
      final clean = value.trim();
      if (clean.isEmpty) continue;
      if (seen.add(clean.toLowerCase())) result.add(clean);
    }

    return result.join(', ');
  }
}

class CompanyDashboardJobPosting {
  final int id;
  final String title;
  final String description;
  final String country;
  final String state;
  final String city;
  final String status;
  final String serviceCategory;

  const CompanyDashboardJobPosting({
    required this.id,
    this.title = '',
    this.description = '',
    this.country = '',
    this.state = '',
    this.city = '',
    this.status = '',
    this.serviceCategory = '',
  });

  factory CompanyDashboardJobPosting.fromJson(Map<String, dynamic> json) {
    return CompanyDashboardJobPosting(
      id: _asInt(json['id']) ?? 0,
      title: _asString(json['title']),
      description: _asString(json['description']),
      country: _asString(json['country']),
      state: _asString(json['state']),
      city: _asString(json['city']),
      status: _asString(json['status']),
      serviceCategory: _asString(json['service_category']),
    );
  }
}

class CompanyDashboardDrone {
  final int id;
  final int? pilotProfileId;
  final String make;
  final String model;
  final int? manufactureYear;
  final String serialNumber;
  final double? weightKg;
  final List<String> capabilities;
  final int? flightTime;
  final int? totalBatteries;
  final String batteryType;
  final double? batteryUsageFee;
  final double? hourlyRate;
  final double? dailyRate;
  final double? emergencyCalloutFee;
  final int? chargingTime;

  const CompanyDashboardDrone({
    required this.id,
    this.pilotProfileId,
    this.make = '',
    this.model = '',
    this.manufactureYear,
    this.serialNumber = '',
    this.weightKg,
    this.capabilities = const [],
    this.flightTime,
    this.totalBatteries,
    this.batteryType = '',
    this.batteryUsageFee,
    this.hourlyRate,
    this.dailyRate,
    this.emergencyCalloutFee,
    this.chargingTime,
  });

  factory CompanyDashboardDrone.fromJson(Map<String, dynamic> json) {
    return CompanyDashboardDrone(
      id: _asInt(json['id']) ?? 0,
      pilotProfileId: _asInt(json['pilot_profile_id']),
      make: _asString(json['make']),
      model: _asString(json['model']),
      manufactureYear: _asInt(json['manufacture_year']),
      serialNumber: _asString(json['serial_number']),
      weightKg: _asDouble(json['weight_kg']),
      capabilities: _asStringList(json['capabilities']),
      flightTime: _asInt(json['flight_time']),
      totalBatteries: _asInt(json['total_batteries']),
      batteryType: _asString(json['battery_type']),
      batteryUsageFee: _asDouble(json['battery_usage_fee']),
      hourlyRate: _asDouble(json['hourly_rate']),
      dailyRate: _asDouble(json['daily_rate']),
      emergencyCalloutFee: _asDouble(json['emergency_callout_fee']),
      chargingTime: _asInt(json['charging_time']),
    );
  }

  String get displayName {
    final value = [make, model]
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .join(' ');
    return value.isEmpty ? 'Drone #$id' : value;
  }
}

class CompanyDashboardComplianceRecord {
  final int id;
  final String licenseType;
  final String licenseNumber;
  final String issuingAuthority;
  final DateTime? expiresAt;
  final int pilotId;
  final String pilotName;
  final bool pilotVerified;
  final String documentUrl;

  const CompanyDashboardComplianceRecord({
    required this.id,
    this.licenseType = '',
    this.licenseNumber = '',
    this.issuingAuthority = '',
    this.expiresAt,
    this.pilotId = 0,
    this.pilotName = '',
    this.pilotVerified = false,
    this.documentUrl = '',
  });

  factory CompanyDashboardComplianceRecord.fromJson(
    Map<String, dynamic> json,
  ) {
    final rawPilot = json['pilot'];
    final pilot = rawPilot is Map
        ? Map<String, dynamic>.from(rawPilot)
        : const <String, dynamic>{};

    return CompanyDashboardComplianceRecord(
      id: _asInt(json['id']) ?? 0,
      licenseType: _asString(json['license_type']),
      licenseNumber: _asString(json['license_number']),
      issuingAuthority: _asString(json['issuing_authority']),
      expiresAt: _asDate(json['expires_at']),
      pilotId: _asInt(pilot['id']) ?? 0,
      pilotName: _asString(pilot['name']),
      pilotVerified: _asBool(pilot['verified']),
      documentUrl: _asString(json['document_url']),
    );
  }
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

DateTime? _asDate(dynamic value) {
  final text = _asString(value);
  return text.isEmpty ? null : DateTime.tryParse(text);
}

bool _asBool(dynamic value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  final text = _asString(value).toLowerCase();
  return text == '1' || text == 'true' || text == 'yes';
}

List<String> _asStringList(dynamic value) {
  if (value is! List) return const [];
  return value
      .map(_asString)
      .where((item) => item.isNotEmpty)
      .toList(growable: false);
}

Map<String, int> _asIntMap(dynamic value) {
  final result = <String, int>{};

  if (value is Map) {
    for (final entry in value.entries) {
      final key = entry.key.toString().trim();
      if (key.isEmpty) continue;
      result[key] = _asInt(entry.value) ?? 0;
    }
  } else if (value is List) {
    for (final item in value) {
      if (item is! Map) continue;
      final map = Map<String, dynamic>.from(item);
      final key = _asString(map['status']).toLowerCase();
      if (key.isEmpty) continue;
      result[key] = _asInt(map['count']) ?? 0;
    }
  }

  return Map<String, int>.unmodifiable(result);
}

List<Map<String, dynamic>> _asMapList(dynamic value) {
  if (value is! List) return const [];

  return value
      .whereType<Map>()
      .map((item) => Map<String, dynamic>.from(item))
      .toList(growable: false);
}

List<CompanyDashboardJobPosting> _asDashboardJobs(dynamic value) {
  if (value is! List) return const [];

  return value
      .whereType<Map>()
      .map(
        (item) => CompanyDashboardJobPosting.fromJson(
          Map<String, dynamic>.from(item),
        ),
      )
      .toList(growable: false);
}

List<CompanyDashboardComplianceRecord> _asComplianceRecords(dynamic value) {
  if (value is! List) return const [];

  return value
      .whereType<Map>()
      .map(
        (item) => CompanyDashboardComplianceRecord.fromJson(
          Map<String, dynamic>.from(item),
        ),
      )
      .toList(growable: false);
}
