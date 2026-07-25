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

class UserStats {
  final int totalPatients;
  final int totalDoctors;
  final int totalReceptionists;
  final int newPatientsToday;

  UserStats({
    required this.totalPatients,
    required this.totalDoctors,
    required this.totalReceptionists,
    required this.newPatientsToday,
  });

  factory UserStats.fromJson(Map<String, dynamic> json) {
    return UserStats(
      totalPatients: _toInt(json['total_patients']),
      totalDoctors: _toInt(json['total_doctors']),
      totalReceptionists: _toInt(json['total_receptionists']),
      newPatientsToday: _toInt(json['new_patients_today']),
    );
  }
}

class AppointmentStats {
  final int total;
  final int today;
  final int pending;
  final int confirmed;
  final int completed;
  final int cancelled;
  final int cancelledByDoctor;
  final int cancelledByPatient;

  AppointmentStats({
    required this.total,
    required this.today,
    required this.pending,
    required this.confirmed,
    required this.completed,
    required this.cancelled,
    required this.cancelledByDoctor,
    required this.cancelledByPatient,
  });

  factory AppointmentStats.fromJson(Map<String, dynamic> json) {
    return AppointmentStats(
      total: _toInt(json['total']),
      today: _toInt(json['today']),
      pending: _toInt(json['pending']),
      confirmed: _toInt(json['confirmed']),
      completed: _toInt(json['completed']),
      cancelled: _toInt(json['cancelled']),
      cancelledByDoctor: _toInt(json['cancelled_by_doctor']),
      cancelledByPatient: _toInt(json['cancelled_by_patient']),
    );
  }
}

class FinancialStats {
  final int totalInvoices;
  final double totalRevenue;
  final double pendingPayments;
  final double totalDeposits;
  final double totalPenalties;
  final double totalRefunds;

  FinancialStats({
    required this.totalInvoices,
    required this.totalRevenue,
    required this.pendingPayments,
    required this.totalDeposits,
    required this.totalPenalties,
    required this.totalRefunds,
  });

  factory FinancialStats.fromJson(Map<String, dynamic> json) {
    return FinancialStats(
      totalInvoices: _toInt(json['total_invoices']),
      totalRevenue: _toDouble(json['total_revenue']),
      pendingPayments: _toDouble(json['pending_payments']),
      totalDeposits: _toDouble(json['total_deposits']),
      totalPenalties: _toDouble(json['total_penalties']),
      totalRefunds: _toDouble(json['total_refunds']),
    );
  }
}

class DashboardStats {
  final UserStats users;
  final AppointmentStats appointments;
  final FinancialStats financial;

  DashboardStats({
    required this.users,
    required this.appointments,
    required this.financial,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      users: UserStats.fromJson(json['users'] ?? {}),
      appointments: AppointmentStats.fromJson(json['appointments'] ?? {}),
      financial: FinancialStats.fromJson(json['financial'] ?? {}),
    );
  }
}
