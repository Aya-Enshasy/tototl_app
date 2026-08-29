class ApiEndpoints {
  ApiEndpoints._();

  // Base URL
  static const String baseUrl = 'https://tototl.abdullahdheir.dev/api/v1';

  // Auth
  static const String login = '/auth/login';
  static const String pilotRegister = '/auth/register/pilot';
  static const String companyRegister = '/auth/register/company';
  static const String logout = '/auth/logout';
  static const String me = '/auth/me';
  static const String pilotProfile = '/pilot/profile';
  static const String  editPilotProfile = '/pilot/profile';
  static const String profileDocuments = '/profile/documents';
  static const String companyProfile = '/company/profile';

  // Password
  static const String forgotPassword = '/auth/password/forgot';


  //drones
  static const String drones =
      '/drones';
  /// GET    /drones/{id}
  /// PATCH  /drones/{id}
  /// DELETE /drones/{id}
  static String drone(int droneId,) {return '/drones/$droneId';}
}