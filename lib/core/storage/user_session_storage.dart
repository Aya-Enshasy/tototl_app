import 'dart:async';
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

  // Last known profile snapshot, encrypted and isolated per account. The
  // snapshot is a display cache; authentication/permissions always come from
  // the current token and server, never this local data.
  static const String _profileSnapshotPrefix = 'tototl_profile_snapshot_v2_';

  static int? _sessionOwner(Map<String, dynamic> session) {
    final rawUser = session['user'];
    if (rawUser is! Map) return null;
    final rawId = rawUser['id'];
    return rawId is int ? rawId : int.tryParse('$rawId');
  }

  static Future<Map<String, dynamic>?> _profileSnapshotFor(int owner) async {
    try {
      final raw = await _storage.read(key: '$_profileSnapshotPrefix$owner');
      if (raw == null) return null;
      final decoded = jsonDecode(raw);
      if (decoded is! Map || decoded['owner'] != owner ||
          decoded['profile'] is! Map) return null;
      return Map<String, dynamic>.from(decoded);
    } catch (_) {
      return null;
    }
  }

  // Secure storage is the durable copy; memory gives instant subsequent reads.
  // A single in-flight read prevents three independent encrypted-store reads
  // when Profile needs account, profile and photo at the same time.
  static Map<String, dynamic>? _memorySession;
  static bool _cacheReady = false;
  static Future<Map<String, dynamic>?>? _readInFlight;
  static Future<void> _writeTail = Future<void>.value();

  static Future<void> _serializeWrite(Future<void> Function() operation) {
    final operationFuture = _writeTail.then((_) => operation());
    _writeTail = operationFuture.then<void>((_) {},
        onError: (Object error, StackTrace stack) {});
    return operationFuture;
  }


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

    await _serializeWrite(() async {
      final owner = _sessionOwner(session);
      final rawProfile = session['profile'];
      if (owner != null && owner > 0) {
        // Re-login with an existing account should show its own complete
        // snapshot before GET /me, even if login returned a partial profile.
        // Fresh keys (including explicit nulls) take precedence.
        final snapshot = await _profileSnapshotFor(owner);
        if (snapshot != null) {
          final combined = Map<String, dynamic>.from(snapshot['profile']);
          if (rawProfile is Map) {
            combined.addAll(Map<String, dynamic>.from(rawProfile));
          }
          session['profile'] = combined;
          final photo = snapshot['profile_photo_url'];
          final currentPhoto = session['profile_photo_url'];
          if ((currentPhoto == null || '$currentPhoto'.isEmpty) &&
              photo is String && photo.isNotEmpty) {
            session['profile_photo_url'] = photo;
          }
        }
      }
      await _writeSession(session);
    });
  }

  // ==========================================================================
  // GET SESSION
  // ==========================================================================

  static Future<Map<String, dynamic>?> getSession() async {
    if (_cacheReady) {
      final cached = _memorySession;
      return cached == null ? null : Map<String, dynamic>.from(cached);
    }
    final running = _readInFlight;
    if (running != null) {
      final result = await running;
      return result == null ? null : Map<String, dynamic>.from(result);
    }
    final task = _readSessionFromDisk();
    _readInFlight = task;
    try {
      final result = await task;
      return result == null ? null : Map<String, dynamic>.from(result);
    } finally {
      if (identical(_readInFlight, task)) _readInFlight = null;
    }
  }

  static Future<Map<String, dynamic>?> _readSessionFromDisk() async {
    Map<String, dynamic>? result;
    try {
      final raw = await _storage.read(key: _sessionKey);
      if (raw != null && raw.trim().isNotEmpty) {
        final decoded = jsonDecode(raw);
        if (decoded is Map) result = Map<String, dynamic>.from(decoded);
      }
    } catch (_) {
      // Allow an API refresh after an encrypted-storage read failure.
    }
    // A login/logout may have written a newer session while disk was read.
    if (!_cacheReady) {
      _memorySession = result;
      _cacheReady = true;
    }
    return _memorySession;
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
    return _serializeWrite(() async {
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
    });
  }

  // ==========================================================================
  // UPDATE PROFILE
  //
  // يستخدم عندما نريد استبدال بيانات البروفايل كاملة.
  // ==========================================================================

  static Future<void> updateProfile(
      Map<String, dynamic> profile,
      ) async {
    return _serializeWrite(() async {
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
    });
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
    return _serializeWrite(() async {
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
    });
  }

  // ==========================================================================
  // PROFILE PHOTO URL
  // ==========================================================================

  static Future<void>
  updateProfilePhotoUrl(
      String url,
      ) async {
    return _serializeWrite(() async {
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
    });
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
    return _serializeWrite(() async {
    await _storage.delete(key: _sessionKey);
    _memorySession = null;
    _cacheReady = true;
    _notifyChanged();
    });
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
      value: jsonEncode(session),
    );

    // Persist the full profile (including optional fields such as work
    // regions, licenses and drones returned within /me) for a fast first
    // paint, even after a fresh login. This data must never be used for auth.
    final owner = _sessionOwner(session);
    final profile = session['profile'];
    if (owner != null && owner > 0 && profile is Map && profile.isNotEmpty) {
      try {
        await _storage.write(
          key: '$_profileSnapshotPrefix$owner',
          value: jsonEncode({
            'owner': owner,
            'profile': profile,
            'profile_photo_url': session['profile_photo_url'] ?? '',
          }),
        );
      } catch (_) {
        // If the optional cache fails, a successful account update must
        // still succeed. /me will refresh it again when connectivity returns.
      }
    }

    _memorySession = Map<String, dynamic>.from(session);
    _cacheReady = true;
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