import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class LoginButtonPressedEvent extends AuthEvent {
  final String email;
  final String password;

  const LoginButtonPressedEvent({required this.email, required this.password});

  @override
  List<Object> get props => [email, password];

  @override
  String toString() =>
      'LoginButtonPressedEvent{email: $email, password: $password}';
}

class SignUpButtonPressedEvent extends AuthEvent {
  final String email;
  final String password;

  const SignUpButtonPressedEvent({required this.email, required this.password});

  @override
  List<Object> get props => [email, password];

  @override
  String toString() =>
      'SignUpButtonPressedEvent{email: $email, password: $password}';
}

class LogOutButtonPressedEvent extends AuthEvent {
  const LogOutButtonPressedEvent();

  @override
  List<Object> get props => [];

  @override
  String toString() => 'LogOutButtonPressedEvent{}';
}
