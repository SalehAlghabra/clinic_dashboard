class FinancialTransactionModel {
  final int id;
  final String type; // 'deposit', 'booking_deduct', 'penalty', 'refund_full', 'refund_partial', 'deduct'
  final double amount;
  final double balanceBefore;
  final double balanceAfter;
  final String? description;
  final int? appointmentId;
  final String? createdAt;

  // Patient Info
  final int? patientId;
  final String patientName;
  final String? patientEmail;
  final String? patientPhone;
  final String? patientProfilePictureUrl;

  // Doctor Info
  final int? doctorId;
  final String? doctorName;
  final String? doctorSpecialization;

  // Appointment Info
  final String? appointmentDate;
  final String? appointmentTime;
  final double? consultationFee;
  final double? additionalCost;
  final String? appointmentStatus;

  FinancialTransactionModel({
    required this.id,
    required this.type,
    required this.amount,
    required this.balanceBefore,
    required this.balanceAfter,
    this.description,
    this.appointmentId,
    this.createdAt,
    this.patientId,
    this.patientName = '',
    this.patientEmail,
    this.patientPhone,
    this.patientProfilePictureUrl,
    this.doctorId,
    this.doctorName,
    this.doctorSpecialization,
    this.appointmentDate,
    this.appointmentTime,
    this.consultationFee,
    this.additionalCost,
    this.appointmentStatus,
  });

  factory FinancialTransactionModel.fromJson(Map<String, dynamic> json) {
    final patientObj = json['patient'] as Map<String, dynamic>?;
    final doctorObj = json['doctor'] as Map<String, dynamic>?;
    final apptObj = json['appointment'] as Map<String, dynamic>?;

    return FinancialTransactionModel(
      id: json['id'] as int? ?? 0,
      type: json['type'] as String? ?? 'deposit',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      balanceBefore: (json['balance_before'] as num?)?.toDouble() ?? 0.0,
      balanceAfter: (json['balance_after'] as num?)?.toDouble() ?? 0.0,
      description: json['description'] as String?,
      appointmentId: json['appointment_id'] as int?,
      createdAt: json['created_at'] as String?,
      patientId: patientObj?['id'] as int?,
      patientName: patientObj?['name'] as String? ?? 'Unknown Patient',
      patientEmail: patientObj?['email'] as String?,
      patientPhone: patientObj?['phone'] as String?,
      patientProfilePictureUrl: patientObj?['profile_picture_url'] as String?,
      doctorId: doctorObj?['id'] as int?,
      doctorName: doctorObj?['name'] as String?,
      doctorSpecialization: doctorObj?['specialization'] as String?,
      appointmentDate: apptObj?['appointment_date'] as String?,
      appointmentTime: apptObj?['appointment_time'] as String?,
      consultationFee: (apptObj?['consultation_fee'] as num?)?.toDouble(),
      additionalCost: (apptObj?['additional_cost'] as num?)?.toDouble(),
      appointmentStatus: apptObj?['status'] as String?,
    );
  }
}
