import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:service_delivery/app/auth/bloc/auth_event.dart';
import 'package:service_delivery/app/auth/bloc/auth_state.dart';
import 'package:service_delivery/app/auth/repository/repository.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authService;

  AuthBloc()
      : _authService = AuthRepository(),
        super(AuthInitialState()) {
    on((event, emit) => emit(AuthLoading()));
    on<LoginButtonPressedEvent>(_signInWithEmailAndPassword);
    on<SignUpButtonPressedEvent>(_signUpUser);
    on<LogOutButtonPressedEvent>(_logOutUser);
  }

  Future<void> _signInWithEmailAndPassword(
    LoginButtonPressedEvent event,
    Emitter<AuthState> emitter,
  ) async {
    try {
      await _authService.signInWithEmailAndPassword(
          email: event.email, password: event.password);
      emitter(AuthLoadingSuccess());
    } catch (e) {
      emitter(AuthLoadingFailure(errorMessage: e.toString()));
    }
  }

  Future<void> _signUpUser(
    SignUpButtonPressedEvent event,
    Emitter<AuthState> emitter,
  ) async {
    try {
      await _authService.createUserWithEmailAndPassword(
          email: event.email, password: event.password);
      emitter(AuthLoadingSuccess());
    } catch (e) {
      emitter(AuthLoadingFailure(errorMessage: e.toString()));
    }
  }

  Future<void> _logOutUser(
    LogOutButtonPressedEvent event,
    Emitter<AuthState> emitter,
  ) async {
    try {
      _authService.signOut();
      emitter(AuthLoadingSuccess());
    } catch (e) {
      emitter(AuthLoadingFailure(errorMessage: e.toString()));
    }
  }
}
