class AppointmentReportItem {
  final int id;
  final String patientName;
  final String doctorName;
  final String service;
  final String appointmentDate;
  final String appointmentTime;
  final String status;
  final String? cancelledBy;

  AppointmentReportItem({
    required this.id,
    required this.patientName,
    required this.doctorName,
    required this.service,
    required this.appointmentDate,
    required this.appointmentTime,
    required this.status,
    this.cancelledBy,
  });

  factory AppointmentReportItem.fromJson(Map<String, dynamic> json) {
    return AppointmentReportItem(
      id: json['id'] ?? 0,
      patientName: json['patient_name'] ?? 'Unknown Patient',
      doctorName: json['doctor_name'] ?? 'Unknown Doctor',
      service: json['service'] ?? 'General Service',
      appointmentDate: json['appointment_date'] ?? '',
      appointmentTime: json['appointment_time'] ?? '',
      status: json['status'] ?? 'pending',
      cancelledBy: json['cancelled_by'],
    );
  }
}

class DoctorReportItem {
  final String doctorName;
  final String specialization;
  final int totalAppointments;
  final int completed;
  final int cancelled;
  final double revenue;

  DoctorReportItem({
    required this.doctorName,
    required this.specialization,
    required this.totalAppointments,
    required this.completed,
    required this.cancelled,
    required this.revenue,
  });

  factory DoctorReportItem.fromJson(Map<String, dynamic> json) {
    return DoctorReportItem(
      doctorName: json['doctor_name'] ?? '',
      specialization: json['specialization'] ?? '',
      totalAppointments: json['total_appointments'] ?? 0,
      completed: json['completed'] ?? 0,
      cancelled: json['cancelled'] ?? 0,
      revenue: (json['revenue'] ?? 0).toDouble(),
    );
  }
}

class ViolationReportItem {
  final String patientName;
  final String email;
  final int violationCount;
  final double totalPenalties;
  final String penaltyRate;

  ViolationReportItem({
    required this.patientName,
    required this.email,
    required this.violationCount,
    required this.totalPenalties,
    required this.penaltyRate,
  });

  factory ViolationReportItem.fromJson(Map<String, dynamic> json) {
    return ViolationReportItem(
      patientName: json['patient_name'] ?? '',
      email: json['email'] ?? '',
      violationCount: json['violation_count'] ?? 0,
      totalPenalties: (json['total_penalties'] ?? 0).toDouble(),
      penaltyRate: json['penalty_rate'] ?? '0%',
    );
  }
}

class InvoiceReportItem {
  final int id;
  final String patientName;
  final String doctorName;
  final String service;
  final double totalAmount;
  final String paymentStatus;
  final String paymentMethod;
  final String issuedAt;

  InvoiceReportItem({
    required this.id,
    required this.patientName,
    required this.doctorName,
    required this.service,
    required this.totalAmount,
    required this.paymentStatus,
    required this.paymentMethod,
    required this.issuedAt,
  });

  factory InvoiceReportItem.fromJson(Map<String, dynamic> json) {
    return InvoiceReportItem(
      id: json['id'] ?? 0,
      patientName: json['patient_name'] ?? 'N/A',
      doctorName: json['doctor_name'] ?? 'N/A',
      service: json['service'] ?? 'N/A',
      totalAmount: (json['total_amount'] ?? 0).toDouble(),
      paymentStatus: json['payment_status'] ?? 'unpaid',
      paymentMethod: json['payment_method'] ?? 'cash',
      issuedAt: json['issued_at'] ?? '',
    );
  }
}
