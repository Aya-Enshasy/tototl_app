// ============================================================================
// COMPANY PROFILE VIEW DATA
// ============================================================================

class CompanyProfileViewData {
  final CompanyAccountModel account;
  final CompanyProfileModel profile;
  final String profilePhotoUrl;

  const CompanyProfileViewData({
    required this.account,
    required this.profile,
    this.profilePhotoUrl = '',
  });

  CompanyProfileViewData copyWith({
    CompanyAccountModel? account,
    CompanyProfileModel? profile,
    String? profilePhotoUrl,
  }) {
    return CompanyProfileViewData(
      account: account ?? this.account,
      profile: profile ?? this.profile,
      profilePhotoUrl:
      profilePhotoUrl ?? this.profilePhotoUrl,
    );
  }
}

// ============================================================================
// COMPANY ACCOUNT
// ============================================================================

class CompanyAccountModel {
  final int? id;
  final String name;
  final String email;
  final String username;
  final String status;
  final String phone;

  const CompanyAccountModel({
    this.id,
    this.name = '',
    this.email = '',
    this.username = '',
    this.status = '',
    this.phone = '',
  });

  factory CompanyAccountModel.fromJson(
      Map<String, dynamic> json,
      ) {
    return CompanyAccountModel(
      id: _asInt(
        json['id'],
      ),
      name: _asString(
        json['name'],
      ),
      email: _asString(
        json['email'],
      ),
      username: _asString(
        json['username'],
      ),
      status: _asString(
        json['status'],
      ),
      phone: _asString(
        json['phone'],
      ),
    );
  }

  String get displayName {
    final value =
    name.trim();

    if (value.isEmpty) {
      return 'Company';
    }

    return value;
  }

  String get displayUsername {
    final value =
    username.trim();

    if (value.isEmpty) {
      return '';
    }

    if (value.startsWith('@')) {
      return value;
    }

    return '@$value';
  }

  bool get isVerified {
    final value =
    status.trim().toLowerCase();

    return value == 'verified' ||
        value == 'approved' ||
        value == 'active';
  }

  String get statusLabel {
    final value =
    status.trim().toLowerCase();

    if (value.isEmpty) {
      return 'Pending';
    }

    switch (value) {
      case 'verified':
      case 'approved':
      case 'active':
        return 'Verified Company';

      case 'pending':
        return 'Pending Verification';

      case 'rejected':
        return 'Verification Rejected';

      default:
        return status;
    }
  }
}

// ============================================================================
// COMPANY PROFILE
// ============================================================================

class CompanyProfileModel {
  final int? id;
  final int? userId;

  final String companyName;
  final String industryType;
  final String description;

  final String country;
  final String state;
  final String city;
  final String address;

  final String website;

  final String profilePhoto;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  final List<CompanyWorkRegionModel>
  workRegions;

  const CompanyProfileModel({
    this.id,
    this.userId,
    this.companyName = '',
    this.industryType = '',
    this.description = '',
    this.country = '',
    this.state = '',
    this.city = '',
    this.address = '',
    this.website = '',
    this.profilePhoto = '',
    this.createdAt,
    this.updatedAt,
    this.workRegions = const [],
  });

