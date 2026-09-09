import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:tototl_app/core/storage/user_session_storage.dart';

import '../models/pilot_availability_preference.dart';

class PilotAvailabilityLocalStore {
  PilotAvailabilityLocalStore._();

  static const FlutterSecureStorage _storage = FlutterSecureStorage();
  static const String _prefix = 'pilot_availability_local_v1';

  static Future<String?> _key() async {
    final userId = await UserSessionStorage.getUserId();
    if (userId == null || userId <= 0) return null;
    return '${_prefix}_$userId';
  }

  static Future<PilotAvailabilityPreference> read() async {
    try {
      final key = await _key();
      if (key == null) return const PilotAvailabilityPreference();

      final raw = await _storage.read(key: key);
      if (raw == null || raw.trim().isEmpty) {
        return const PilotAvailabilityPreference();
      }

      final decoded = jsonDecode(raw);
      if (decoded is! Map) return const PilotAvailabilityPreference();

      return PilotAvailabilityPreference.fromJson(
        Map<String, dynamic>.from(decoded),
      );
    } catch (_) {
      return const PilotAvailabilityPreference();
    }
  }

  static Future<void> write(PilotAvailabilityPreference value) async {
    final key = await _key();
    if (key == null) return;

    await _storage.write(
      key: key,
      value: jsonEncode(value.toJson()),
    );
  }

  static Future<void> clear() async {
    final key = await _key();
    if (key == null) return;
    await _storage.delete(key: key);
  }
}
