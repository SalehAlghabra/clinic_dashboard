import 'package:intl/intl.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_endpoints.dart';
import '../models/dashboard_stats.dart';
import '../models/reports_models.dart';
import '../models/doctor_schedule_model.dart';
import '../models/doctor_service_model.dart';

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
    String? bio,
  }) async {
    final staffResponse = await _apiClient.post(
      ApiEndpoints.createStaff,
      data: {
        'name': name,
        'email': email,
        'password': password,
        'phone': phone,
        'role': 'doctor',
      },
    );

    final userId = staffResponse.data['user']['id'];

    await _apiClient.post(
      ApiEndpoints.doctors,
      data: {
        'user_id': userId,
        'specialization': specialization,
        'bio': bio ?? '',
      },
    );
  }

  Future<List<DoctorSchedule>> fetchDoctorSchedules(int doctorId) async {
    final response = await _apiClient.get(ApiEndpoints.doctorSchedules(doctorId));
    final List data = response.data is List ? response.data : [];
    return data.map((e) => DoctorSchedule.fromJson(e)).toList();
  }

  Future<void> addDoctorSchedule(int doctorId, String day, String start, String end, int duration) async {
    await _apiClient.post(
      ApiEndpoints.doctorSchedules(doctorId),
      data: {
        'day_of_week': day.toLowerCase(),
        'start_time': start,
        'end_time': end,
        'duration_per_patient': duration,
      },
    );
  }

  Future<void> deleteDoctorSchedule(int doctorId, int scheduleId) async {
    await _apiClient.delete(ApiEndpoints.doctorScheduleDetail(doctorId, scheduleId));
  }

  Future<List<DoctorService>> fetchDoctorServices(int doctorId) async {
    final response = await _apiClient.get(ApiEndpoints.doctorServices(doctorId));
    final List data = response.data is List ? response.data : [];
    return data.map((e) => DoctorService.fromJson(e)).toList();
  }

  Future<void> addDoctorService(int doctorId, String serviceName, double price) async {
    await _apiClient.post(
      ApiEndpoints.doctorServices(doctorId),
      data: {
        'service_name': serviceName,
        'price': price,
      },
    );
  }

  Future<void> deleteDoctorService(int doctorId, int serviceId) async {
    await _apiClient.delete(ApiEndpoints.doctorServiceDetail(doctorId, serviceId));
  }
}
