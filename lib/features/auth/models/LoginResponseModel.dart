class LoginResponseModel {
  final bool success;
  final String message;
  final LoginDataModel? data;
  final dynamic errors;

  LoginResponseModel({
    required this.success,
    required this.message,
    this.data,
    this.errors,
  });

  factory LoginResponseModel.fromJson(Map<String, dynamic> json) {
    return LoginResponseModel(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null
          ? LoginDataModel.fromJson(json['data'])
          : null,
      errors: json['errors'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'data': data?.toJson(),
      'errors': errors,
    };
  }
}

class LoginDataModel {
  final UserModel user;
  final String role;
  final String token;

  LoginDataModel({
    required this.user,
    required this.role,
    required this.token,
  });

  factory LoginDataModel.fromJson(Map<String, dynamic> json) {
    return LoginDataModel(
      user: UserModel.fromJson(json['user']),
      role: json['role'] ?? '',
      token: json['token'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user': user.toJson(),
      'role': role,
      'token': token,
    };
  }
}

class UserModel {
  final int id;
  final String name;
  final String email;
  final DateTime? emailVerifiedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String username;
  final String status;
  final String? phone;
  final List<RoleModel> roles;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.emailVerifiedAt,
    this.createdAt,
    this.updatedAt,
    required this.username,
    required this.status,
    this.phone,
    required this.roles,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      emailVerifiedAt: json['email_verified_at'] != null
          ? DateTime.tryParse(json['email_verified_at'])
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'])
          : null,
      username: json['username'] ?? '',
      status: json['status'] ?? '',
      phone: json['phone'],
      roles: (json['roles'] as List<dynamic>?)
          ?.map(
            (role) => RoleModel.fromJson(
          role as Map<String, dynamic>,
        ),
      )
          .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'email_verified_at': emailVerifiedAt?.toIso8601String(),
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'username': username,
      'status': status,
      'phone': phone,
      'roles': roles.map((role) => role.toJson()).toList(),
    };
  }
}

class RoleModel {
  final int id;
  final String name;
  final String guardName;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final RolePivotModel? pivot;

  RoleModel({
    required this.id,
    required this.name,
    required this.guardName,
    this.createdAt,
    this.updatedAt,
    this.pivot,
  });

  factory RoleModel.fromJson(Map<String, dynamic> json) {
    return RoleModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      guardName: json['guard_name'] ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'])
          : null,
      pivot: json['pivot'] != null
          ? RolePivotModel.fromJson(json['pivot'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'guard_name': guardName,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'pivot': pivot?.toJson(),
    };
  }
}

class RolePivotModel {
  final String modelType;
  final int modelId;
  final int roleId;

  RolePivotModel({
    required this.modelType,
    required this.modelId,
    required this.roleId,
  });

  factory RolePivotModel.fromJson(Map<String, dynamic> json) {
    return RolePivotModel(
      modelType: json['model_type'] ?? '',
      modelId: json['model_id'] ?? 0,
      roleId: json['role_id'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'model_type': modelType,
      'model_id': modelId,
      'role_id': roleId,
    };
  }
}