import 'dart:typed_data';

import 'package:msgpack_annotation/msgpack_annotation.dart';

import 'builder_example.g.msgpack.dart';

enum Foo {
  foo,
  bar;
}

@MsgPackSerializable()
class Customer {
  final int id;
  final String name;
  final Uint8List data;
  final Foo foo;
  final Bar bar;

  Customer({required this.id, required this.name, required this.data, required this.foo, required this.bar});

  void toMsgPack(Serializer serializer) => $customerToMsgPack(this, serializer);
}

@MsgPackSerializable()
class Bar {
  final String bar;
  final List<FooBar> list;
  final Map<String, FooBar> map;

  Bar({required this.bar, required this.list, required this.map});

  factory Bar.fromMsgPack(Deserializer deserializer) => $barFromMsgPack(deserializer);

  void toMsgPack(Serializer serializer) => $barToMsgPack(this, serializer);
}

@MsgPackSerializable()
class FooBar {
  FooBar();
  factory FooBar.fromMsgPack(Deserializer deserializer) => $fooBarFromMsgPack(deserializer);
  void toMsgPack(Serializer serializer) {}
}

void main() {
  final customer = Customer(
    id: 1,
    name: 'name',
    data: Uint8List.fromList([1, 2, 3]),
    foo: Foo.bar,
    bar: Bar(bar: 'bar', list: [FooBar()], map: {}),
  );
  final serializer = Serializer();
  customer.toMsgPack(serializer);
  final bytes = serializer.takeBytes();
  print(bytes);
}