  factory CompanyProfileModel.fromJson(
      Map<String, dynamic> json,
      ) {
    final workRegions =
    <CompanyWorkRegionModel>[];

    final rawRegions =
    json['work_regions'];

    if (rawRegions is List) {
      for (final item in rawRegions) {
        if (item is Map) {
          workRegions.add(
            CompanyWorkRegionModel.fromJson(
              Map<String, dynamic>.from(
                item,
              ),
            ),
          );
        }
      }
    }

    return CompanyProfileModel(
      id: _asInt(
        json['id'],
      ),

      userId: _asInt(
        json['user_id'],
      ),

      companyName: _asString(
        json['company_name'],
      ),

      industryType: _asString(
        json['industry_type'],
      ),

      description: _asString(
        json['description'],
      ),

      country: _asString(
        json['country'],
      ),

      state: _asString(
        json['state'],
      ),

      city: _asString(
        json['city'],
      ),

      address: _asString(
        json['address'],
      ),

      website: _asString(
        json['website'],
      ),

      profilePhoto: _asString(
        json['profile_photo'],
      ),

      createdAt: _asDate(
        json['created_at'],
      ),

      updatedAt: _asDate(
        json['updated_at'],
      ),

      workRegions:
      workRegions,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id':
      id,

      'user_id':
      userId,

      'company_name':
      companyName,

      'industry_type':
      industryType,

      'description':
      description,

      'country':
      country,

      'state':
      state,

      'city':
      city,

      'address':
      address,

      'website':
      website,

      if (profilePhoto.isNotEmpty)
        'profile_photo':
        profilePhoto,

      'created_at':
      createdAt?.toIso8601String(),

      'updated_at':
      updatedAt?.toIso8601String(),

      'work_regions':
      workRegions
          .map(
            (item) =>
            item.toJson(),
      )
          .toList(),
    };
  }

  String get displayCompanyName {
    final value =
    companyName.trim();

    if (value.isEmpty) {
      return 'Company';
    }

    return value;
  }

  String get locationLabel {
    final values =
    <String>[
      city,
      state,
      country,
    ].where(
          (value) =>
      value.trim().isNotEmpty,
    ).toList();

    if (values.isEmpty) {
      return 'Location not specified';
    }

    return values.join(
      ', ',
    );
  }

  String get industryAndLocationLabel {
    final values =
    <String>[
      industryType,
      locationLabel ==
          'Location not specified'
          ? ''
          : locationLabel,
    ].where(
          (value) =>
      value.trim().isNotEmpty,
    ).toList();

    if (values.isEmpty) {
      return 'Company profile';
    }

    return values.join(
      ' · ',
    );
  }
}

// ============================================================================
// COMPANY WORK REGION
// ============================================================================

class CompanyWorkRegionModel {
  final int? id;
  final int? companyProfileId;

  final String country;
  final String state;
  final String city;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  const CompanyWorkRegionModel({
    this.id,
    this.companyProfileId,
    this.country = '',
    this.state = '',
    this.city = '',
    this.createdAt,
    this.updatedAt,
  });

  factory CompanyWorkRegionModel.fromJson(
      Map<String, dynamic> json,
      ) {
    return CompanyWorkRegionModel(
      id: _asInt(
        json['id'],
      ),

      companyProfileId: _asInt(
        json['company_profile_id'],
      ),

      country: _asString(
        json['country'],
      ),

      state: _asString(
        json['state'],
      ),

      city: _asString(
        json['city'],
      ),

      createdAt: _asDate(
        json['created_at'],
      ),

      updatedAt: _asDate(
        json['updated_at'],
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id':
      id,

      'company_profile_id':
      companyProfileId,

      'country':
      country,

      'state':
      state.isEmpty
          ? null
          : state,

      'city':
      city.isEmpty
          ? null
          : city,

      'created_at':
      createdAt?.toIso8601String(),

      'updated_at':
      updatedAt?.toIso8601String(),
    };
  }

  String get displayLabel {
    final values =
    <String>[
      city,
      state,
      country,
    ].where(
          (value) =>
      value.trim().isNotEmpty,
    ).toList();

    if (values.isEmpty) {
      return 'Region';
    }

    return values.join(
      ', ',
    );
  }
}

// ============================================================================
// HELPERS
// ============================================================================

String _asString(
    dynamic value,
    ) {
  if (value == null) {
    return '';
  }

  return value
      .toString()
      .trim();
}

int? _asInt(
    dynamic value,
    ) {
  if (value == null) {
    return null;
  }

  if (value is int) {
    return value;
  }

  return int.tryParse(
    value.toString(),
  );
}

DateTime? _asDate(
    dynamic value,
    ) {
  if (value == null) {
    return null;
  }

  final text =
  value
      .toString()
      .trim();

  if (text.isEmpty) {
    return null;
  }

  return DateTime.tryParse(
    text,
  );
}