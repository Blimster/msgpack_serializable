# MessagePack Serializable

## Overview

This project provides an implementation for serializing and deserializing objects using MessagePack.

## Installation

To install the project, run the following command:

```bash
dart pub get
```

## Build

To generate the necessary files, run the following command:

```bash
dart run build_runner build
```

## Usage

Here is a simple example of how to use the `MessagePackSerializable` class:

```dart
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
```

## License

This project is licensed under the MIT License. For more information, see the `LICENSE` file.
