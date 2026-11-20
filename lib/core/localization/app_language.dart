import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'generated_ui_translations.dart';

class AppLanguage {
  AppLanguage._();

  static final ValueNotifier<Locale> locale = ValueNotifier(const Locale('en'));
  static const supportedCodes = ['en', 'ar', 'de'];

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('app_language') ?? 'en';
    locale.value = Locale(supportedCodes.contains(saved) ? saved : 'en');
  }

  static Future<void> set(String code) async {
    final safeCode = supportedCodes.contains(code) ? code : 'en';
    locale.value = Locale(safeCode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_language', safeCode);
  }

  static String t(String key) => _values[locale.value.languageCode]?[key] ??
      _values['en']![key] ??
      key;

  /// Translates static interface copy while retaining English as the source
  /// language and a safe fallback for content received from the server.
  static String text(String source) {
    final code = locale.value.languageCode;
    if (source.trim().isEmpty) return source;

    // Friendly labels for backend capability enum values. This is display-only;
    // multipart form and query values are always handled by DroneCapabilities.
    const capabilityNames = <String, String>{
      'thermal': 'Thermal Camera',
      'laser': 'Laser',
      'night_vision': 'Night Vision',
      'lidar': 'LiDAR',
      'radar': 'Radar',
      'imaging': 'Imaging',
      'rtk': 'RTK',
      'zoom': 'Zoom',
      'other': 'Other',
    };
    final readable = capabilityNames[source] ?? source;
    if (code == 'en') return readable;

    final exact = generatedUiTranslations[code]?[readable];
    if (exact != null) return exact;

    // Small dynamic UI patterns used by registration pickers/progress labels.
    final years = RegExp(r'^(\d+) years?$').firstMatch(source);
    if (years != null) {
      final n = years.group(1)!;
      if (code == 'ar') return '$n سنة';
      if (code == 'de') return '$n ${n == '1' ? 'Jahr' : 'Jahre'}';
    }

    final selected = RegExp(r'^(\d+) selected$', caseSensitive: false).firstMatch(source);
    if (selected != null) {
      final n = selected.group(1)!;
      if (code == 'ar') return 'تم اختيار $n';
      if (code == 'de') return '$n ausgewählt';
    }

    final cities = RegExp(r'^(\d+) cities$', caseSensitive: false).firstMatch(source);
    if (cities != null) {
      final n = cities.group(1)!;
      if (code == 'ar') return '$n مدينة';
      if (code == 'de') return '$n Städte';
    }

    final upload = RegExp(r'^Uploading (\d+)%$').firstMatch(source);
    if (upload != null) {
      final n = upload.group(1)!;
      if (code == 'ar') return 'جارٍ الرفع $n%';
      if (code == 'de') return 'Wird hochgeladen $n%';
    }

    final jobsFound = RegExp(r'^(\d+) jobs found$').firstMatch(source);
    if (jobsFound != null) {
      final n = jobsFound.group(1)!;
      if (code == 'ar') return 'تم العثور على $n وظيفة';
      if (code == 'de') return '$n Aufträge gefunden';
    }

    final jobPostingLimit = RegExp(r'^Job postings: (.+)$').firstMatch(source);
    if (jobPostingLimit != null) {
      if (code == 'ar') return 'الوظائف المنشورة: ${jobPostingLimit.group(1)}';
      if (code == 'de') return 'Aufträge: ${jobPostingLimit.group(1)}';
    }

    final pilotApplications = RegExp(r'^Pilot applications: (.+)$').firstMatch(source);
    if (pilotApplications != null) {
      if (code == 'ar') return 'طلبات الطيار: ${pilotApplications.group(1)}';
      if (code == 'de') return 'Pilotenbewerbungen: ${pilotApplications.group(1)}';
    }

    final currentStatus = RegExp(r'^Status: (.+)$').firstMatch(source);
    if (currentStatus != null) {
      if (code == 'ar') return 'الحالة: ${currentStatus.group(1)}';
      if (code == 'de') return 'Status: ${currentStatus.group(1)}';
    }

    return readable;
  }

  static const _values = {
    'en': {
      'settings': 'Settings', 'profile': 'Profile', 'updateProfile': 'Update profile',
      'notifications': 'Notifications', 'jobUpdates': 'Job recommendations',
      'applicationUpdates': 'Application updates', 'emailUpdates': 'Email updates',
      'account': 'Account', 'changePassword': 'Change password', 'privacy': 'Privacy controls',
      'language': 'Language', 'about': 'About', 'saveChanges': 'Save changes',
      'saved': 'Changes saved successfully', 'currentPassword': 'Current password',
      'newPassword': 'New password', 'confirmPassword': 'Confirm new password',
      'passwordChanged': 'Password changed successfully', 'personalInfo': 'Personal information',
      'fullName': 'Full name', 'email': 'Email', 'phone': 'Phone', 'location': 'Location',
      'appLanguage': 'App language', 'selectLanguage': 'Select your preferred language',
      'privacyText': 'Manage how your profile and information are shared.',
      'publicProfile': 'Public profile', 'showEmail': 'Show email address',
      'aboutText': 'TOTOTL INTGRX connects skilled drone pilots with companies that need reliable aerial services.',
      'version': 'Version', 'back': 'Back', 'security': 'Password & security',
    },
    'ar': {
      'settings': 'الإعدادات', 'profile': 'الملف الشخصي', 'updateProfile': 'تعديل الملف الشخصي',
      'notifications': 'الإشعارات', 'jobUpdates': 'توصيات الوظائف', 'applicationUpdates': 'تحديثات الطلبات',
      'emailUpdates': 'تحديثات البريد الإلكتروني', 'account': 'الحساب', 'changePassword': 'تغيير كلمة المرور',
      'privacy': 'الخصوصية', 'language': 'اللغة', 'about': 'حول التطبيق', 'saveChanges': 'حفظ التغييرات',
      'saved': 'تم حفظ التغييرات بنجاح', 'currentPassword': 'كلمة المرور الحالية',
      'newPassword': 'كلمة المرور الجديدة', 'confirmPassword': 'تأكيد كلمة المرور الجديدة',
      'passwordChanged': 'تم تغيير كلمة المرور بنجاح', 'personalInfo': 'المعلومات الشخصية',
      'fullName': 'الاسم الكامل', 'email': 'البريد الإلكتروني', 'phone': 'رقم الهاتف', 'location': 'الموقع',
      'appLanguage': 'لغة التطبيق', 'selectLanguage': 'اختر لغتك المفضلة',
      'privacyText': 'تحكم في كيفية مشاركة ملفك الشخصي ومعلوماتك.', 'publicProfile': 'ملف شخصي عام',
      'showEmail': 'إظهار عنوان البريد الإلكتروني',
      'aboutText': 'توتوتل إنتجركس تربط طياري الدرون المحترفين بالشركات التي تحتاج إلى خدمات جوية موثوقة.',
      'version': 'الإصدار', 'back': 'رجوع', 'security': 'كلمة المرور والأمان',
    },
    'de': {
      'settings': 'Einstellungen', 'profile': 'Profil', 'updateProfile': 'Profil bearbeiten',
      'notifications': 'Benachrichtigungen', 'jobUpdates': 'Jobempfehlungen', 'applicationUpdates': 'Bewerbungsupdates',
      'emailUpdates': 'E-Mail-Updates', 'account': 'Konto', 'changePassword': 'Passwort ändern',
      'privacy': 'Datenschutz', 'language': 'Sprache', 'about': 'Über die App', 'saveChanges': 'Änderungen speichern',
      'saved': 'Änderungen wurden gespeichert', 'currentPassword': 'Aktuelles Passwort',
      'newPassword': 'Neues Passwort', 'confirmPassword': 'Neues Passwort bestätigen',
      'passwordChanged': 'Passwort wurde geändert', 'personalInfo': 'Persönliche Informationen',
      'fullName': 'Vollständiger Name', 'email': 'E-Mail', 'phone': 'Telefon', 'location': 'Standort',
      'appLanguage': 'App-Sprache', 'selectLanguage': 'Wähle deine bevorzugte Sprache',
      'privacyText': 'Lege fest, wie dein Profil und deine Daten geteilt werden.', 'publicProfile': 'Öffentliches Profil',
      'showEmail': 'E-Mail-Adresse anzeigen',
      'aboutText': 'TOTOTL INTGRX verbindet qualifizierte Drohnenpiloten mit Unternehmen für zuverlässige Luftservices.',
      'version': 'Version', 'back': 'Zurück', 'security': 'Passwort und Sicherheit',
    },
  };
}
