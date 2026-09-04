class AdminAccountModel {
  final int? id;
  final String name;
  final String email;
  final String username;
  final String phone;
  final String status;
  final String role;

  const AdminAccountModel({
    this.id,
    this.name = '',
    this.email = '',
    this.username = '',
    this.phone = '',
    this.status = '',
    this.role = '',
  });

  factory AdminAccountModel.fromJson(Map<String, dynamic> json) {
    return AdminAccountModel(
      id: _asInt(json['id']),
      name: _asString(json['name']),
      email: _asString(json['email']),
      username: _asString(json['username']),
      phone: _asString(json['phone']),
      status: _asString(json['status']),
      role: _asString(
        json['role'] ??
            json['user_type'] ??
            json['type'],
      ),
    );
  }

  String get displayName {
    final value = name.trim();
    return value.isEmpty ? 'Administrator' : value;
  }

  String get displayUsername {
    final value = username.trim();
    if (value.isEmpty) return 'Admin account';
    return value.startsWith('@') ? value : '@$value';
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
