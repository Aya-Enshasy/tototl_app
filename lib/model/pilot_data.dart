import 'package:flutter/foundation.dart';

/// ============================================================================
/// ENUMS
/// ============================================================================

enum PilotApplicationStatus {
  submitted,
  underReview,
  accepted,
  declined,
  withdrawn;

  String get label {
    switch (this) {
      case PilotApplicationStatus.submitted:
        return 'Submitted';
      case PilotApplicationStatus.underReview:
        return 'Under Review';
      case PilotApplicationStatus.accepted:
        return 'Accepted';
      case PilotApplicationStatus.declined:
        return 'Declined';
      case PilotApplicationStatus.withdrawn:
        return 'Withdrawn';
    }
  }
}

enum CompanyJobStatus {
  draft,
  active,
  closed;

  String get label {
    switch (this) {
      case CompanyJobStatus.draft:
        return 'Draft';
      case CompanyJobStatus.active:
        return 'Active';
      case CompanyJobStatus.closed:
        return 'Closed';
    }
  }
}

/// ============================================================================
/// CORE MODELS
/// ============================================================================

class PilotJob {
  const PilotJob({
    required this.id,
    required this.title,
    required this.company,
    required this.location,
    this.country = '',
    this.city = '',
    this.region = '',
    this.address,
    this.gpsCoordinates,
    required this.pay,
    required this.date,
    required this.distance,
    required this.companyRating,
    required this.description,
    required this.requirements,
    required this.capabilities,
    required this.safetyRequirements,
    required this.jobsPosted,
    required this.pilotsHired,
    required this.siteImagesProvided,
    required this.pidIncluded,
  });

  final String id;
  final String title;
  final String company;

  /// Backward-compatible combined display string, e.g. "Los Angeles, United States".
  final String location;

  // Structured location — use these for anything that needs to show
  // country / city / region separately and unambiguously.
  final String country;
  final String city;
  final String region;

  /// Exact street address. Kept private on job cards; only meant to be
  /// revealed to a pilot after their application is accepted.
  final String? address;
  final String? gpsCoordinates;

  final String pay;
  final String date;
  final String distance;
  final String companyRating;
  final String description;
  final List<String> requirements;
  final List<String> capabilities;
  final List<String> safetyRequirements;
  final int jobsPosted;
  final int pilotsHired;
  final bool siteImagesProvided;
  final bool pidIncluded;

  PilotJob copyWith({
    String? id,
    String? title,
    String? company,
    String? location,
    String? country,
    String? city,
    String? region,
    String? address,
    String? gpsCoordinates,
    String? pay,
    String? date,
    String? distance,
    String? companyRating,
    String? description,
    List<String>? requirements,
    List<String>? capabilities,
    List<String>? safetyRequirements,
    int? jobsPosted,
    int? pilotsHired,
    bool? siteImagesProvided,
    bool? pidIncluded,
  }) {
    return PilotJob(
      id: id ?? this.id,
      title: title ?? this.title,
      company: company ?? this.company,
      location: location ?? this.location,
      country: country ?? this.country,
      city: city ?? this.city,
      region: region ?? this.region,
      address: address ?? this.address,
      gpsCoordinates: gpsCoordinates ?? this.gpsCoordinates,
      pay: pay ?? this.pay,
      date: date ?? this.date,
      distance: distance ?? this.distance,
      companyRating: companyRating ?? this.companyRating,
      description: description ?? this.description,
      requirements: requirements ?? this.requirements,
      capabilities: capabilities ?? this.capabilities,
      safetyRequirements: safetyRequirements ?? this.safetyRequirements,
      jobsPosted: jobsPosted ?? this.jobsPosted,
      pilotsHired: pilotsHired ?? this.pilotsHired,
      siteImagesProvided: siteImagesProvided ?? this.siteImagesProvided,
      pidIncluded: pidIncluded ?? this.pidIncluded,
    );
  }
}

class PilotDrone {
  const PilotDrone({
    required this.id,
    required this.name,
    required this.year,
    required this.capabilities,
    required this.isFullMatch,
  });

  final String id;
  final String name;
  final String year;
  final List<String> capabilities;
  final bool isFullMatch;
}

class PilotProfile {
  const PilotProfile({
    required this.name,
    required this.location,
    required this.experience,
    required this.rating,
    required this.skills,
  });

  final String name;
  final String location;
  final String experience;
  final String rating;
  final List<String> skills;
}

class PilotApplication {
  const PilotApplication({
    required this.id,
    required this.job,
    required this.drone,
    required this.status,
    required this.submittedAt,
    required this.pilot,
    this.coverNote,
    this.proposedRate,
    this.equipmentOffered = const [],
    this.additionalCertifications = const [],
  });

  final String id;
  final PilotJob job;
  final PilotDrone drone;
  final PilotApplicationStatus status;
  final String submittedAt;
  final PilotProfile pilot;
  final String? coverNote;
  final String? proposedRate;

  /// Equipment/sensors the pilot confirmed they can bring to this job.
  final List<String> equipmentOffered;

  /// Extra certifications the pilot listed for this specific application.
  final List<String> additionalCertifications;

