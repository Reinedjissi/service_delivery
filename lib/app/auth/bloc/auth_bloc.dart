import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:service_delivery/app/auth/bloc/auth_event.dart';
import 'package:service_delivery/app/auth/bloc/auth_state.dart';
import 'package:service_delivery/app/auth/repository/repository.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authService;

  AuthBloc()
      : _authService = AuthRepository(),
        super(AuthInitialState()) {
    // Correction : spécifier le type d'événement pour le handler générique
    on<AuthEvent>((event, emit) => emit(AuthLoading()));
    on<LoginButtonPressedEvent>(_signInWithEmailAndPassword);
    on<SignUpButtonPressedEvent>(_signUpUser);
    on<LogOutButtonPressedEvent>(_logOutUser);
  }

  Future<void> _signInWithEmailAndPassword(LoginButtonPressedEvent event,
      Emitter<AuthState> emit,
      // Correction : paramètre nommé 'emit' au lieu de 'emitter'
      ) async {
    try {
      await _authService.signInWithEmailAndPassword(
          email: event.email, password: event.password);
      emit(
          AuthLoadingSuccess()); // Correction : utiliser 'emit' au lieu de 'emitter'
    } catch (e) {
      emit(AuthLoadingFailure(errorMessage: e.toString()));
    }
  }

  Future<void> _signUpUser(SignUpButtonPressedEvent event,
      Emitter<AuthState> emit, // Correction : paramètre nommé 'emit'
      ) async {
    try {
      await _authService.createUserWithEmailAndPassword(
          email: event.email, password: event.password);
      emit(AuthLoadingSuccess()); // Correction : utiliser 'emit'
    } catch (e) {
      // emit(AuthLoadingFailure(errorMessage: e.toString()));
    }
  }

  Future<void> _logOutUser(LogOutButtonPressedEvent event,
      Emitter<AuthState> emit, // Correction : paramètre nommé 'emit'
      ) async {
    try {
      await _authService.signOut(); // Correction : ajouter 'await'
      emit(AuthLoadingSuccess()); // Correction : utiliser 'emit'
    } catch (e) {
      emit(AuthLoadingFailure(errorMessage: e.toString()));
      //emit(AuthLoadingFailure(errorMessage: e.toString()));
    }
  }
}