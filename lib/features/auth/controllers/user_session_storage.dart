import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// ============================================================================
// USER SESSION STORAGE
// ============================================================================

class UserSessionStorage {
  UserSessionStorage._();

  static const FlutterSecureStorage
  _storage =
  FlutterSecureStorage();

  static const String _sessionKey =
      'user_session';

  // ==========================================================================
  // SAVE SESSION
  // ==========================================================================

  static Future<void> saveSession(
      Map<String, dynamic> data,
      ) async {
    final session =
    Map<String, dynamic>.from(
      data,
    );

    // Token is stored separately
    // inside TokenStorage.
    session.remove(
      'token',
    );

    await _writeSession(
      session,
    );
  }

  // ==========================================================================
  // GET SESSION
  // ==========================================================================

  static Future<Map<String, dynamic>?>
  getSession() async {
    try {
      final raw =
      await _storage.read(
        key:
        _sessionKey,
      );

      if (raw == null ||
          raw.trim().isEmpty) {
        return null;
      }

      final decoded =
      jsonDecode(
        raw,
      );

      if (decoded is! Map) {
        return null;
      }

      return Map<String, dynamic>.from(
        decoded,
      );
    } catch (_) {
      return null;
    }
  }

  // ==========================================================================
  // USER
  // ==========================================================================

  static Future<Map<String, dynamic>?>
  getUser() async {
    final session =
    await getSession();

    final raw =
    session?['user'];

    if (raw is! Map) {
      return null;
    }

    return Map<String, dynamic>.from(
      raw,
    );
  }

  // ==========================================================================
  // PROFILE
  // ==========================================================================

  static Future<Map<String, dynamic>?>
  getProfile() async {
    final session =
    await getSession();

    final raw =
    session?['profile'];

    if (raw is! Map) {
      return null;
    }

    return Map<String, dynamic>.from(
      raw,
    );
  }

  // ==========================================================================
  // UPDATE USER
  // ==========================================================================

  static Future<void> updateUser(
      Map<String, dynamic> user,
      ) async {
    final session =
        await getSession() ??
            <String, dynamic>{};

    session['user'] =
    Map<String, dynamic>.from(
      user,
    );

    await _writeSession(
      session,
    );
  }

  // ==========================================================================
  // UPDATE PROFILE
  // ==========================================================================

  static Future<void> updateProfile(
      Map<String, dynamic> profile,
      ) async {
    final session =
        await getSession() ??
            <String, dynamic>{};

    session['profile'] =
    Map<String, dynamic>.from(
      profile,
    );

    await _writeSession(
      session,
    );
  }

  // ==========================================================================
  // MERGE PROFILE
  //
  // Important:
  // GET /company/profile might not return profile_photo.
  // So we merge the fresh response with the cached profile instead
  // of deleting fields that already exist locally.
  // ==========================================================================

  static Future<void> mergeProfile(
      Map<String, dynamic> profile,
      ) async {
    final session =
        await getSession() ??
            <String, dynamic>{};

    final oldRaw =
    session['profile'];

    final merged =
    oldRaw is Map
        ? Map<String, dynamic>.from(
      oldRaw,
    )
        : <String, dynamic>{};

    merged.addAll(
      Map<String, dynamic>.from(
        profile,
      ),
    );

    session['profile'] =
        merged;

    await _writeSession(
      session,
    );
  }


  // ==========================================================================
  // PROFILE PHOTO URL
  // ==========================================================================

  static Future<void>
  updateProfilePhotoUrl(
      String url,
      ) async {
    final clean =
    url.trim();

    final session =
        await getSession() ??
            <String, dynamic>{};

    session['profile_photo_url'] =
        clean;

    await _writeSession(
      session,
    );
  }

  static Future<String?>
  getProfilePhotoUrl() async {
    final session =
    await getSession();

    // First:
    // explicit locally stored photo.
    final direct =
    session?['profile_photo_url']
        ?.toString()
        .trim();

    if (direct != null &&
        direct.isNotEmpty) {
      return direct;
    }

    // Second:
    // photo returned inside profile during registration/login.
    final rawProfile =
    session?['profile'];

    if (rawProfile is Map) {
      final value =
      rawProfile['profile_photo']
          ?.toString()
          .trim();

      if (value != null &&
          value.isNotEmpty) {
        return value;
      }
    }

    return null;
  }

  // ==========================================================================
  // ROLE
  // ==========================================================================

  static Future<String?>
  getRole() async {
    final session =
    await getSession();

    final value =
    session?['role']
        ?.toString()
        .trim();

    if (value == null ||
        value.isEmpty) {
      return null;
    }

    return value;
  }

  // ==========================================================================
  // STATUS
  // ==========================================================================

  static Future<String?>
  getStatus() async {
    final user =
    await getUser();

    final value =
    user?['status']
        ?.toString()
        .trim();

    if (value == null ||
        value.isEmpty) {
      return null;
    }

    return value;
  }

  // ==========================================================================
  // USER ID
  // ==========================================================================

  static Future<int?>
  getUserId() async {
    final user =
    await getUser();

    final value =
    user?['id'];

    if (value is int) {
      return value;
    }

    return int.tryParse(
      value?.toString() ??
          '',
    );
  }

  // ==========================================================================
  // NAME
  // ==========================================================================

  static Future<String?>
  getName() async {
    final user =
    await getUser();

    final value =
    user?['name']
        ?.toString()
        .trim();

    if (value == null ||
        value.isEmpty) {
      return null;
    }

    return value;
  }

  // ==========================================================================
  // EMAIL
  // ==========================================================================

  static Future<String?>
  getEmail() async {
    final user =
    await getUser();

    final value =
    user?['email']
        ?.toString()
        .trim();

    if (value == null ||
        value.isEmpty) {
      return null;
    }

    return value;
  }

  // ==========================================================================
  // CLEAR
  // ==========================================================================

  static Future<void>
  clearSession() async {
    await _storage.delete(
      key:
      _sessionKey,
    );
  }

  // ==========================================================================
  // PRIVATE WRITE
  // ==========================================================================

  static Future<void> _writeSession(
      Map<String, dynamic> session,
      ) async {
    await _storage.write(
      key:
      _sessionKey,

      value:
      jsonEncode(
        session,
      ),
    );
  }



}