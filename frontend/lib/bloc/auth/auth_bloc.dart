import 'package:flutter_bloc/flutter_bloc.dart';
import '../../repositories/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository authRepository;

  AuthBloc({required this.authRepository}) : super(const AuthState.unknown()) {
    on<AppStarted>(_onAppStarted);
    on<LoginRequested>(_onLoginRequested);
    on<SignupRequested>(_onSignupRequested);
    on<LogoutRequested>(_onLogoutRequested);
  }

  Future<void> _onAppStarted(AppStarted event, Emitter<AuthState> emit) async {
    try {
      final user = await authRepository.getCurrentUser();
      if (user != null) {
        emit(AuthState.authenticated(user));
      } else {
        emit(const AuthState.unauthenticated());
      }
    } catch (_) {
      emit(const AuthState.unauthenticated());
    }
  }

  Future<void> _onLoginRequested(LoginRequested event, Emitter<AuthState> emit) async {
    emit(const AuthState.loading());
    try {
      final user = await authRepository.login(email: event.email, password: event.password);
      emit(AuthState.authenticated(user));
    } catch (e) {
      emit(AuthState.error(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onSignupRequested(SignupRequested event, Emitter<AuthState> emit) async {
    emit(const AuthState.loading());
    try {
      final user = await authRepository.signup(
        name: event.name,
        email: event.email,
        password: event.password,
      );
      emit(AuthState.authenticated(user));
    } catch (e) {
      emit(AuthState.error(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onLogoutRequested(LogoutRequested event, Emitter<AuthState> emit) async {
    await authRepository.logout();
    emit(const AuthState.unauthenticated());
  }
}