import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:tototl_app/core/storage/user_session_storage.dart';

import '../models/pilot_home_snapshot.dart';

class PilotHomeCache {
  PilotHomeCache._();

  static const FlutterSecureStorage _storage = FlutterSecureStorage();
  static const String _prefix = 'pilot_home_snapshot_v2';

  static Future<String?> _key() async {
    final userId = await UserSessionStorage.getUserId();
    if (userId == null || userId <= 0) return null;
    return '${_prefix}_$userId';
  }

  static Future<PilotHomeSnapshot?> read() async {
    try {
      final key = await _key();
      if (key == null) return null;

      final raw = await _storage.read(key: key);
      if (raw == null || raw.trim().isEmpty) return null;

      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;

      return PilotHomeSnapshot.fromJson(
        Map<String, dynamic>.from(decoded),
      );
    } catch (_) {
      return null;
    }
  }

  static Future<void> write(PilotHomeSnapshot snapshot) async {
    try {
      final key = await _key();
      if (key == null) return;

      await _storage.write(
        key: key,
        value: jsonEncode(snapshot.toJson()),
      );
    } catch (_) {
      // Cache failure should never break the home screen.
    }
  }

  static Future<void> clear() async {
    final key = await _key();
    if (key == null) return;
    await _storage.delete(key: key);
  }
}
