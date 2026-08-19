class ApiEndpoints {
  ApiEndpoints._();

  // Base URL
  static const String baseUrl = 'https://tototl.abdullahdheir.dev/api/v1';

  // Auth
  static const String login = '/auth/login';
  static const String pilotRegister = '/auth/register/pilot';
  static const String logout = '/auth/logout';
  static const String me = '/auth/me';

  // Password
  static const String forgotPassword = '/auth/forgot-password';
  static const String verifyOtp = '/auth/verify-otp';
  static const String resetPassword = '/auth/reset-password';
  static const String changePassword = '/auth/change-password';

// مثال:
// static const String profile = '/profile';
// static const String notifications = '/notifications';
}