  PilotApplication copyWith({
    String? id,
    PilotJob? job,
    PilotDrone? drone,
    PilotApplicationStatus? status,
    String? submittedAt,
    PilotProfile? pilot,
    String? coverNote,
    String? proposedRate,
    List<String>? equipmentOffered,
    List<String>? additionalCertifications,
  }) {
    return PilotApplication(
      id: id ?? this.id,
      job: job ?? this.job,
      drone: drone ?? this.drone,
      status: status ?? this.status,
      submittedAt: submittedAt ?? this.submittedAt,
      pilot: pilot ?? this.pilot,
      coverNote: coverNote ?? this.coverNote,
      proposedRate: proposedRate ?? this.proposedRate,
      equipmentOffered: equipmentOffered ?? this.equipmentOffered,
      additionalCertifications:
          additionalCertifications ?? this.additionalCertifications,
    );
  }
}

class CompanyJob {
  const CompanyJob({
    required this.job,
    required this.status,
    required this.postedAt,
    this.urgent = false,
  });

  final PilotJob job;
  final CompanyJobStatus status;
  final String postedAt;
  final bool urgent;

  CompanyJob copyWith({
    PilotJob? job,
    CompanyJobStatus? status,
    String? postedAt,
    bool? urgent,
  }) {
    return CompanyJob(
      job: job ?? this.job,
      status: status ?? this.status,
      postedAt: postedAt ?? this.postedAt,
      urgent: urgent ?? this.urgent,
    );
  }
}

/// ============================================================================
/// STORES
/// Simple in-memory, notifier-based stores. Swap the internals for a real
/// backend/local database later without touching the screens that consume
/// them — they only rely on `.instance`, the getters, and the mutator
/// methods below.
/// ============================================================================

class PilotApplicationsStore extends ChangeNotifier {
  PilotApplicationsStore._internal();

  static final PilotApplicationsStore instance =
      PilotApplicationsStore._internal();

  final List<PilotApplication> _applications = [];

  List<PilotApplication> get applications => List.unmodifiable(_applications);

  /// Applications that are still "in play" — used for dashboard counters.
  int get activeCount => _applications
      .where(
        (application) =>
            application.status == PilotApplicationStatus.submitted ||
            application.status == PilotApplicationStatus.underReview,
      )
      .length;

  void submit(PilotApplication application) {
    _applications.insert(0, application);
    notifyListeners();
  }

  void updateStatus(String applicationId, PilotApplicationStatus status) {
    final index = _applications.indexWhere(
      (application) => application.id == applicationId,
    );
    if (index == -1) return;
    _applications[index] = _applications[index].copyWith(status: status);
    notifyListeners();
  }

  void withdraw(String applicationId) {
    updateStatus(applicationId, PilotApplicationStatus.withdrawn);
  }
}

class CompanyJobsStore extends ChangeNotifier {
  CompanyJobsStore._internal();

  static final CompanyJobsStore instance = CompanyJobsStore._internal();

  final List<CompanyJob> _jobs = [];

  List<CompanyJob> get jobs => List.unmodifiable(_jobs);

  List<CompanyJob> get activeJobs => _jobs
      .where((companyJob) => companyJob.status == CompanyJobStatus.active)
      .toList();

  List<CompanyJob> get draftJobs => _jobs
      .where((companyJob) => companyJob.status == CompanyJobStatus.draft)
      .toList();

  void save(CompanyJob companyJob) {
    _jobs.insert(0, companyJob);
    notifyListeners();
  }

  void updateStatus(String jobId, CompanyJobStatus status) {
    final index = _jobs.indexWhere((companyJob) => companyJob.job.id == jobId);
    if (index == -1) return;
    _jobs[index] = _jobs[index].copyWith(status: status);
    notifyListeners();
  }
}

/// ============================================================================
/// SAMPLE DATA
/// Placeholder data so screens like ApplyForJobScreen (which reads
/// `pilotDrones.first` / `pilotProfiles.first`) have something to render.
/// Replace with data loaded from your real pilot profile / fleet source.
/// ============================================================================

final List<PilotDrone> pilotDrones = [
  const PilotDrone(
    id: 'drone-matrice-350',
    name: 'DJI Matrice 350 RTK',
    year: '2023',
    capabilities: ['Thermal Camera', 'LiDAR', 'Night Vision'],
    isFullMatch: true,
  ),
  const PilotDrone(
    id: 'drone-mavic-3t',
    name: 'DJI Mavic 3T',
    year: '2022',
    capabilities: ['Thermal Camera', 'Imaging'],
    isFullMatch: false,
  ),
  const PilotDrone(
    id: 'drone-phantom-4',
    name: 'DJI Phantom 4 RTK',
    year: '2021',
    capabilities: ['Imaging'],
    isFullMatch: false,
  ),
];

final List<PilotProfile> pilotProfiles = [
  const PilotProfile(
    name: 'Ahmad Nassar',
    location: 'Nablus, Palestine',
    experience: '6yr experience',
    rating: '4.9',
    skills: ['Thermal Camera', 'LiDAR', 'Imaging', 'Night Vision'],
  ),
];
