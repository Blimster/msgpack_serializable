import 'package:meta/meta_meta.dart';
import 'package:msgpack_dart/msgpack_dart.dart';

export 'package:msgpack_dart/msgpack_dart.dart';

/// Annotate a class with `@MsgPackSerializable` to generate serialization code.
@Target({TargetKind.classType})
class MsgPackSerializable {
  const MsgPackSerializable();
}

/// Encodes a list to the MessagePack format. This function is helper for the [MsgPack] serializable builder.
void encodeList(Serializer serializer, List list, void Function(Serializer, dynamic) itemEncoder) {
  serializer.encode(list.length);
  for (final item in list) {
    itemEncoder(serializer, item);
  }
}

/// Decodes a list from the MessagePack format. This function is helper for the [MsgPack] serializable builder.
List<T> decodeList<T>(Deserializer deserializer, T Function(Deserializer) itemDecoder) {
  final result = <T>[];
  final length = deserializer.decode() as int;
  for (var i = 0; i < length; i++) {
    result.add(itemDecoder(deserializer));
  }
  return result;
}

/// Encodes a set to the MessagePack format. This function is helper for the [MsgPack] serializable builder.
void encodeSet(Serializer serializer, Set set, void Function(Serializer, dynamic) itemEncoder) {
  serializer.encode(set.length);
  for (final item in set) {
    itemEncoder(serializer, item);
  }
}

/// Decodes a set from the MessagePack format. This function is helper for the [MsgPack] serializable builder.
Set<T> decodeSet<T>(Deserializer deserializer, T Function(Deserializer) itemDecoder) {
  final result = <T>{};
  final length = deserializer.decode() as int;
  for (var i = 0; i < length; i++) {
    result.add(itemDecoder(deserializer));
  }
  return result;
}

/// Encodes a map to the MessagePack format. This function is helper for the [MsgPack] serializable builder.
void encodeMap(Serializer serializer, Map map, void Function(Serializer, dynamic) keyEncoder,
    void Function(Serializer, dynamic) valueEncoder) {
  serializer.encode(map.length);
  for (final entry in map.entries) {
    keyEncoder(serializer, entry.key);
    valueEncoder(serializer, entry.value);
  }
}

/// Decodes a map from the MessagePack format. This function is helper for the [MsgPack] serializable builder.
Map<K, V> decodeMap<K, V>(
    Deserializer deserializer, K Function(Deserializer) keyDecoder, V Function(Deserializer) valueDecoder) {
  final result = <K, V>{};
  final length = deserializer.decode() as int;
  for (var i = 0; i < length; i++) {
    final key = keyDecoder(deserializer);
    final value = valueDecoder(deserializer);
    result[key] = value;
  }
  return result;
}
