import 'package:equatable/equatable.dart';
import '../../data/models/dashboard_stats.dart';
import '../../data/models/reports_models.dart';

abstract class DashboardEvent extends Equatable {
  const DashboardEvent();
  @override
  List<Object?> get props => [];
}

class FetchDashboardData extends DashboardEvent {
  final String? from;
  final String? to;

  const FetchDashboardData({this.from, this.to});

  @override
  List<Object?> get props => [from, to];
}

class RefreshDashboard extends DashboardEvent {}

// States
abstract class DashboardState extends Equatable {
  const DashboardState();
  @override
  List<Object?> get props => [];
}

class DashboardInitial extends DashboardState {}

class DashboardLoading extends DashboardState {}

class DashboardLoaded extends DashboardState {
  final DashboardStats stats;
  final List<AppointmentReportItem> recentAppointments;
  final List<DoctorReportItem> doctorReports;
  final List<ViolationReportItem> violations;

  const DashboardLoaded({
    required this.stats,
    required this.recentAppointments,
    required this.doctorReports,
    required this.violations,
  });

  @override
  List<Object?> get props => [stats, recentAppointments, doctorReports, violations];
}

class DashboardError extends DashboardState {
  final String message;
  const DashboardError(this.message);

  @override
  List<Object?> get props => [message];
}
