import 'package:intl/intl.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_endpoints.dart';
import '../models/dashboard_stats.dart';
import '../models/reports_models.dart';

class DashboardRepository {
  final ApiClient _apiClient;

  DashboardRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  Future<DashboardStats> fetchDashboardStats() async {
    final response = await _apiClient.get(ApiEndpoints.dashboardReport);
    return DashboardStats.fromJson(response.data);
  }

  Future<List<AppointmentReportItem>> fetchAppointmentsReport({
    String? from,
    String? to,
  }) async {
    final now = DateTime.now();
    final startDate = from ?? DateFormat('yyyy-MM-01').format(now);
    final endDate = to ?? DateFormat('yyyy-MM-dd').format(now);

    final response = await _apiClient.get(
      ApiEndpoints.appointmentsReport,
      queryParameters: {'from': startDate, 'to': endDate},
    );

    final List data = response.data['data'] ?? [];
    return data.map((e) => AppointmentReportItem.fromJson(e)).toList();
  }

  Future<List<InvoiceReportItem>> fetchRevenueReport({
    String? from,
    String? to,
  }) async {
    final now = DateTime.now();
    final startDate = from ?? DateFormat('yyyy-MM-01').format(now);
    final endDate = to ?? DateFormat('yyyy-MM-dd').format(now);

    final response = await _apiClient.get(
      ApiEndpoints.revenueReport,
      queryParameters: {'from': startDate, 'to': endDate},
    );

    final List data = response.data['data'] ?? [];
    return data.map((e) => InvoiceReportItem.fromJson(e)).toList();
  }

  Future<List<DoctorReportItem>> fetchDoctorsReport({
    String? from,
    String? to,
  }) async {
    final now = DateTime.now();
    final startDate = from ?? DateFormat('yyyy-MM-01').format(now);
    final endDate = to ?? DateFormat('yyyy-MM-dd').format(now);

    final response = await _apiClient.get(
      ApiEndpoints.doctorsReport,
      queryParameters: {'from': startDate, 'to': endDate},
    );

    final List doctors = response.data['doctors'] ?? [];
    return doctors.map((e) => DoctorReportItem.fromJson(e)).toList();
  }

  Future<List<ViolationReportItem>> fetchViolationsReport() async {
    final response = await _apiClient.get(ApiEndpoints.violationsReport);
    final List patients = response.data['patients'] ?? [];
    return patients.map((e) => ViolationReportItem.fromJson(e)).toList();
  }

  Future<void> depositWallet(int userId, double amount) async {
    await _apiClient.post(
      ApiEndpoints.walletDeposit(userId),
      data: {'amount': amount},
    );
  }

  Future<void> createDoctor({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String specialization,
    required double consultationFee,
  }) async {
    await _apiClient.post(
      ApiEndpoints.doctors,
      data: {
        'name': name,
        'email': email,
        'password': password,
        'phone': phone,
        'specialization': specialization,
        'consultation_fee': consultationFee,
      },
    );
  }
}
