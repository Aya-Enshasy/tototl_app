class PilotLicenseModel {
  final int id;
  final int? pilotProfileId;
  final String licenseType;
  final String licenseNumber;
  final String issuingAuthority;
  final DateTime? expiresAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<PilotLicenseDocument> media;

  const PilotLicenseModel({
    this.id = 0,
    this.pilotProfileId,
    this.licenseType = '',
    this.licenseNumber = '',
    this.issuingAuthority = '',
    this.expiresAt,
    this.createdAt,
    this.updatedAt,
    this.media = const <PilotLicenseDocument>[],
  });

  factory PilotLicenseModel.fromJson(Map<String, dynamic> json) {
    final media = <PilotLicenseDocument>[];
    final rawMedia = json['media'];

    if (rawMedia is List) {
      for (final item in rawMedia) {
        if (item is Map) {
          media.add(
            PilotLicenseDocument.fromJson(
              Map<String, dynamic>.from(item),
            ),
          );
        }
      }
    }

    return PilotLicenseModel(
      id: _asInt(json['id']) ?? 0,
      pilotProfileId: _asInt(
        json['pilot_profile_id'] ?? json['pilotProfileId'],
      ),
      licenseType: _asString(
        json['license_type'] ?? json['licenseType'],
      ),
      licenseNumber: _asString(
        json['license_number'] ?? json['licenseNumber'],
      ),
      issuingAuthority: _asString(
        json['issuing_authority'] ?? json['issuingAuthority'],
      ),
      expiresAt: _asDate(
        json['expires_at'] ?? json['expiresAt'],
      ),
      createdAt: _asDate(
        json['created_at'] ?? json['createdAt'],
      ),
      updatedAt: _asDate(
        json['updated_at'] ?? json['updatedAt'],
      ),
      media: media,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'pilot_profile_id': pilotProfileId,
      'license_type': licenseType,
      'license_number': licenseNumber,
      'issuing_authority': issuingAuthority,
      'expires_at': expiresAt?.toIso8601String(),
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'media': media.map((item) => item.toJson()).toList(),
    };
  }

  PilotLicenseModel copyWith({
    int? id,
    int? pilotProfileId,
    String? licenseType,
    String? licenseNumber,
    String? issuingAuthority,
    DateTime? expiresAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<PilotLicenseDocument>? media,
  }) {
    return PilotLicenseModel(
      id: id ?? this.id,
      pilotProfileId: pilotProfileId ?? this.pilotProfileId,
      licenseType: licenseType ?? this.licenseType,
      licenseNumber: licenseNumber ?? this.licenseNumber,
      issuingAuthority: issuingAuthority ?? this.issuingAuthority,
      expiresAt: expiresAt ?? this.expiresAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      media: media ?? this.media,
    );
  }

  PilotLicenseDocument? get licenseDocument {
    return _documentForCollection('license_document');
  }

  PilotLicenseDocument? get permitOrInsuranceDocument {
    return _documentForCollection('permit_or_insurance_document');
  }

  PilotLicenseDocument? _documentForCollection(String collection) {
    for (final item in media) {
      if (item.collectionName.trim().toLowerCase() == collection) {
        return item;
      }
    }
    return null;
  }

  bool get isExpired {
    final expiry = expiresAt;
    if (expiry == null) return false;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final expiryDay = DateTime(expiry.year, expiry.month, expiry.day);

    return expiryDay.isBefore(today);
  }

  bool get isExpiringSoon {
    final expiry = expiresAt;
    if (expiry == null || isExpired) return false;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final expiryDay = DateTime(expiry.year, expiry.month, expiry.day);
    final days = expiryDay.difference(today).inDays;

    return days >= 0 && days <= 30;
  }
}

class PilotLicenseDocument {
  final int? id;
  final String collectionName;
  final String fileName;
  final String mimeType;
  final int? size;
  final String url;
  final String downloadUrl;
  final DateTime? createdAt;

  const PilotLicenseDocument({
    this.id,
    this.collectionName = '',
    this.fileName = '',
    this.mimeType = '',
    this.size,
    this.url = '',
    this.downloadUrl = '',
    this.createdAt,
  });

  factory PilotLicenseDocument.fromJson(Map<String, dynamic> json) {
    return PilotLicenseDocument(
      id: _asInt(json['id']),
      collectionName: _asString(
        json['collection_name'] ?? json['collectionName'],
      ),
      fileName: _asString(
        json['file_name'] ?? json['fileName'],
      ),
      mimeType: _asString(
        json['mime_type'] ?? json['mimeType'],
      ),
      size: _asInt(json['size']),
      url: _asString(json['url']),
      downloadUrl: _asString(
        json['download_url'] ?? json['downloadUrl'],
      ),
      createdAt: _asDate(
        json['created_at'] ?? json['createdAt'],
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'collection_name': collectionName,
      'file_name': fileName,
      'mime_type': mimeType,
      'size': size,
      'url': url,
      'download_url': downloadUrl,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  /// Existing UI compatibility.
  String? get name {
    final value = fileName.trim();
    return value.isEmpty ? null : value;
  }

  /// Private media may legitimately have url == null/empty while download_url
  /// is present. download_url therefore counts as a real attached document.
  bool get hasValue {
    return id != null ||
        fileName.trim().isNotEmpty ||
        url.trim().isNotEmpty ||
        downloadUrl.trim().isNotEmpty;
  }

  String get bestDownloadUrl {
    final privateUrl = downloadUrl.trim();
    if (privateUrl.isNotEmpty) return privateUrl;
    return url.trim();
  }
}

String _asString(dynamic value) {
  if (value == null) return '';
  return value.toString().trim();
}

int? _asInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  return int.tryParse(value.toString());
}

DateTime? _asDate(dynamic value) {
  if (value == null) return null;

  final text = value.toString().trim();
  if (text.isEmpty) return null;

  return DateTime.tryParse(text);
}
