import 'package:flutter/foundation.dart';

class PilotJob {
  const PilotJob({
    required this.id,
    required this.title,
    required this.company,
    required this.location,
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
    this.siteImagesProvided = true,
    this.pidIncluded = true,
  });

  final String id;
  final String title;
  final String company;
  final String location;
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
    required this.id,
    required this.name,
    required this.location,
    required this.rating,
    required this.reviewCount,
    required this.experience,
    required this.successRate,
    required this.missions,
    required this.about,
    required this.skills,
    required this.drones,
    this.verified = true,
  });

  final String id;
  final String name;
  final String location;
  final String rating;
  final int reviewCount;
  final String experience;
  final String successRate;
  final int missions;
  final String about;
  final List<String> skills;
  final List<PilotDrone> drones;
  final bool verified;
}

enum PilotApplicationStatus { submitted, underReview, approved, declined }

extension PilotApplicationStatusLabel on PilotApplicationStatus {
  String get label {
    switch (this) {
      case PilotApplicationStatus.submitted:
        return 'Submitted';
      case PilotApplicationStatus.underReview:
        return 'Under Review';
      case PilotApplicationStatus.approved:
        return 'Approved';
      case PilotApplicationStatus.declined:
        return 'Not selected';
    }
  }
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
  });

  final String id;
  final PilotJob job;
  final PilotDrone drone;
  final PilotApplicationStatus status;
  final String submittedAt;
  final PilotProfile pilot;
  final String? coverNote;
  final String? proposedRate;

  PilotApplication copyWith({PilotApplicationStatus? status}) =>
      PilotApplication(
        id: id,
        job: job,
        drone: drone,
        status: status ?? this.status,
        submittedAt: submittedAt,
        pilot: pilot,
        coverNote: coverNote,
        proposedRate: proposedRate,
      );
}

const solarFarmJob = PilotJob(
  id: 'solar-farm-array',
  title: 'Thermal Inspection - Solar Farm Array',
  company: 'SunTech Energy Ltd.',
  location: 'Mojave Desert, CA',
  pay: r'$850/day',
  date: '2026-08-14',
  distance: '12 km',
  companyRating: '4.8',
  description:
      'Comprehensive thermal imaging survey of 1,200-panel solar installation. '
      'Identify hotspots, damaged cells, and bypass diode failures. Deliverables '
      'include annotated thermal maps and a full PDF report.',
  requirements: [
    'Thermal camera certified',
    'Solar inspection experience',
    'BVLOS waiver preferred',
    'Part 107 required',
  ],
  capabilities: ['Thermal', 'Imaging', 'Night Vision'],
  safetyRequirements: [
    'Safety vest required on site',
    'Hard hat during setup',
    'Pre-flight safety briefing mandatory',
    'Emergency contact on file',
  ],
  jobsPosted: 47,
  pilotsHired: 4,
);

const pilotJobs = <PilotJob>[
  solarFarmJob,
  PilotJob(
    id: 'coastal-mapping',
    title: 'Coastal Mapping Survey',
    company: 'BlueHorizon Analytics',
    location: 'Santa Monica, CA',
    pay: r'$720/day',
    date: '2026-08-19',
    distance: '18 km',
    companyRating: '4.7',
    description: 'Capture georeferenced aerial imagery for shoreline analysis.',
    requirements: ['Part 107 required', 'Mapping experience'],
    capabilities: ['Imaging', 'RTK'],
    safetyRequirements: ['Pre-flight safety briefing mandatory'],
    jobsPosted: 31,
    pilotsHired: 12,
  ),
  PilotJob(
    id: 'wind-turbine',
    title: 'Wind Turbine Visual Inspection',
    company: 'Northline Renewables',
    location: 'Palm Springs, CA',
    pay: r'$920/day',
    date: '2026-08-24',
    distance: '26 km',
    companyRating: '4.9',
    description: 'Visual blade inspection and close-range imagery collection.',
    requirements: ['Inspection experience', 'Part 107 required'],
    capabilities: ['Imaging', 'Zoom'],
    safetyRequirements: ['Safety vest required on site'],
    jobsPosted: 18,
    pilotsHired: 7,
  ),
];

const pilotDrones = <PilotDrone>[
  PilotDrone(
    id: 'matrice-350',
    name: 'DJI Matrice 350 RTK',
    year: '2024',
    capabilities: ['Thermal', 'Imaging', 'LiDAR'],
    isFullMatch: true,
  ),
  PilotDrone(
    id: 'air-3s',
    name: 'DJI Air 3S',
    year: '2025',
    capabilities: ['Imaging', 'Night Vision'],
    isFullMatch: false,
  ),
];

const pilotProfiles = <PilotProfile>[
  PilotProfile(
    id: 'aya-inshasi',
    name: 'Aya Inshasi',
    location: 'Los Angeles, CA',
    rating: '4.9',
    reviewCount: 47,
    experience: '6yr',
    successRate: '98%',
    missions: 248,
    about:
        'FAA Part 107 certified pilot specializing in industrial inspection, thermal imaging, and precision mapping. Completed commercial missions across energy, construction, and infrastructure sectors.',
    skills: ['Thermal', 'Imaging', 'LiDAR', 'RTK'],
    drones: pilotDrones,
  ),
  PilotProfile(
    id: 'marcus-johansson',
    name: 'Marcus Johansson',
    location: 'Los Angeles, CA',
    rating: '4.9',
    reviewCount: 47,
    experience: '6yr',
    successRate: '98%',
    missions: 200,
    about:
        'FAA Part 107 certified pilot with 6 years specializing in industrial inspection, thermal imaging, and precision mapping. Completed 200+ commercial missions across energy, construction, and infrastructure sectors.',
    skills: ['Thermal', 'LiDAR', 'Imaging'],
    drones: pilotDrones,
  ),
  PilotProfile(
    id: 'aisha-okonkwo',
    name: 'Aisha Okonkwo',
    location: 'Houston, TX',
    rating: '4.8',
    reviewCount: 32,
    experience: '4yr',
    successRate: '96%',
    missions: 126,
    about:
        'Commercial drone pilot focused on energy site documentation, aerial imaging, and compliant field operations.',
    skills: ['Imaging', 'Night Vision', 'Thermal'],
    drones: [
      PilotDrone(
        id: 'air-3s',
        name: 'DJI Air 3S',
        year: '2025',
        capabilities: ['Imaging', 'Night Vision'],
        isFullMatch: false,
      ),
    ],
  ),
];

