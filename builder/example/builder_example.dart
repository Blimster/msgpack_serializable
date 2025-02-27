import 'package:msgpack_annotation/msgpack_annotation.dart';

import 'builder_example.g.msgpack.dart';

@MsgPackSerializable()
class Customer {
  final CustomerId id;
  final String name;

  Customer({required this.id, required this.name});

  factory Customer.fromMsgPack(Deserializer deserializer) => $customerFromMsgPack(deserializer);

  void toMsgPack(Serializer serializer) => $customerToMsgPack(this, serializer);

  @override
  String toString() => 'Customer(id: $id, name: $name)';
}

@MsgPackSerializable()
class CustomerId {
  final String id;

  CustomerId({required this.id});

  factory CustomerId.fromMsgPack(Deserializer deserializer) => $customerIdFromMsgPack(deserializer);

  void toMsgPack(Serializer serializer) => $customerIdToMsgPack(this, serializer);

  @override
  String toString() => 'CustomerId(id: $id)';
}

void main() {
  final customer = Customer(
    id: CustomerId(id: '1910'),
    name: 'FC St. Pauli',
  );

  final serializer = Serializer();
  customer.toMsgPack(serializer);
  final bytes = serializer.takeBytes();

  final deserializer = Deserializer(bytes);
  final newCustomer = Customer.fromMsgPack(deserializer);

  print(newCustomer);
}
