import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class UserSessionStorage {
  UserSessionStorage._();

  static const FlutterSecureStorage _storage = FlutterSecureStorage();
  static const String _sessionKey = 'user_session';

  static Future<void> saveSession(Map<String, dynamic> data) async {
    final session = Map<String, dynamic>.from(data);
    session.remove('token');
    await _writeSession(session);
  }

  static Future<Map<String, dynamic>?> getSession() async {
    try {
      final raw = await _storage.read(key: _sessionKey);

      if (raw == null || raw.trim().isEmpty) {
        return null;
      }

      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        return null;
      }

      return Map<String, dynamic>.from(decoded);
    } catch (_) {
      return null;
    }
  }

  static Future<Map<String, dynamic>?> getUser() async {
    final session = await getSession();
    final raw = session?['user'];

    if (raw is! Map) return null;
    return Map<String, dynamic>.from(raw);
  }

  static Future<Map<String, dynamic>?> getProfile() async {
    final session = await getSession();
    final raw = session?['profile'];

    if (raw is! Map) return null;
    return Map<String, dynamic>.from(raw);
  }

  static Future<void> updateUser(Map<String, dynamic> user) async {
    final session = await getSession() ?? <String, dynamic>{};
    session['user'] = Map<String, dynamic>.from(user);
    await _writeSession(session);
  }

  static Future<void> updateProfile(Map<String, dynamic> profile) async {
    final session = await getSession() ?? <String, dynamic>{};
    session['profile'] = Map<String, dynamic>.from(profile);
    await _writeSession(session);
  }

  static Future<void> updateProfilePhotoUrl(String url) async {
    final session = await getSession() ?? <String, dynamic>{};
    session['profile_photo_url'] = url.trim();
    await _writeSession(session);
  }

  static Future<String?> getProfilePhotoUrl() async {
    final session = await getSession();
    final value = session?['profile_photo_url']?.toString().trim();

    if (value == null || value.isEmpty) return null;
    return value;
  }

  static Future<String?> getRole() async {
    final session = await getSession();
    final value = session?['role']?.toString().trim();

    if (value == null || value.isEmpty) return null;
    return value;
  }

  static Future<String?> getStatus() async {
    final user = await getUser();
    final value = user?['status']?.toString().trim();

    if (value == null || value.isEmpty) return null;
    return value;
  }

  static Future<int?> getUserId() async {
    final user = await getUser();
    final value = user?['id'];

    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '');
  }

  static Future<String?> getName() async {
    final user = await getUser();
    final value = user?['name']?.toString().trim();

    if (value == null || value.isEmpty) return null;
    return value;
  }

  static Future<String?> getEmail() async {
    final user = await getUser();
    final value = user?['email']?.toString().trim();

    if (value == null || value.isEmpty) return null;
    return value;
  }

  static Future<void> clearSession() async {
    await _storage.delete(key: _sessionKey);
  }

  static Future<void> _writeSession(Map<String, dynamic> session) async {
    await _storage.write(
      key: _sessionKey,
      value: jsonEncode(session),
    );
  }
}
