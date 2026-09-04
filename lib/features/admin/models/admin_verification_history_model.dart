class AdminVerificationHistoryModel {
  final int id;
  final int userId;
  final int adminId;
  final String action;
  final String reason;
  final DateTime? createdAt;

  const AdminVerificationHistoryModel({
    required this.id,
    required this.userId,
    required this.adminId,
    this.action = '',
    this.reason = '',
    this.createdAt,
  });

  factory AdminVerificationHistoryModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return AdminVerificationHistoryModel(
      id: _asInt(json['id']) ?? 0,
      userId: _asInt(json['user_id']) ?? 0,
      adminId: _asInt(json['admin_id']) ?? 0,
      action: _asString(json['action']),
      reason: _asString(json['reason']),
      createdAt: _asDate(json['created_at']),
    );
  }

  String get normalizedAction => action.trim().toLowerCase();
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
