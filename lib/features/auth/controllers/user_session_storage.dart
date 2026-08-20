import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class UserSessionStorage {
  UserSessionStorage._();

  static const FlutterSecureStorage _storage =
  FlutterSecureStorage();

  static const String _sessionKey = 'user_session';

  // ============================================================
  // SAVE
  // ============================================================

  static Future<void> saveSession(
      Map<String, dynamic> data,
      ) async {
    final session = Map<String, dynamic>.from(data);

    // التوكن عندنا إله TokenStorage لحاله
    session.remove('token');

    await _storage.write(
      key: _sessionKey,
      value: jsonEncode(session),
    );
  }

  // ============================================================
  // GET FULL SESSION
  // ============================================================

  static Future<Map<String, dynamic>?> getSession() async {
    final value = await _storage.read(
      key: _sessionKey,
    );

    if (value == null || value.isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(value);

      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
    } catch (_) {
      return null;
    }

    return null;
  }

  // ============================================================
  // USER
  // ============================================================

  static Future<Map<String, dynamic>?> getUser() async {
    final session = await getSession();

    final user = session?['user'];

    if (user is Map) {
      return Map<String, dynamic>.from(user);
    }

    return null;
  }

  // ============================================================
  // PROFILE
  // ============================================================

  static Future<Map<String, dynamic>?> getProfile() async {
    final session = await getSession();

    final profile = session?['profile'];

    if (profile is Map) {
      return Map<String, dynamic>.from(profile);
    }

    return null;
  }

  // ============================================================
  // ROLE
  // ============================================================

  static Future<String?> getRole() async {
    final session = await getSession();

    return session?['role']?.toString();
  }

  // ============================================================
  // STATUS
  // ============================================================

  static Future<String?> getStatus() async {
    final user = await getUser();

    return user?['status']?.toString();
  }

  // ============================================================
  // USER ID
  // ============================================================

  static Future<int?> getUserId() async {
    final user = await getUser();

    final value = user?['id'];

    if (value is int) {
      return value;
    }

    return int.tryParse(
      value?.toString() ?? '',
    );
  }

  // ============================================================
  // NAME
  // ============================================================

  static Future<String?> getName() async {
    final user = await getUser();

    return user?['name']?.toString();
  }

  // ============================================================
  // EMAIL
  // ============================================================

  static Future<String?> getEmail() async {
    final user = await getUser();

    return user?['email']?.toString();
  }

  // ============================================================
  // CLEAR
  // ============================================================

  static Future<void> clearSession() async {
    await _storage.delete(
      key: _sessionKey,
    );
  }
}