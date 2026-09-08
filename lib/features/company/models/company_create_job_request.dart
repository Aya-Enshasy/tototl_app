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
}
