import 'package:equatable/equatable.dart';
import 'package:service_delivery/app/users/models/user.dart';

abstract class UserEvent extends Equatable {
  const UserEvent();

  @override
  List<Object?> get props => [];
}

class CreateUserEvent extends UserEvent {
  final UserDto userDto;

  const CreateUserEvent({required this.userDto});

  @override
  List<Object> get props => [CreateUserEvent];

  @override
  String toString() => 'CreateUserEvent{userDto: $userDto}';
}

class UpdateUserEvent extends UserEvent {
  final UserDto userDto;
  final String id;

  const UpdateUserEvent({required this.userDto, required this.id});

  @override
  List<Object> get props => [userDto, id];

  @override
  String toString() => 'UpdateUserEvent{userDto: $userDto, id: $id}';
}

class DeleteUserEvent extends UserEvent {
  final String id;

  const DeleteUserEvent({required this.id});

  @override
  List<Object> get props => [id];

  @override
  String toString() => 'DeleteUserEvent{id: $id}';
}

class GetUserEvent extends UserEvent {
  final String id;

  const GetUserEvent({required this.id});

  @override
  List<Object> get props => [];

  @override
  String toString() => 'GetUserEvent{}';
}

class GetUserAllEvent extends UserEvent {
  final Map<String, String>? query;

  const GetUserAllEvent({this.query});

  @override
  List<Object> get props => [];

  @override
  String toString() => 'GetUserAllEvent{}';
}
