class PilotContractLocationModel {
  final int id;
  final int contractId;
  final String address;
  final double latitude;
  final double longitude;
  final String notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const PilotContractLocationModel({
    required this.id,
    required this.contractId,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PilotContractLocationModel.fromJson(Map<String, dynamic> json) {
    return PilotContractLocationModel(
      id: _asInt(json['id']) ?? 0,
      contractId: _asInt(json['contract_id']) ?? 0,
      address: _asString(json['address']),
      latitude: _asDouble(json['latitude']) ?? 0,
      longitude: _asDouble(json['longitude']) ?? 0,
      notes: _asString(json['notes']),
      createdAt: _asDate(json['created_at']),
      updatedAt: _asDate(json['updated_at']),
    );
  }

  String get coordinatesLabel =>
      '${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}';
}

String _asString(dynamic value) => value == null ? '' : value.toString().trim();
int? _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '');
}
double? _asDouble(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '');
}
DateTime? _asDate(dynamic value) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? null : DateTime.tryParse(text);
}
