library serializers;

import 'package:built_collection/built_collection.dart';
import 'package:built_value/serializer.dart';
import 'package:built_value/standard_json_plugin.dart';
import 'package:service_delivery/app/users/models/user.dart';

part 'serializers.g.dart';

@SerializersFor([
  UserDto
])

final Serializers serializers = (_$serializers.toBuilder()
  ..addPlugin(StandardJsonPlugin())
  ..addBuilderFactory(
      const FullType(BuiltList, [FullType(String)]),
          () => new ListBuilder<String>())
)
    .build();