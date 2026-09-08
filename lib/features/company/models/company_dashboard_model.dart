class CompanyDashboardModel {
  const CompanyDashboardModel({
    required this.jobsByStatus,
    required this.incomingApplicationsCount,
    required this.recentApplicants,
  });

  final CompanyJobsByStatus jobsByStatus;
  final int incomingApplicationsCount;
  final List<CompanyDashboardApplicant> recentApplicants;

  int get totalJobs =>
      jobsByStatus.draft +
      jobsByStatus.published +
      jobsByStatus.closed +
      jobsByStatus.cancelled;

  factory CompanyDashboardModel.fromJson(Map<String, dynamic> json) {
    final rawJobs = json['jobs_by_status'];
    final rawApplicants = json['recent_applicants'];

    return CompanyDashboardModel(
      jobsByStatus: CompanyJobsByStatus.fromJson(
        rawJobs is Map
            ? Map<String, dynamic>.from(rawJobs)
            : const <String, dynamic>{},
      ),
      incomingApplicationsCount: _asInt(
            json['incoming_applications_count'],
          ) ??
          0,
      recentApplicants: rawApplicants is List
          ? rawApplicants
              .whereType<Map>()
              .map(
                (item) => CompanyDashboardApplicant.fromJson(
                  Map<String, dynamic>.from(item),
                ),
              )
              .toList()
          : const <CompanyDashboardApplicant>[],
    );
  }
}

class CompanyJobsByStatus {
  const CompanyJobsByStatus({
    required this.draft,
    required this.published,
    required this.closed,
    required this.cancelled,
  });

  final int draft;
  final int published;
  final int closed;
  final int cancelled;

  factory CompanyJobsByStatus.fromJson(Map<String, dynamic> json) {
    return CompanyJobsByStatus(
      draft: _asInt(json['draft']) ?? 0,
      published: _asInt(json['published']) ?? 0,
      closed: _asInt(json['closed']) ?? 0,
      cancelled: _asInt(json['cancelled']) ?? 0,
    );
  }
}

class CompanyDashboardApplicant {
  const CompanyDashboardApplicant({
    required this.id,
    required this.jobPostingId,
    required this.pilotProfileId,
    required this.droneId,
    required this.coverMessage,
    required this.status,
    required this.decidedAt,
    required this.withdrawnAt,
    required this.createdAt,
    required this.updatedAt,
    required this.rejectionReason,
    required this.pilotProfile,
    required this.jobPosting,
    required this.drone,
  });

  final int id;
  final int jobPostingId;
  final int pilotProfileId;
  final int droneId;
  final String? coverMessage;
  final String status;
  final DateTime? decidedAt;
  final DateTime? withdrawnAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? rejectionReason;
  final CompanyDashboardPilotProfile? pilotProfile;
  final CompanyDashboardJobPosting? jobPosting;
  final CompanyDashboardDrone? drone;

