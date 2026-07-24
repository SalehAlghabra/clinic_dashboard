import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/dashboard_repository.dart';
import 'dashboard_events_states.dart';

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  final DashboardRepository _repository;

  DashboardBloc({required DashboardRepository repository})
      : _repository = repository,
        super(DashboardInitial()) {
    on<FetchDashboardData>(_onFetchDashboardData);
    on<RefreshDashboard>(_onRefreshDashboard);
  }

  Future<void> _onFetchDashboardData(
    FetchDashboardData event,
    Emitter<DashboardState> emit,
  ) async {
    emit(DashboardLoading());
    try {
      final results = await Future.wait([
        _repository.fetchDashboardStats(),
        _repository.fetchAppointmentsReport(from: event.from, to: event.to),
        _repository.fetchDoctorsReport(from: event.from, to: event.to),
        _repository.fetchViolationsReport(),
      ]);

      emit(DashboardLoaded(
        stats: results[0] as dynamic,
        recentAppointments: results[1] as dynamic,
        doctorReports: results[2] as dynamic,
        violations: results[3] as dynamic,
      ));
    } catch (e) {
      emit(DashboardError(e.toString().replaceAll('ApiException: ', '')));
    }
  }

  Future<void> _onRefreshDashboard(
    RefreshDashboard event,
    Emitter<DashboardState> emit,
  ) async {
    add(const FetchDashboardData());
  }
}
