import 'package:intl/intl.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_endpoints.dart';
import '../models/dashboard_stats.dart';
import '../models/reports_models.dart';
import '../models/doctor_schedule_model.dart';

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
    if (from == null && to == null) {
      final response = await _apiClient.get(ApiEndpoints.appointments);
      final List data = response.data is List ? response.data : (response.data['data'] ?? []);
      return data.map((e) => AppointmentReportItem.fromJson(e)).toList();
    }

    final response = await _apiClient.get(
      ApiEndpoints.appointmentsReport,
      queryParameters: {'from': from, 'to': to},
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

  Future<List<PatientReportItem>> fetchPatientsReport({String? search}) async {
    final params = <String, dynamic>{};
    if (search != null && search.isNotEmpty) params['search'] = search;
    final response = await _apiClient.get(ApiEndpoints.patientsReport, queryParameters: params);
    final List patients = response.data['patients'] ?? [];
    return patients.map((e) => PatientReportItem.fromJson(e)).toList();
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
        'consultation_fee': consultationFee,
        'bio': bio ?? '',
      },
    );
  }

  Future<void> updateDoctor(int doctorId, {
    String? specialization,
    double? consultationFee,
    String? bio,
  }) async {
    final data = <String, dynamic>{};
    if (specialization != null) data['specialization'] = specialization;
    if (consultationFee != null) data['consultation_fee'] = consultationFee;
    if (bio != null) data['bio'] = bio;

    await _apiClient.put(
      ApiEndpoints.doctorDetail(doctorId),
      data: data,
    );
  }

  Future<void> deleteDoctor(int doctorId) async {
    await _apiClient.delete(ApiEndpoints.doctorDetail(doctorId));
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

  Future<void> updateAppointmentStatus(int appointmentId, String status, {
    double? additionalCost,
    String? additionalNote,
  }) async {
    final data = <String, dynamic>{'status': status};
    if (status == 'completed') {
      if (additionalCost != null) data['additional_cost'] = additionalCost;
      if (additionalNote != null) data['additional_note'] = additionalNote;
    }

    await _apiClient.patch(
      '${ApiEndpoints.appointments}/$appointmentId/status',
      data: data,
    );
  }

  Future<void> updateInvoicePayment(int invoiceId, String status, String paymentMethod) async {
    await _apiClient.patch(
      '${ApiEndpoints.invoices}/$invoiceId/payment',
      data: {
        'payment_status': status,
        'payment_method': paymentMethod,
      },
    );
  }
}
