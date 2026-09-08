class PilotLicenseFormRequest {
  const PilotLicenseFormRequest({
    required this.licenseType,
    required this.licenseNumber,
    required this.issuingAuthority,
    required this.expiresAt,
    this.licenseDocumentPath,
    this.permitOrInsuranceDocumentPath,
  });

  final String licenseType;
  final String licenseNumber;
  final String issuingAuthority;
  final DateTime expiresAt;

  /// Required when creating a new license.
  /// Optional when editing an existing one.
  final String? licenseDocumentPath;

  final String? permitOrInsuranceDocumentPath;

  Map<String, dynamic> toFields() {
    return {
      'license_type': licenseType.trim(),
      'license_number': licenseNumber.trim(),
      'issuing_authority': issuingAuthority.trim(),
      'expires_at': DateTime.utc(
        expiresAt.year,
        expiresAt.month,
        expiresAt.day,
        23,
        59,
        59,
      ).toIso8601String(),
    };
  }
}
