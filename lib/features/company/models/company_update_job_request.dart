class CompanyUpdateJobRequest {
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
  // Coordinates remain optional, but they must be supplied together.
  final double? latitude;
  final double? longitude;

  // Last day on which pilots may submit proposals.
  // Backend requires proposalDeadline <= startDate.
  final DateTime? proposalDeadline;

  // Decimal number of expected working days.
  final double? estimatedDays;

  // Maximum 20 items, each <= 255 characters.
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

  const CompanyUpdateJobRequest({
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
  });

  bool get hasCoordinates =>
      latitude != null &&
          longitude != null;

  bool get hasPartialCoordinates =>
      (latitude != null && longitude == null) ||
          (latitude == null && longitude != null);

  bool get hasProposalDeadline =>
      proposalDeadline != null;

  bool get hasEstimatedDays =>
      estimatedDays != null;

  bool get hasDeliverables =>
      deliverables.isNotEmpty;

  bool get hasClearanceNotes =>
      clearanceNotes?.trim().isNotEmpty == true;
}