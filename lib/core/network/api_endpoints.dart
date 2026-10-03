class ApiEndpoints {
  ApiEndpoints._();

  // Base URL
  static const String baseUrl =
      'https://tototl.abdullahdheir.dev/api/v1';

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
  static const String fcmTokenRefresh = '/fcm-token/refresh';

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
  // CONTRACTS
  // ==========================================================================

  /// GET /contracts
  static const String contracts = '/contracts';

  /// GET /contracts/{contract}
  static String contract(int contractId) {
    return '/contracts/$contractId';
  }

  /// POST /contracts/{contract}/accept
  static String acceptContract(int contractId) {
    return '/contracts/$contractId/accept';
  }

  /// POST /contracts/{contract}/reject
  static String rejectContract(int contractId) {
    return '/contracts/$contractId/reject';
  }

  /// POST /contracts/{contract}/start-work
  static String startContractWork(int contractId) {
    return '/contracts/$contractId/start-work';
  }

  /// GET /contracts/{contract}/location
  static String contractLocation(int contractId) {
    return '/contracts/$contractId/location';
  }

  /// GET /contracts/{contract}/submissions
  /// POST /contracts/{contract}/submissions
  static String contractSubmissions(int contractId) {
    return '/contracts/$contractId/submissions';
  }

  /// GET /contracts/{contract}/submissions/{submission}
  static String contractSubmission(
    int contractId,
    int submissionId,
  ) {
    return '/contracts/$contractId/submissions/$submissionId';
  }

  // ==========================================================================
  // COMPANY CONTRACTS
  // ==========================================================================

  static const String companyContracts = '/company/contracts';

  static String companyContract(int contractId) {
    return '/company/contracts/$contractId';
  }

  static String fundCompanyContract(int contractId) {
    return '/company/contracts/$contractId/fund';
  }

  static String cancelCompanyContract(int contractId) {
    return '/company/contracts/$contractId/cancel';
  }

  static String terminateCompanyContract(int contractId) {
    return '/company/contracts/$contractId/terminate';
  }

  static String companyContractLocation(int contractId) {
    return '/company/contracts/$contractId/location';
  }

  static String companyContractSubmissions(int contractId) {
    return '/company/contracts/$contractId/submissions';
  }

  static String companyContractSubmission(
    int contractId,
    int submissionId,
  ) {
    return '/company/contracts/$contractId/submissions/$submissionId';
  }

  static String approveCompanyContractSubmission(
    int contractId,
    int submissionId,
  ) {
    return '/company/contracts/$contractId/submissions/$submissionId/approve';
  }

  static String requestRevisionCompanyContractSubmission(
    int contractId,
    int submissionId,
  ) {
    return '/company/contracts/$contractId/submissions/$submissionId/request-revision';
  }



  // ==========================================================================
  // PAYMENTS
  // ==========================================================================

  /// GET /payments
  static const String payments = '/payments';

  /// GET /payments/{payment}
  static String payment(int paymentId) {
    return '/payments/$paymentId';
  }

  /// GET /company/payments
  static const String companyPayments = '/company/payments';

  /// GET /company/payments/{payment}
  static String companyPayment(int paymentId) {
    return '/company/payments/$paymentId';
  }

  // ==========================================================================
  // SUBSCRIPTIONS
  // ==========================================================================

  /// GET /subscription-plans
  static const String subscriptionPlans = '/subscription-plans';

  /// GET /subscription
  static const String currentSubscription = '/subscription';

  /// POST /subscriptions
  static const String subscriptions = '/subscriptions';

  /// POST /subscriptions/{subscription}/cancel
  static String cancelSubscription(int subscriptionId) {
    return '/subscriptions/$subscriptionId/cancel';
  }

  /// POST /subscriptions/{subscription}/change-plan
  static String changeSubscriptionPlan(int subscriptionId) {
    return '/subscriptions/$subscriptionId/change-plan';
  }

  /// GET /subscriptions/history
  static const String subscriptionHistory = '/subscriptions/history';

  /// GET /subscription-payments
  static const String subscriptionPayments = '/subscription-payments';

  // ==========================================================================
  // ADMIN
  // ==========================================================================

  static const String adminPendingPilots = '/admin/pilots/pending';
  static const String adminPendingCompanies = '/admin/companies/pending';

  /// GET /admin/companies
  /// Supports: search, status, per_page, page
  static const String adminCompanies = '/admin/companies';

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

  static const String pilotLicenses = '/pilot-licenses';

  static String pilotLicense(int licenseId) {
    return '/pilot-licenses/$licenseId';
  }

  static const String pilotDashboard = '/dashboard';
  static const String companyDashboard = '/company/dashboard';
}
