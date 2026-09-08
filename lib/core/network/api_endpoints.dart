class ApiEndpoints {
  ApiEndpoints._();

  // Base URL
  static const String baseUrl = 'https://tototl.abdullahdheir.dev/api/v1';

  // Auth
  static const String login = '/auth/login';
  static const String pilotRegister = '/auth/register/pilot';
  static const String companyRegister = '/auth/register/company';
  static const String logout = '/auth/logout';
  static const String me = '/me';
  static const String pilotProfile = '/pilot/profile';
  static const String editPilotProfile = '/pilot/profile';
  static const String profileDocuments = '/profile/documents';
  static const String companyProfile = '/company/profile';

  // Password
  static const String forgotPassword = '/auth/password/forgot';

  // Drones
  static const String drones = '/drones';

  /// GET    /drones/{id}
  /// PATCH  /drones/{id}
  /// DELETE /drones/{id}
  static String drone(int droneId) {
    return '/drones/$droneId';
  }

  // ==========================================================================
  // COMPANY JOBS
  // ==========================================================================

  /// GET  /company/job-postings
  /// POST /company/job-postings
  static const String companyJobPostings = '/company/job-postings';

  /// POST /company/job-postings/{id}/publish
  static String publishCompanyJob(int jobId) {
    return '/company/job-postings/$jobId/publish';
  }

  // ==========================================================================
  // ADMIN
  // ==========================================================================

  static const String adminPendingPilots = '/admin/pilots/pending';

  static const String adminPendingCompanies = '/admin/companies/pending';

  // ==========================================================================
  // ADMIN - VERIFICATION ACTIONS
  // ==========================================================================

  static String adminApproveUser(int userId) {
    return '/admin/users/$userId/approve';
  }

  static String adminRejectUser(int userId) {
    return '/admin/users/$userId/reject';
  }

  static String adminSuspendUser(int userId) {
    return '/admin/users/$userId/suspend';
  }

  static String adminReactivateUser(int userId) {
    return '/admin/users/$userId/reactivate';
  }

  static String adminVerificationHistory(int userId) {
    return '/admin/users/$userId/verification-history';
  }
}
