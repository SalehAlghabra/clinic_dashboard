import '../../../../core/config/app_config.dart';

double _toDouble(dynamic value) {
  if (value == null) return 0.0;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0.0;
  return 0.0;
}

int _toInt(dynamic value) {
  if (value == null) return 0;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

String? parseProfilePictureUrl(dynamic rawUrl, dynamic rawPath) {
  String? url = rawUrl as String? ?? rawPath as String?;
  if (url == null || url.toString().isEmpty || url.toString().contains('default-avatar.png')) {
    return null;
  }

  final base = AppConfig.baseUrl.endsWith('/')
      ? AppConfig.baseUrl.substring(0, AppConfig.baseUrl.length - 1)
      : AppConfig.baseUrl;

  String relativePath = url.toString();
  if (relativePath.contains('storage/')) {
    final idx = relativePath.indexOf('storage/');
    relativePath = relativePath.substring(idx + 'storage/'.length);
  }
  if (relativePath.startsWith('/')) {
    relativePath = relativePath.substring(1);
  }

  if ((url.toString().startsWith('http://') || url.toString().startsWith('https://')) && !url.toString().contains('storage/')) {
    return url.toString();
  }

  return '$base/api/storage/$relativePath';
}

String? _parseProfilePictureUrl(dynamic rawUrl, dynamic rawPath) =>
    parseProfilePictureUrl(rawUrl, rawPath);


class AppointmentReportItem {
  final int id;
  final int patientId;
  final String patientName;
  final String? patientEmail;
  final String? patientPhone;
  final String? patientProfilePictureUrl;
  final int doctorId;
  final String doctorName;
  final String? specialization;
  final String? doctorProfilePictureUrl;
  final double consultationFee;
  final double additionalCost;
  final String? additionalNote;
  final String appointmentDate;
  final String appointmentTime;
  final String status;
  final String? notes;
  final String? cancelledBy;

  AppointmentReportItem({
    required this.id,
    this.patientId = 0,
    required this.patientName,
    this.patientEmail,
    this.patientPhone,
    this.patientProfilePictureUrl,
    this.doctorId = 0,
    required this.doctorName,
    this.specialization,
    this.doctorProfilePictureUrl,
    required this.consultationFee,
    required this.additionalCost,
    this.additionalNote,
    required this.appointmentDate,
    required this.appointmentTime,
    required this.status,
    this.notes,
    this.cancelledBy,
  });

  factory AppointmentReportItem.fromJson(Map<String, dynamic> json) {
    return AppointmentReportItem(
      id: _toInt(json['id']),
      patientId: _toInt(json['patient_id']),
      patientName: json['patient_name'] ?? 'Unknown Patient',
      patientEmail: json['patient_email'],
      patientPhone: json['patient_phone'],
      patientProfilePictureUrl: _parseProfilePictureUrl(json['patient_profile_picture_url'], null),
      doctorId: _toInt(json['doctor_id']),
      doctorName: json['doctor_name'] ?? 'Unknown Doctor',
      specialization: json['specialization'],
      doctorProfilePictureUrl: _parseProfilePictureUrl(json['doctor_profile_picture_url'], null),
      consultationFee: _toDouble(json['consultation_fee']),
      additionalCost: _toDouble(json['additional_cost']),
      additionalNote: json['additional_note'],
      appointmentDate: json['appointment_date'] ?? '',
      appointmentTime: json['appointment_time'] ?? '',
      status: json['status'] ?? 'pending',
      notes: json['notes'],
      cancelledBy: json['cancelled_by'],
    );
  }
}

class DoctorReportItem {
  final int id;
  final int userId;
  final String doctorName;
  final String? profilePictureUrl;
  final String specialization;
  final double consultationFee;
  final int totalAppointments;
  final int completed;
  final int cancelled;
  final double revenue;

  DoctorReportItem({
    required this.id,
    this.userId = 0,
    required this.doctorName,
    this.profilePictureUrl,
    required this.specialization,
    required this.consultationFee,
    required this.totalAppointments,
    required this.completed,
    required this.cancelled,
    required this.revenue,
  });

  factory DoctorReportItem.fromJson(Map<String, dynamic> json) {
    return DoctorReportItem(
      id: _toInt(json['id']),
      userId: _toInt(json['user_id']),
      doctorName: json['doctor_name'] ?? '',
      profilePictureUrl: _parseProfilePictureUrl(json['profile_picture_url'], json['profile_picture']),
      specialization: json['specialization'] ?? '',
      consultationFee: _toDouble(json['consultation_fee']),
      totalAppointments: _toInt(json['total_appointments']),
      completed: _toInt(json['completed']),
      cancelled: _toInt(json['cancelled']),
      revenue: _toDouble(json['revenue']),
    );
  }
}

class ViolationReportItem {
  final int id;
  final String patientName;
  final String? profilePictureUrl;
  final String email;
  final int violationCount;
  final double totalPenalties;
  final String penaltyRate;

  ViolationReportItem({
    required this.id,
    required this.patientName,
    this.profilePictureUrl,
    required this.email,
    required this.violationCount,
    required this.totalPenalties,
    required this.penaltyRate,
  });

  factory ViolationReportItem.fromJson(Map<String, dynamic> json) {
    return ViolationReportItem(
      id: _toInt(json['id']),
      patientName: json['patient_name'] ?? '',
      profilePictureUrl: _parseProfilePictureUrl(json['profile_picture_url'], json['profile_picture']),
      email: json['email'] ?? '',
      violationCount: _toInt(json['violation_count']),
      totalPenalties: _toDouble(json['total_penalties']),
      penaltyRate: json['penalty_rate'] ?? '0%',
    );
  }
}

class InvoiceReportItem {
  final int id;
  final int appointmentId;
  final int patientId;
  final String patientName;
  final String? patientEmail;
  final String? patientPhone;
  final String? profilePictureUrl;
  final double walletBalance;
  final String doctorName;
  final double consultationFee;
  final double additionalCost;
  final String? additionalNote;
  final double totalAmount;
  final double alreadyPaid;
  final double remainingAmount;
  final String paymentStatus;
  final String paymentMethod;
  final String issuedAt;

  InvoiceReportItem({
    required this.id,
    required this.appointmentId,
    required this.patientId,
    required this.patientName,
    this.patientEmail,
    this.patientPhone,
    this.profilePictureUrl,
    this.walletBalance = 0.0,
    required this.doctorName,
    required this.consultationFee,
    this.additionalCost = 0.0,
    this.additionalNote,
    required this.totalAmount,
    required this.alreadyPaid,
    required this.remainingAmount,
    required this.paymentStatus,
    required this.paymentMethod,
    required this.issuedAt,
  });

  factory InvoiceReportItem.fromJson(Map<String, dynamic> json) {
    return InvoiceReportItem(
      id: _toInt(json['id']),
      appointmentId: _toInt(json['appointment_id']),
      patientId: _toInt(json['patient_id']),
      patientName: json['patient_name'] ?? 'N/A',
      patientEmail: json['patient_email'],
      patientPhone: json['patient_phone'],
      profilePictureUrl: _parseProfilePictureUrl(json['profile_picture_url'], json['profile_picture']),
      walletBalance: _toDouble(json['wallet_balance']),
      doctorName: json['doctor_name'] ?? 'N/A',
      consultationFee: _toDouble(json['consultation_fee']),
      additionalCost: _toDouble(json['additional_cost']),
      additionalNote: json['additional_note'],
      totalAmount: _toDouble(json['total_amount']),
      alreadyPaid: _toDouble(json['already_paid'] ?? json['deposit_amount']),
      remainingAmount: _toDouble(json['remaining_amount']),
      paymentStatus: json['payment_status'] ?? 'unpaid',
      paymentMethod: json['payment_method'] ?? 'cash',
      issuedAt: json['issued_at'] ?? '',
    );
  }
}

class PatientReportItem {
  final int id;
  final String patientName;
  final String? profilePictureUrl;
  final String email;
  final String phone;
  final double walletBalance;
  final int violationCount;
  final double totalPenalties;

  PatientReportItem({
    required this.id,
    required this.patientName,
    this.profilePictureUrl,
    required this.email,
    required this.phone,
    required this.walletBalance,
    required this.violationCount,
    required this.totalPenalties,
  });

  factory PatientReportItem.fromJson(Map<String, dynamic> json) {
    return PatientReportItem(
      id: _toInt(json['id']),
      patientName: json['patient_name'] ?? '',
      profilePictureUrl: _parseProfilePictureUrl(json['profile_picture_url'], json['profile_picture']),
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      walletBalance: _toDouble(json['wallet_balance']),
      violationCount: _toInt(json['violation_count']),
      totalPenalties: _toDouble(json['total_penalties']),
    );
  }
}
