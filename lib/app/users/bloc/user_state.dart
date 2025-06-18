import 'package:equatable/equatable.dart';

abstract class UserState extends Equatable {
  const UserState();

  @override
  List<Object> get props => [];
}

class UserInitialState extends UserState {}

class UserLoading extends UserState {}

class UserLoadingSuccess extends UserState {}

class UserLoadingFailure extends UserState {
  final String errorMessage;

  const UserLoadingFailure({required this.errorMessage});

  @override
  List<Object> get props => [errorMessage];
}
