import 'package:equatable/equatable.dart';

abstract class AuthState extends Equatable{
  const AuthState();
  @override
  List<Object> get props => [];
}

class AuthInitialState extends AuthState {}
class AuthLoading extends AuthState {}

class AuthLoadingSuccess extends AuthState {}

class AuthLoadingFailure extends AuthState {
  final String errorMessage;
  const AuthLoadingFailure({required this.errorMessage});
  @override
  List<Object> get props => [errorMessage];

  @override
  String toString() => 'AuthLoadingFailure{errorMessage: $errorMessage}';

}