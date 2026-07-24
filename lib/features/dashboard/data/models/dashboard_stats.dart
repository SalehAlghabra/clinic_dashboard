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
      totalPatients: json['total_patients'] ?? 0,
      totalDoctors: json['total_doctors'] ?? 0,
      totalReceptionists: json['total_receptionists'] ?? 0,
      newPatientsToday: json['new_patients_today'] ?? 0,
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
      total: json['total'] ?? 0,
      today: json['today'] ?? 0,
      pending: json['pending'] ?? 0,
      confirmed: json['confirmed'] ?? 0,
      completed: json['completed'] ?? 0,
      cancelled: json['cancelled'] ?? 0,
      cancelledByDoctor: json['cancelled_by_doctor'] ?? 0,
      cancelledByPatient: json['cancelled_by_patient'] ?? 0,
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
      totalInvoices: json['total_invoices'] ?? 0,
      totalRevenue: (json['total_revenue'] ?? 0).toDouble(),
      pendingPayments: (json['pending_payments'] ?? 0).toDouble(),
      totalDeposits: (json['total_deposits'] ?? 0).toDouble(),
      totalPenalties: (json['total_penalties'] ?? 0).toDouble(),
      totalRefunds: (json['total_refunds'] ?? 0).toDouble(),
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
