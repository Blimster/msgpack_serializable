import 'package:build/build.dart';

import 'src/msgpack_serializable_builder.dart';

Builder msgPackSerializableBuilder(BuilderOptions options) {
  return MsgPackSerializableBuilder();
}
