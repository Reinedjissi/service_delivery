library user;

import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'package:service_delivery/core/firebase/dto/abstract_dto.dart';
import 'package:service_delivery/core/serialisers/serializers.dart';
import 'dart:convert';

part 'user.g.dart';

abstract class UserDto implements Built<UserDto, UserDtoBuilder>, AbstractDto {
  UserDto._();

  factory UserDto([Function(UserDtoBuilder b) updates]) = _$UserDto;

  static Serializer<UserDto> get serializer => _$userDtoSerializer;

  String? get id;

  String? get email;

  String? get firstName;

  String? get lastName;

  String? get password;

  static UserDto? fromJson(String jsonString) {
    return serializers.deserializeWith(
        UserDto.serializer, json.decode(jsonString));
  }

  @override
  String toJson() {
    return json.encode(serializers.serializeWith(UserDto.serializer, this));
  }

  @override
  UserDto? toSummaryDto(jsonString) {
    return UserDto.fromJson(jsonString);
  }

  @override
  Map<String, dynamic> toJsonMap() {
    return serializers.serializeWith(UserDto.serializer, this)
        as Map<String, dynamic>;
  }

  static UserDto fromJsonMap(Map<String, dynamic> json) {
    return serializers.deserializeWith(UserDto.serializer, json) as UserDto;
  }
}
