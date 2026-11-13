class CompanyCreateJobRequest {
  final String title;
  final String description;
  final String country;

  final String? serviceCategory;
  final String? state;
  final String? city;
  final String? region;

  final DateTime startDate;
  final DateTime endDate;

  // Phase 4 / later Job API additions.
  //
  // Coordinates are optional, but when one is supplied the other must also
  // be supplied. The backend validates them against country/state/city.
  final double? latitude;
  final double? longitude;

  // Last date on which pilots may submit proposals.
  // Must not be after startDate.
  final DateTime? proposalDeadline;

  // Decimal duration in days. Half-days such as 2.5 are supported.
  final double? estimatedDays;

  // Maximum 20 items, each item max 255 characters.
  final List<String> deliverables;

  final String? clearanceNotes;

  final String paymentType;
  final double? paymentMin;
  final double? paymentMax;

  final List<String> requiredCapabilities;
  final String? requiredExperience;
  final List<String> requiredCertifications;

  final String? droneSize;
  final bool trainingSafetyRequired;
  final bool ndaRequired;

  final String? requirementsNotes;

  final List<String> attachmentPaths;

  const CompanyCreateJobRequest({
    required this.title,
    required this.description,
    required this.country,
    this.serviceCategory,
    this.state,
    this.city,
    this.region,
    required this.startDate,
    required this.endDate,
    this.latitude,
    this.longitude,
    this.proposalDeadline,
    this.estimatedDays,
    this.deliverables = const [],
    this.clearanceNotes,
    required this.paymentType,
    this.paymentMin,
    this.paymentMax,
    this.requiredCapabilities = const [],
    this.requiredExperience,
    this.requiredCertifications = const [],
    this.droneSize,
    this.trainingSafetyRequired = false,
    this.ndaRequired = false,
    this.requirementsNotes,
    this.attachmentPaths = const [],
  });

  bool get hasCoordinates =>
      latitude != null &&
          longitude != null;

  bool get hasPartialCoordinates =>
      (latitude != null &&
          longitude == null) ||
          (latitude == null &&
              longitude != null);

  bool get hasProposalDeadline =>
      proposalDeadline != null;

  bool get hasEstimatedDays =>
      estimatedDays != null;

  bool get hasDeliverables =>
      deliverables.isNotEmpty;

  bool get hasClearanceNotes =>
      clearanceNotes
          ?.trim()
          .isNotEmpty ==
          true;
}