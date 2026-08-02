import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/auth_repository.dart';
import 'auth_events_states.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;

  AuthBloc({required AuthRepository authRepository})
      : _authRepository = authRepository,
        super(AuthInitial()) {
    on<CheckAuthStatus>(_onCheckAuthStatus);
    on<LoginSubmitted>(_onLoginSubmitted);
    on<OtpSubmitted>(_onOtpSubmitted);
    on<LogoutRequested>(_onLogoutRequested);
    on<ProfileUpdated>((event, emit) => emit(Authenticated(event.user)));
  }

  Future<void> _onCheckAuthStatus(
    CheckAuthStatus event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final user = await _authRepository.getProfile();
      if (user != null && user.role != 'patient') {
        emit(Authenticated(user));
      } else {
        emit(Unauthenticated());
      }
    } catch (_) {
      emit(Unauthenticated());
    }
  }

  Future<void> _onLoginSubmitted(
    LoginSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final result = await _authRepository.login(
        email: event.email,
        password: event.password,
      );

      if (result.requiresOtp) {
        emit(AuthOtpRequired(
          email: result.email ?? event.email,
          message: result.message ?? 'OTP verification required.',
        ));
      } else if (result.user != null) {
        if (result.user!.role == 'patient') {
          emit(const AuthFailure('Access denied. Patients cannot access the management dashboard.'));
        } else {
          emit(Authenticated(result.user!));
        }
      } else {
        emit(const AuthFailure('Login failed. Please try again.'));
      }
    } catch (e) {
      emit(AuthFailure(e.toString().replaceAll('ApiException: ', '')));
    }
  }

  Future<void> _onOtpSubmitted(
    OtpSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final user = await _authRepository.verifyOtp(
        email: event.email,
        otp: event.otp,
      );
      if (user.role == 'patient') {
        await _authRepository.logout();
        emit(const AuthFailure('Access denied. Patients cannot access the management dashboard.'));
      } else {
        emit(Authenticated(user));
      }
    } catch (e) {
      emit(AuthFailure(e.toString().replaceAll('ApiException: ', '')));
    }
  }

  Future<void> _onLogoutRequested(
    LogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    await _authRepository.logout();
    emit(Unauthenticated());
  }
}
