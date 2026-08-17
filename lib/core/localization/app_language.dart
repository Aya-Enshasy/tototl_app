import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppLanguage {
  AppLanguage._();

  static final ValueNotifier<Locale> locale = ValueNotifier(const Locale('en'));
  static const supportedCodes = ['en', 'ar', 'de'];

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    locale.value = Locale(prefs.getString('app_language') ?? 'en');
  }

  static Future<void> set(String code) async {
    locale.value = Locale(code);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_language', code);
  }

  static String t(String key) => _values[locale.value.languageCode]?[key] ??
      _values['en']![key] ??
      key;

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
