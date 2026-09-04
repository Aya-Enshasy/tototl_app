class AdminUserModel {
  final int id;
  final String name;
  final String email;
  final String username;
  final String status;
  final String phone;
  final DateTime? emailVerifiedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const AdminUserModel({
    required this.id,
    this.name = '',
    this.email = '',
    this.username = '',
    this.status = '',
    this.phone = '',
    this.emailVerifiedAt,
    this.createdAt,
    this.updatedAt,
  });

  factory AdminUserModel.fromJson(Map<String, dynamic> json) {
    return AdminUserModel(
      id: _asInt(json['id']) ?? 0,
      name: _asString(json['name']),
      email: _asString(json['email']),
      username: _asString(json['username']),
      status: _asString(json['status']),
      phone: _asString(json['phone']),
      emailVerifiedAt: _asDate(json['email_verified_at']),
      createdAt: _asDate(json['created_at']),
      updatedAt: _asDate(json['updated_at']),
    );
  }

  String get displayName =>
      name.trim().isEmpty ? 'Unnamed account' : name.trim();

  String get displayUsername {
    final value = username.trim();
    if (value.isEmpty) return 'No username';
    return value.startsWith('@') ? value : '@$value';
  }

  String get displayPhone =>
      phone.trim().isEmpty ? 'Not provided' : phone.trim();

  String get normalizedStatus => status.trim().toLowerCase();

  bool get isPending => normalizedStatus == 'pending';
  bool get isSuspended => normalizedStatus == 'suspended';
  bool get isActive =>
      normalizedStatus == 'active' ||
      normalizedStatus == 'approved' ||
      normalizedStatus == 'verified';

  AdminUserModel copyWith({
    int? id,
    String? name,
    String? email,
    String? username,
    String? status,
    String? phone,
    DateTime? emailVerifiedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AdminUserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      username: username ?? this.username,
      status: status ?? this.status,
      phone: phone ?? this.phone,
      emailVerifiedAt: emailVerifiedAt ?? this.emailVerifiedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

String _asString(dynamic value) =>
    value == null ? '' : value.toString().trim();

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