class PilotJobsStore extends ChangeNotifier {
  PilotJobsStore._();

  static final instance = PilotJobsStore._();

  final List<PilotJob> _jobs = List<PilotJob>.from(pilotJobs);

  List<PilotJob> get jobs => List.unmodifiable(_jobs);

  void publish(PilotJob job) {
    _jobs.insert(0, job);
    notifyListeners();
  }
}

enum CompanyJobStatus { active, draft, archived }

extension CompanyJobStatusLabel on CompanyJobStatus {
  String get label {
    switch (this) {
      case CompanyJobStatus.active:
        return 'Active';
      case CompanyJobStatus.draft:
        return 'Draft';
      case CompanyJobStatus.archived:
        return 'Archived';
    }
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
}

class CompanyJobsStore extends ChangeNotifier {
  CompanyJobsStore._();

  static final instance = CompanyJobsStore._();

  final List<CompanyJob> _jobs = const [
    CompanyJob(
      job: solarFarmJob,
      status: CompanyJobStatus.active,
      postedAt: 'Posted 2 hours ago',
      urgent: true,
    ),
    CompanyJob(
      job: PilotJob(
        id: 'lidar-topographic',
        title: 'LiDAR Topographic Mapping - Construction Site',
        company: 'SunTech Energy Ltd.',
        location: 'Barstow, CA',
        pay: r'$1,200/day',
        date: '2026-08-18',
        distance: '21 km',
        companyRating: '4.8',
        description:
            'Topographic mapping for site planning and earthworks documentation.',
        requirements: ['3+ years experience', 'Part 107 required'],
        capabilities: ['LiDAR', 'Imaging'],
        safetyRequirements: ['Hard hat during setup'],
        jobsPosted: 47,
        pilotsHired: 4,
      ),
      status: CompanyJobStatus.active,
      postedAt: 'Posted yesterday',
    ),
    CompanyJob(
      job: PilotJob(
        id: 'substation-draft',
        title: 'Electrical Substation Inspection',
        company: 'SunTech Energy Ltd.',
        location: 'Victorville, CA',
        pay: r'$950/day',
        date: '2026-08-26',
        distance: '32 km',
        companyRating: '4.8',
        description: 'Visual asset inspection for an electrical substation.',
        requirements: ['Part 107 required'],
        capabilities: ['Thermal', 'Imaging'],
        safetyRequirements: ['Safety vest required on site'],
        jobsPosted: 47,
        pilotsHired: 4,
      ),
      status: CompanyJobStatus.draft,
      postedAt: 'Saved today',
    ),
  ];

  List<CompanyJob> get jobs => List.unmodifiable(_jobs);

  int get activeCount =>
      _jobs.where((job) => job.status == CompanyJobStatus.active).length;

  void save(CompanyJob companyJob) {
    _jobs.insert(0, companyJob);
    if (companyJob.status == CompanyJobStatus.active) {
      PilotJobsStore.instance.publish(companyJob.job);
    }
    notifyListeners();
  }
}

class PilotApplicationsStore extends ChangeNotifier {
  PilotApplicationsStore._();

  static final instance = PilotApplicationsStore._();

  final List<PilotApplication> _applications = [
    PilotApplication(
      id: 'solar-application-marcus',
      job: solarFarmJob,
      drone: pilotDrones[1],
      status: PilotApplicationStatus.underReview,
      submittedAt: 'Submitted Jul 22, 2026',
      pilot: pilotProfiles[1],
      coverNote: 'Available for the requested survey window.',
    ),
    PilotApplication(
      id: 'solar-application-aisha',
      job: solarFarmJob,
      drone: pilotDrones[0],
      status: PilotApplicationStatus.submitted,
      submittedAt: 'Submitted Jul 24, 2026',
      pilot: pilotProfiles[2],
    ),
    PilotApplication(
      id: 'city-application',
      job: PilotJob(
        id: 'city-roof',
        title: 'Commercial Roof Assessment',
        company: 'UrbanCore Facilities',
        location: 'Los Angeles, CA',
        pay: r'$640/day',
        date: '2026-08-06',
        distance: '9 km',
        companyRating: '4.6',
        description:
            'Roof condition capture for a commercial property portfolio.',
        requirements: ['Part 107 required'],
        capabilities: ['Imaging'],
        safetyRequirements: ['Hard hat during setup'],
        jobsPosted: 12,
        pilotsHired: 3,
      ),
      drone: pilotDrones[1],
      status: PilotApplicationStatus.approved,
      submittedAt: 'Approved Jul 18, 2026',
      pilot: pilotProfiles[0],
    ),
  ];

  List<PilotApplication> get applications => List.unmodifiable(_applications);

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

  void decline(PilotApplication application) {
    final index = _applications.indexWhere((item) => item.id == application.id);
    if (index == -1) return;
    _applications[index] = application.copyWith(
      status: PilotApplicationStatus.declined,
    );
    notifyListeners();
  }
}
