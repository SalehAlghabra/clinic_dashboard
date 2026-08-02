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

class AppointmentReportItem {
  final int id;
  final String patientName;
  final String doctorName;
  final double consultationFee;
  final double additionalCost;
  final String? additionalNote;
  final String appointmentDate;
  final String appointmentTime;
  final String status;
  final String? cancelledBy;

  AppointmentReportItem({
    required this.id,
    required this.patientName,
    required this.doctorName,
    required this.consultationFee,
    required this.additionalCost,
    this.additionalNote,
    required this.appointmentDate,
    required this.appointmentTime,
    required this.status,
    this.cancelledBy,
  });

  factory AppointmentReportItem.fromJson(Map<String, dynamic> json) {
    return AppointmentReportItem(
      id: _toInt(json['id']),
      patientName: json['patient_name'] ?? 'Unknown Patient',
      doctorName: json['doctor_name'] ?? 'Unknown Doctor',
      consultationFee: _toDouble(json['consultation_fee']),
      additionalCost: _toDouble(json['additional_cost']),
      additionalNote: json['additional_note'],
      appointmentDate: json['appointment_date'] ?? '',
      appointmentTime: json['appointment_time'] ?? '',
      status: json['status'] ?? 'pending',
      cancelledBy: json['cancelled_by'],
    );
  }
}

class DoctorReportItem {
  final int id;
  final String doctorName;
  final String specialization;
  final double consultationFee;
  final int totalAppointments;
  final int completed;
  final int cancelled;
  final double revenue;

  DoctorReportItem({
    required this.id,
    required this.doctorName,
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
      doctorName: json['doctor_name'] ?? '',
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
  final String email;
  final int violationCount;
  final double totalPenalties;
  final String penaltyRate;

  ViolationReportItem({
    required this.id,
    required this.patientName,
    required this.email,
    required this.violationCount,
    required this.totalPenalties,
    required this.penaltyRate,
  });

  factory ViolationReportItem.fromJson(Map<String, dynamic> json) {
    return ViolationReportItem(
      id: _toInt(json['id']),
      patientName: json['patient_name'] ?? '',
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
  final String patientName;
  final String doctorName;
  final double consultationFee;
  final double totalAmount;
  final double alreadyPaid;
  final double remainingAmount;
  final String paymentStatus;
  final String paymentMethod;
  final String issuedAt;

  InvoiceReportItem({
    required this.id,
    required this.appointmentId,
    required this.patientName,
    required this.doctorName,
    required this.consultationFee,
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
      patientName: json['patient_name'] ?? 'N/A',
      doctorName: json['doctor_name'] ?? 'N/A',
      consultationFee: _toDouble(json['consultation_fee']),
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
  final String email;
  final String phone;
  final double walletBalance;
  final int violationCount;
  final double totalPenalties;

  PatientReportItem({
    required this.id,
    required this.patientName,
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
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      walletBalance: _toDouble(json['wallet_balance']),
      violationCount: _toInt(json['violation_count']),
      totalPenalties: _toDouble(json['total_penalties']),
    );
  }
}
