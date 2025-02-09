// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'builder_example.dart' as _i1;
import 'package:msgpack_dart/msgpack_dart.dart' as _i2;
import 'package:msgpack_annotation/msgpack_annotation.dart' as _i3;

/// Customer
void $customerToMsgPack(_i1.Customer customer, _i2.Serializer serializer) {
  serializer.encode(customer.id);
  serializer.encode(customer.name);
  serializer.encode(customer.data);
  serializer.encode(customer.foo.index);
  customer.bar.toMsgPack(serializer);
}

/// Customer
_i1.Customer $customerFromMsgPack(_i2.Deserializer deserializer) {
  return _i1.Customer(
    id: deserializer.decode(),
    name: deserializer.decode(),
    data: deserializer.decode(),
    foo: _i1.Foo.values[deserializer.decode()],
    bar: _i1.Bar.fromMsgPack(deserializer),
  );
}

/// Bar
void $barToMsgPack(_i1.Bar bar, _i2.Serializer serializer) {
  serializer.encode(bar.bar);
  _i3.encodeList(serializer, bar.list, (serializer, item) => item.toMsgPack(serializer));
  _i3.encodeMap(
    serializer,
    bar.map,
    (serializer, key) => serializer.encode(key),
    (serializer, value) => value.toMsgPack(serializer),
  );
}

/// Bar
_i1.Bar $barFromMsgPack(_i2.Deserializer deserializer) {
  return _i1.Bar(
    bar: deserializer.decode(),
    list: _i3.decodeList(deserializer, (deserializer) => _i1.FooBar.fromMsgPack(deserializer)),
    map: _i3.decodeMap(
      deserializer,
      (deserializer) => deserializer.decode(),
      (deserializer) => _i1.FooBar.fromMsgPack(deserializer),
    ),
  );
}

/// FooBar
void $fooBarToMsgPack(_i1.FooBar fooBar, _i2.Serializer serializer) {}

/// FooBar
_i1.FooBar $fooBarFromMsgPack(_i2.Deserializer deserializer) {
  return _i1.FooBar();
}
