# MessagePack Serializable

A Dart library that automatically generates MessagePack serialization code for your classes, providing an efficient binary serialization format for your data.

## Overview

This package consists of two main components:

- **msgpack_annotation**: Contains the annotations and helper methods needed for serialization
- **msgpack_serializable**: A code generator that creates serialization/deserialization code for annotated classes

## Installation

Add both the annotation and builder packages to your `pubspec.yaml`:

```yaml
dependencies:
  msgpack_annotation: ^0.1.0
  msgpack_dart: ^1.0.1

dev_dependencies:
  build_runner: ^2.4.0
  msgpack_serializable: ^0.1.0
```

## Usage

### 1. Annotate your classes

Add the `@MsgPackSerializable()` annotation to classes you want to serialize:

```dart
import 'package:msgpack_annotation/msgpack_annotation.dart';

// Import the generated code file
import 'your_file.g.msgpack.dart';

@MsgPackSerializable()
class Person {
  final String name;
  final int age;
  
  Person({required this.name, required this.age});
  
  // Add serialization methods that delegate to the generated code
  factory Person.fromMsgPack(Deserializer deserializer) => 
      $personFromMsgPack(deserializer);
      
  void toMsgPack(Serializer serializer) => 
      $personToMsgPack(this, serializer);
}
```

### 2. Generate the serialization code

Run the build_runner to generate the serialization code:

```bash
dart run build_runner build
```

This creates a `.g.msgpack.dart` file with the serialization logic.

### 3. Use the serialization

```dart
// Serialization
final person = Person(name: 'Alice', age: 30);
final serializer = Serializer();
person.toMsgPack(serializer);
final bytes = serializer.takeBytes();

// Deserialization
final deserializer = Deserializer(bytes);
final newPerson = Person.fromMsgPack(deserializer);
```

## Supported Types

The library supports the following types:

- Core types: `bool`, `int`, `double`, `String`, and `Uint8List`
- Collections: `List<T>`, `Set<T>`, `Map<K, V>`
- Enums
- Nested classes that are also serializable

## Example

See the [builder example](builder/example/builder_example.dart) for a complete working example:

```dart
import 'package:msgpack_annotation/msgpack_annotation.dart';

import 'builder_example.g.msgpack.dart';

@MsgPackSerializable()
class Customer {
  final CustomerId id;
  final String name;

  Customer({required this.id, required this.name});

  factory Customer.fromMsgPack(Deserializer deserializer) => 
      $customerFromMsgPack(deserializer);

  void toMsgPack(Serializer serializer) => 
      $customerToMsgPack(this, serializer);

  @override
  String toString() => 'Customer(id: $id, name: $name)';
}

@MsgPackSerializable()
class CustomerId {
  final String id;

  CustomerId({required this.id});

  factory CustomerId.fromMsgPack(Deserializer deserializer) => 
      $customerIdFromMsgPack(deserializer);

  void toMsgPack(Serializer serializer) => 
      $customerIdToMsgPack(this, serializer);

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

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
