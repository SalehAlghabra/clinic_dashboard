import 'package:dio/dio.dart';
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

  Future<void> deductWallet(int userId, double amount) async {
    await _apiClient.post(
      '/api/wallet/deduct/$userId',
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

  Future<Map<String, dynamic>> updateInvoicePayment(int invoiceId, String status, String paymentMethod) async {
    final response = await _apiClient.patch(
      '${ApiEndpoints.invoices}/$invoiceId/payment',
      data: {
        'payment_status': status,
        'payment_method': paymentMethod,
      },
    );
    return response.data is Map<String, dynamic> ? response.data : {};
  }

  Future<Map<String, dynamic>> registerPatient({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
    String? phone,
    bool staffOverride = false,
  }) async {
    final response = await _apiClient.post(
      '/api/patients',
      data: {
        'name': name,
        'email': email,
        'password': password,
        'password_confirmation': passwordConfirmation,
        'phone': phone ?? '',
        if (staffOverride) 'staff_override': true,
      },
    );
    return Map<String, dynamic>.from(response.data);
  }

  Future<void> verifyOtp(String email, String otp) async {
    await _apiClient.post(
      ApiEndpoints.verifyOtp,
      data: {
        'email': email,
        'otp': otp,
      },
    );
  }

  Future<Map<String, dynamic>> updatePatient({
    required int id,
    required String name,
    required String email,
    String? phone,
    bool staffOverride = false,
    String? otp,
  }) async {
    final response = await _apiClient.put(
      '/api/patients/$id',
      data: {
        'name': name,
        'email': email,
        'phone': phone ?? '',
        if (staffOverride) 'staff_override': true,
        if (otp != null && otp.isNotEmpty) 'otp': otp,
      },
    );
    return Map<String, dynamic>.from(response.data);
  }

  Future<void> bookAppointment({
    required int patientId,
    required int doctorId,
    required String date,
    required String time,
    String? notes,
  }) async {
    await _apiClient.post(
      ApiEndpoints.appointments,
      data: {
        'patient_id': patientId,
        'doctor_id': doctorId,
        'appointment_date': date,
        'appointment_time': time,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      },
    );
  }

  Future<void> rescheduleAppointment({
    required int appointmentId,
    required String date,
    required String time,
  }) async {
    await _apiClient.patch(
      '${ApiEndpoints.appointments}/$appointmentId/reschedule',
      data: {
        'appointment_date': date,
        'appointment_time': time,
      },
    );
  }

  Future<void> cancelAppointment(int appointmentId, {String? reason}) async {
    await _apiClient.patch(
      '${ApiEndpoints.appointments}/$appointmentId/cancel',
      data: {
        if (reason != null && reason.isNotEmpty) 'cancellation_reason': reason,
      },
    );
  }

  Future<List<InvoiceReportItem>> fetchInvoices({
    bool billingQueue = false,
    bool unpaid = false,
    String? search,
  }) async {
    final params = <String, dynamic>{};
    if (billingQueue) params['billing_queue'] = 1;
    if (unpaid) params['unpaid'] = 1;
    if (search != null && search.isNotEmpty) params['search'] = search;

    final response = await _apiClient.get(ApiEndpoints.invoices, queryParameters: params);
    final List data = response.data is List ? response.data : [];
    return data.map((e) => InvoiceReportItem.fromJson(e)).toList();
  }

  Future<List<Map<String, dynamic>>> fetchPatientTransactions(int patientId) async {
    final response = await _apiClient.get('/api/wallet/transactions/$patientId');
    final List data = response.data['data'] ?? (response.data is List ? response.data : []);
    return List<Map<String, dynamic>>.from(data);
  }

  Future<List<String>> fetchAvailableSlots(int doctorId, String date) async {
    final response = await _apiClient.get(
      '/api/doctors/$doctorId/available-slots',
      queryParameters: {'date': date},
    );
    final List slots = response.data['available_slots'] ?? (response.data is List ? response.data : []);
    return slots.map((e) => e.toString()).toList();
  }

  Future<List<Map<String, dynamic>>> fetchReceptionists() async {
    final response = await _apiClient.get('/api/staff/receptionists');
    final List data = response.data['receptionists'] ?? [];
    return List<Map<String, dynamic>>.from(data);
  }

  Future<void> createReceptionist({
    required String name,
    required String email,
    required String password,
    String? phone,
  }) async {
    await _apiClient.post(
      '/api/auth/create-staff',
      data: {
        'name': name,
        'email': email,
        'password': password,
        'phone': phone ?? '',
        'role': 'receptionist',
      },
    );
  }

  Future<void> deleteStaff(int staffId) async {
    await _apiClient.delete('/api/staff/$staffId');
  }

  /// Upload a profile picture for a patient (admin or receptionist).
  Future<String?> updatePatientProfilePicture({
    required int patientId,
    required List<int> fileBytes,
    required String fileName,
  }) async {
    final formData = FormData.fromMap({
      'profile_picture': MultipartFile.fromBytes(fileBytes, filename: fileName),
    });
    final response = await _apiClient.post(
      '/api/patients/$patientId/profile-picture',
      data: formData,
    );
    return response.data['profile_picture_url'] as String?;
  }

  /// Upload a profile picture for a doctor or receptionist (admin only).
  Future<String?> updateStaffProfilePicture({
    required int userId,
    required List<int> fileBytes,
    required String fileName,
  }) async {
    final formData = FormData.fromMap({
      'profile_picture': MultipartFile.fromBytes(fileBytes, filename: fileName),
    });
    final response = await _apiClient.post(
      '/api/staff/$userId/profile-picture',
      data: formData,
    );
    return response.data['profile_picture_url'] as String?;
  }
}
