import 'package:service_delivery/app/users/models/user.dart';
import 'package:service_delivery/core/firebase/abstraction_crud.dart';

class UserRepository extends AbstractionCrud<UserDto>{
  @override
  String collectionName() {
    return "user";
  }

  @override
  UserDto? toSummaryDto(json) {
    return UserDto.fromJson(json);
  }

}