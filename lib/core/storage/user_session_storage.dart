import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// ============================================================================
// USER SESSION STORAGE
// ============================================================================

class UserSessionStorage {
  UserSessionStorage._();

  static const FlutterSecureStorage _storage =
  FlutterSecureStorage();

  static const String _sessionKey =
      'user_session';

  // ==========================================================================
  // SESSION REVISION
  //
  // أي تغيير في بيانات المستخدم أو البروفايل أو الصورة
  // يزيد هذا الرقم.
  //
  // الشاشات مثل Company Home تستطيع الاستماع له:
  //
  // UserSessionStorage.revision.addListener(...)
  //
  // وبذلك تتحدث البيانات فوراً بدون Restart أو Refresh يدوي.
  // ==========================================================================

  static final ValueNotifier<int> revision =
  ValueNotifier<int>(0);

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
        key: _sessionKey,
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
  //
  // يستخدم عندما نريد استبدال بيانات البروفايل كاملة.
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
  // مهم جداً:
  //
  // بعض endpoints قد لا ترجع كل حقول البروفايل.
  //
  // مثال:
  // GET /company/profile
  // ممكن لا يرجع profile_photo أو بعض work_regions.
  //
  // لذلك لا نستبدل البروفايل القديم بالكامل.
  // ندمج الجديد فوق القديم.
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

    // ------------------------------------------------------------------------
    // 1. الصورة المخزنة مباشرة في session
    // ------------------------------------------------------------------------

    final direct =
    session?['profile_photo_url']
        ?.toString()
        .trim();

    if (direct != null &&
        direct.isNotEmpty) {
      return direct;
    }

    // ------------------------------------------------------------------------
    // 2. الصورة الموجودة داخل profile
    // ------------------------------------------------------------------------

    final rawProfile =
    session?['profile'];

    if (rawProfile is Map) {
      final profile =
      Map<String, dynamic>.from(
        rawProfile,
      );

      final profilePhoto =
      profile['profile_photo']
          ?.toString()
          .trim();

      if (profilePhoto != null &&
          profilePhoto.isNotEmpty) {
        return profilePhoto;
      }

      // بعض responses تستخدم profile_photo_url
      final alternatePhoto =
      profile['profile_photo_url']
          ?.toString()
          .trim();

      if (alternatePhoto != null &&
          alternatePhoto.isNotEmpty) {
        return alternatePhoto;
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
      key: _sessionKey,
    );

    // حتى أي شاشة تستمع للـsession تعرف أن الحساب تم مسحه.
    _notifyChanged();
  }

  // ==========================================================================
  // PRIVATE WRITE
  //
  // جميع عمليات تعديل الـsession تمر من هنا.
  //
  // لذلك أي تعديل:
  // - Login
  // - Register
  // - Update profile
  // - Profile photo
  // - Account update
  //
  // سيؤدي تلقائياً لإشعار الشاشات المستمعة.
  // ==========================================================================

  static Future<void> _writeSession(
      Map<String, dynamic> session,
      ) async {
    await _storage.write(
      key: _sessionKey,
      value: jsonEncode(
        session,
      ),
    );

    _notifyChanged();
  }

  // ==========================================================================
  // NOTIFY
  // ==========================================================================

  static void _notifyChanged() {
    revision.value =
        revision.value + 1;
  }
}