  factory CompanyDashboardApplicant.fromJson(Map<String, dynamic> json) {
    final rawPilot = json['pilot_profile'];
    final rawJob = json['job_posting'];
    final rawDrone = json['drone'];

    return CompanyDashboardApplicant(
      id: _asInt(json['id']) ?? 0,
      jobPostingId: _asInt(json['job_posting_id']) ?? 0,
      pilotProfileId: _asInt(json['pilot_profile_id']) ?? 0,
      droneId: _asInt(json['drone_id']) ?? 0,
      coverMessage: _clean(json['cover_message']),
      status: _clean(json['status']) ?? 'pending',
      decidedAt: _asDate(json['decided_at']),
      withdrawnAt: _asDate(json['withdrawn_at']),
      createdAt: _asDate(json['created_at']),
      updatedAt: _asDate(json['updated_at']),
      rejectionReason: _clean(json['rejection_reason']),
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
  const CompanyDashboardPilotProfile({
    required this.id,
    required this.userId,
    required this.bio,
    required this.experienceYears,
    required this.nationality,
    required this.dateOfBirth,
    required this.linkedinUrl,
    required this.previousCompany,
    required this.languages,
    required this.currentCountry,
    required this.currentState,
    required this.currentCity,
  });

  final int id;
  final int userId;
  final String? bio;
  final int? experienceYears;
  final String? nationality;
  final DateTime? dateOfBirth;
  final String? linkedinUrl;
  final String? previousCompany;
  final List<String> languages;
  final String? currentCountry;
  final String? currentState;
  final String? currentCity;

  String get location {
    final parts = <String>[
      if (currentCity != null) currentCity!,
      if (currentState != null && currentState != currentCity) currentState!,
      if (currentCountry != null) currentCountry!,
    ];
    return parts.isEmpty ? 'Location not provided' : parts.join(', ');
  }

  factory CompanyDashboardPilotProfile.fromJson(
    Map<String, dynamic> json,
  ) {
    final rawLanguages = json['languages'];

    return CompanyDashboardPilotProfile(
      id: _asInt(json['id']) ?? 0,
      userId: _asInt(json['user_id']) ?? 0,
      bio: _clean(json['bio']),
      experienceYears: _asInt(json['experience_years']),
      nationality: _clean(json['nationality']),
      dateOfBirth: _asDate(json['date_of_birth']),
      linkedinUrl: _clean(json['linkedin_url']),
      previousCompany: _clean(json['previous_company']),
      languages: rawLanguages is List
          ? rawLanguages
              .map((item) => item.toString().trim())
              .where((item) => item.isNotEmpty)
              .toList()
          : const <String>[],
      currentCountry: _clean(json['current_country']),
      currentState: _clean(json['current_state']),
      currentCity: _clean(json['current_city']),
    );
  }
}

class CompanyDashboardJobPosting {
  const CompanyDashboardJobPosting({
    required this.id,
    required this.title,
    required this.country,
    required this.state,
    required this.city,
    required this.startDate,
    required this.endDate,
    required this.paymentType,
    required this.paymentMin,
    required this.paymentMax,
    required this.status,
    required this.serviceCategory,
    required this.region,
  });

  final int id;
  final String title;
  final String? country;
  final String? state;
  final String? city;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? paymentType;
  final double? paymentMin;
  final double? paymentMax;
  final String status;
  final String? serviceCategory;
  final String? region;

  String get location {
    final parts = <String>[
      if (city != null) city!,
      if (state != null && state != city) state!,
      if (country != null) country!,
    ];
    return parts.isEmpty ? 'Location not provided' : parts.join(', ');
  }

  factory CompanyDashboardJobPosting.fromJson(Map<String, dynamic> json) {
    return CompanyDashboardJobPosting(
      id: _asInt(json['id']) ?? 0,
      title: _clean(json['title']) ?? 'Job #${_asInt(json['id']) ?? 0}',
      country: _clean(json['country']),
      state: _clean(json['state']),
      city: _clean(json['city']),
      startDate: _asDate(json['start_date']),
      endDate: _asDate(json['end_date']),
      paymentType: _clean(json['payment_type']),
      paymentMin: _asDouble(json['payment_min']),
      paymentMax: _asDouble(json['payment_max']),
      status: _clean(json['status']) ?? '',
      serviceCategory: _clean(json['service_category']),
      region: _clean(json['region']),
    );
  }
}

class CompanyDashboardDrone {
  const CompanyDashboardDrone({
    required this.id,
    required this.make,
    required this.model,
    required this.manufactureYear,
    required this.serialNumber,
    required this.capabilities,
    required this.flightTime,
    required this.chargingTime,
  });

  final int id;
  final String? make;
  final String? model;
  final int? manufactureYear;
  final String? serialNumber;
  final List<String> capabilities;
  final int? flightTime;
  final int? chargingTime;

  String get displayName {
    final parts = <String>[
      if (make != null) make!,
      if (model != null) model!,
    ];
    return parts.isEmpty ? 'Drone #$id' : parts.join(' ');
  }

  factory CompanyDashboardDrone.fromJson(Map<String, dynamic> json) {
    final rawCapabilities = json['capabilities'];

    return CompanyDashboardDrone(
      id: _asInt(json['id']) ?? 0,
      make: _clean(json['make']),
      model: _clean(json['model']),
      manufactureYear: _asInt(json['manufacture_year']),
      serialNumber: _clean(json['serial_number']),
      capabilities: rawCapabilities is List
          ? rawCapabilities
              .map((item) => item.toString().trim())
              .where((item) => item.isNotEmpty)
              .toList()
          : const <String>[],
      flightTime: _asInt(
        json['flight_time'] ?? json['flight_time_per_battery_minutes'],
      ),
      chargingTime: _asInt(json['charging_time']),
    );
  }
}

int? _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '');
}

double? _asDouble(dynamic value) {
  if (value is double) return value;
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '');
}

DateTime? _asDate(dynamic value) {
  final text = value?.toString().trim();
  if (text == null || text.isEmpty) return null;
  return DateTime.tryParse(text)?.toLocal();
}

String? _clean(dynamic value) {
  final text = value?.toString().trim();
  return text == null || text.isEmpty ? null : text;
}
