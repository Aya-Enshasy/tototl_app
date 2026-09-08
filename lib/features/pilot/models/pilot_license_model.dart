class PilotLicenseDocument {
  const PilotLicenseDocument({
    this.id,
    this.name,
    this.url,
    this.mimeType,
    this.size,
  });

  final int? id;
  final String? name;
  final String? url;
  final String? mimeType;
  final int? size;

  bool get hasValue =>
      id != null ||
      (name?.trim().isNotEmpty ?? false) ||
      (url?.trim().isNotEmpty ?? false);

  factory PilotLicenseDocument.fromDynamic(dynamic raw) {
    if (raw == null) {
      return const PilotLicenseDocument();
    }

    if (raw is String) {
      final clean = raw.trim();
      if (clean.isEmpty) {
        return const PilotLicenseDocument();
      }

      return PilotLicenseDocument(
        name: _fileNameFromUrl(clean),
        url: clean,
      );
    }

    if (raw is Map) {
      final map = Map<String, dynamic>.from(raw);

      final url = _firstString(map, const [
        'url',
        'download_url',
        'file_url',
        'full_url',
        'temporary_url',
      ]);

      return PilotLicenseDocument(
        id: _asInt(
          map['id'] ??
              map['media_id'] ??
              map['document_id'],
        ),
        name: _firstString(map, const [
              'name',
              'file_name',
              'original_name',
              'filename',
            ]) ??
            (url == null ? null : _fileNameFromUrl(url)),
        url: url,
        mimeType: _firstString(map, const [
          'mime_type',
          'mime',
          'content_type',
        ]),
        size: _asInt(
          map['size'] ??
              map['file_size'] ??
              map['size_bytes'],
        ),
      );
    }

    return const PilotLicenseDocument();
  }
}

class PilotLicenseModel {
  const PilotLicenseModel({
    required this.id,
    required this.licenseType,
    required this.licenseNumber,
    required this.issuingAuthority,
    required this.expiresAt,
    this.pilotProfileId,
    this.licenseDocument,
    this.permitOrInsuranceDocument,
    this.createdAt,
    this.updatedAt,
  });

  final int id;
  final int? pilotProfileId;
  final String licenseType;
  final String licenseNumber;
  final String issuingAuthority;
  final DateTime? expiresAt;
  final PilotLicenseDocument? licenseDocument;
  final PilotLicenseDocument? permitOrInsuranceDocument;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isExpired {
    final expiry = expiresAt;
    if (expiry == null) return false;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(expiry.year, expiry.month, expiry.day);

    return date.isBefore(today);
  }

  bool get isExpiringSoon {
    final expiry = expiresAt;
    if (expiry == null || isExpired) return false;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(expiry.year, expiry.month, expiry.day);

    final days = date.difference(today).inDays;
    return days <= 30;
  }

  factory PilotLicenseModel.fromJson(Map<String, dynamic> json) {
    final primaryRaw =
        json['license_document'] ??
        json['licenseDocument'] ??
        json['license_document_media'] ??
        json['license_document_url'];

    final secondaryRaw =
        json['permit_or_insurance_document'] ??
        json['permitOrInsuranceDocument'] ??
        json['permit_or_insurance_document_media'] ??
        json['permit_or_insurance_document_url'];

    final primary = PilotLicenseDocument.fromDynamic(primaryRaw);
    final secondary = PilotLicenseDocument.fromDynamic(secondaryRaw);

    return PilotLicenseModel(
      id: _asInt(json['id']) ?? 0,
      pilotProfileId: _asInt(
        json['pilot_profile_id'] ??
            json['pilotProfileId'],
      ),
      licenseType: _asString(
        json['license_type'] ??
            json['licenseType'],
      ),
      licenseNumber: _asString(
        json['license_number'] ??
            json['licenseNumber'],
      ),
      issuingAuthority: _asString(
        json['issuing_authority'] ??
            json['issuingAuthority'],
      ),
      expiresAt: _asDateTime(
        json['expires_at'] ??
            json['expiresAt'],
      ),
      licenseDocument: primary.hasValue ? primary : null,
      permitOrInsuranceDocument:
          secondary.hasValue ? secondary : null,
      createdAt: _asDateTime(
        json['created_at'] ??
            json['createdAt'],
      ),
      updatedAt: _asDateTime(
        json['updated_at'] ??
            json['updatedAt'],
      ),
    );
  }
}

String _asString(dynamic value) {
  return value?.toString().trim() ?? '';
}

String? _firstString(
  Map<String, dynamic> map,
  List<String> keys,
) {
  for (final key in keys) {
    final value = map[key];
    if (value == null) continue;

    final text = value.toString().trim();
    if (text.isNotEmpty) return text;
  }

  return null;
}

int? _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '');
}

DateTime? _asDateTime(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;

  final text = value.toString().trim();
  if (text.isEmpty) return null;

  return DateTime.tryParse(text);
}

String _fileNameFromUrl(String url) {
  final uri = Uri.tryParse(url);
  if (uri != null && uri.pathSegments.isNotEmpty) {
    return uri.pathSegments.last;
  }

  final parts = url.split('/');
  return parts.isEmpty ? 'Document' : parts.last;
}
