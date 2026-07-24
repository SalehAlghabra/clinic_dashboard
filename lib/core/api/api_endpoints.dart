class ApiEndpoints {
  // Auth
  static const String login = '/api/auth/login';
  static const String logout = '/api/auth/logout';
  static const String me = '/api/auth/me';
  static const String createStaff = '/api/auth/create-staff';

  // Dashboard & Reports
  static const String dashboardReport = '/api/reports/dashboard';
  static const String appointmentsReport = '/api/reports/appointments';
  static const String revenueReport = '/api/reports/revenue';
  static const String doctorsReport = '/api/reports/doctors';
  static const String violationsReport = '/api/reports/violations';

  // Core CMS Resources
  static const String doctors = '/api/doctors';
  static String doctorDetail(int id) => '/api/doctors/$id';
  static String doctorSchedules(int doctorId) => '/api/doctors/$doctorId/schedules';
  static String doctorServices(int doctorId) => '/api/doctors/$doctorId/services';

  static const String appointments = '/api/appointments';
  static const String invoices = '/api/invoices';
  static const String settings = '/api/settings';
  
  static String walletDeposit(int userId) => '/api/wallet/deposit/$userId';
}
