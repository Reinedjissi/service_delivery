import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:service_delivery/app/users/bloc/user_event.dart';
import 'package:service_delivery/app/users/bloc/user_state.dart';
import 'package:service_delivery/app/users/repository/repository.dart';

class UserBloc extends Bloc<UserEvent, UserState> {
  final UserRepository _userService;

  UserBloc()
      : _userService = UserRepository(),
        super(UserInitialState()) {
    on((event, emit) => emit(UserLoading()));
    on<CreateUserEvent>(_createUser);
    on<UpdateUserEvent>(_updateUser);
    on<DeleteUserEvent>(_deleteUser);
  }

  _createUser(CreateUserEvent event, Emitter<UserState> emitter) async {
    try {
      await _userService.create(event.userDto);
      emitter(UserLoadingSuccess());
    } catch (e) {
      emitter(UserLoadingFailure(errorMessage: e.toString()));
    }
  }

  _updateUser(UpdateUserEvent event, Emitter<UserState> emitter) async {
    try {
      await _userService.update(event.id, event.userDto);
      emitter(UserLoadingSuccess());
    } catch (e) {
      emitter(UserLoadingFailure(errorMessage: e.toString()));
    }
  }

  _deleteUser(DeleteUserEvent event, Emitter<UserState> emitter) async {
    try {
      await _userService.delete(event.id);
      emitter(UserLoadingSuccess());
    } catch (e) {
      emitter(UserLoadingFailure(errorMessage: e.toString()));
    }
  }
}
