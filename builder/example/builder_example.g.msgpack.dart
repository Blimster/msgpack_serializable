// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'builder_example.dart' as _i1;
import 'package:msgpack_dart/msgpack_dart.dart' as _i2;

/// void toMsgPack(Serializer serializer) => $customerToMsgPack(this, serializer);
void $customerToMsgPack(_i1.Customer customer, _i2.Serializer serializer) {
  customer.id.toMsgPack(serializer);
  serializer.encode(customer.name);
}

/// factory Customer.fromMsgPack(Deserializer deserializer) => $customerFromMsgPack(deserializer);
_i1.Customer $customerFromMsgPack(_i2.Deserializer deserializer) {
  return _i1.Customer(id: _i1.CustomerId.fromMsgPack(deserializer), name: deserializer.decode());
}

/// void toMsgPack(Serializer serializer) => $customerIdToMsgPack(this, serializer);
void $customerIdToMsgPack(_i1.CustomerId customerId, _i2.Serializer serializer) {
  serializer.encode(customerId.id);
}

/// factory CustomerId.fromMsgPack(Deserializer deserializer) => $customerIdFromMsgPack(deserializer);
_i1.CustomerId $customerIdFromMsgPack(_i2.Deserializer deserializer) {
  return _i1.CustomerId(id: deserializer.decode());
}
