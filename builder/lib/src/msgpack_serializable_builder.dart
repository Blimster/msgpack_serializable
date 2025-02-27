import 'dart:async';

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:build/build.dart';
import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:msgpack_annotation/msgpack_annotation.dart';
import 'package:recase/recase.dart';

bool isAnnotatedClass(Element element) {
  if (element is ClassElement) {
    final isAnnotated = element.metadata
        .map((e) => e.element)
        .whereType<ConstructorElement>()
        .map((e) => e.enclosingElement3)
        .whereType<ClassElement>()
        .where((e) => e.name == '$MsgPackSerializable')
        .toList()
        .isNotEmpty;
    return isAnnotated;
  }
  return false;
}

List<ClassElement> annotatedClasses(LibraryElement library) {
  return library.topLevelElements.where(isAnnotatedClass).cast<ClassElement>().toList();
}

class MsgPackSerializableBuilder extends Builder {
  @override
  FutureOr<void> build(BuildStep buildStep) async {
    final lib = await buildStep.inputLibrary;
    final classes = annotatedClasses(lib);
    final content = <String>[];
    for (final clazz in classes) {
      content.add(clazz.name);
    }
    if (classes.isNotEmpty) {
      final emitter = DartEmitter.scoped(
        useNullSafetySyntax: true,
      );
      final DartFormatter formatter = DartFormatter(
        languageVersion: DartFormatter.latestLanguageVersion,
        pageWidth: 120,
      );

      final library = Library((builder) {
        for (final clazz in classes) {
          final fields = clazz.fields.map((e) => (name: e.name, type: e.type)).toList();
          builder.body.add(Method((builder) {
            builder.docs.add(
                '/// void toMsgPack(Serializer serializer) => \$${clazz.name.camelCase}ToMsgPack(this, serializer);');
            builder.returns = refer('void');
            builder.name = '\$${clazz.name.camelCase}ToMsgPack';
            builder.requiredParameters.add(Parameter((builder) {
              builder.name = clazz.name.camelCase;
              builder.type = refer(clazz.name, buildStep.inputId.pathSegments.last);
            }));
            builder.requiredParameters.add(Parameter((builder) {
              builder.type = refer('Serializer', 'package:msgpack_dart/msgpack_dart.dart');
              builder.name = 'serializer';
            }));
            builder.body = Code.scope((allocate) => '''
              ${fields.map((e) => generateToMsgPack(allocate, clazz.name.camelCase, e.type, e.name)).join('\n')}
            ''');
          }));
          builder.body.add(Method((builder) {
            builder.docs.add(
                '/// factory Bar.fromMsgPack(Deserializer deserializer) => \$${clazz.name}FromMsgPack(deserializer);');
            builder.returns = refer(clazz.name, buildStep.inputId.pathSegments.last);
            builder.name = '\$${clazz.name.camelCase}FromMsgPack';
            builder.requiredParameters.add(Parameter((builder) {
              builder.type = refer('Deserializer', 'package:msgpack_dart/msgpack_dart.dart');
              builder.name = 'deserializer';
            }));
            builder.body = Code.scope((allocate) => '''
              return ${allocate(refer(clazz.name, buildStep.inputId.pathSegments.last))}(${fields.map((e) => '${e.name}: ${generateFromMsgPack(allocate, buildStep.inputId.pathSegments.last, e.type)}').join('\n')});
            ''');
          }));
        }
      });

      try {
        await buildStep.writeAsString(
            buildStep.inputId.changeExtension('.g.msgpack.dart'), formatter.format(library.accept(emitter).toString()));
      } catch (e) {
        await buildStep.writeAsString(
            buildStep.inputId.changeExtension('.g.msgpack.dart'), library.accept(emitter).toString());
      }
    }
  }

  @override
  Map<String, List<String>> get buildExtensions {
    return {
      '.dart': ['.g.msgpack.dart']
    };
  }
}

enum TypeKind {
  core,
  enumeration,
  complex,
  list,
  set,
  map,
  unsupported,
}

abstract class CodeGenerator {
  TypeKind get kind;
  bool supportsType(DartType type);
  String toMsgPack(String Function(Reference) allocate, String? prefix, DartType type, String name);
  String fromMsgPack(String Function(Reference) allocate, String package, DartType type);

  String refName(String? prefix, String name) {
    if (prefix == null) {
      return name;
    }
    return '$prefix.$name';
  }
}

class CoreCodeGenerator extends CodeGenerator {
  @override
  TypeKind get kind => TypeKind.core;

  @override
  bool supportsType(DartType type) {
    if (type.isDartCoreBool || type.isDartCoreDouble || type.isDartCoreInt || type.isDartCoreString) {
      return true;
    }
    if (type.element case ClassElement(name: 'Uint8List', library: LibraryElement(name: 'dart.typed_data'))) {
      return true;
    }
    return false;
  }

  @override
  String toMsgPack(String Function(Reference) allocate, String? prefix, DartType type, String name) {
    return 'serializer.encode(${refName(prefix, name)})';
  }

  String fromMsgPack(String Function(Reference) allocate, String package, DartType type) {
    return 'deserializer.decode()';
  }
}

class EnumerationCodeGenerator extends CodeGenerator {
  @override
  TypeKind get kind => TypeKind.enumeration;

  @override
  bool supportsType(DartType type) {
    return type.element is EnumElement;
  }

  @override
  String toMsgPack(String Function(Reference) allocate, String? prefix, DartType type, String name) {
    return 'serializer.encode(${refName(prefix, name)}.index)';
  }

  String fromMsgPack(String Function(Reference) allocate, String package, DartType type) {
    return '${allocate(refer(type.getDisplayString(), package))}.values[deserializer.decode()]';
  }
}

class ComplexCodeGenerator extends CodeGenerator {
  @override
  TypeKind get kind => TypeKind.complex;

  @override
  bool supportsType(DartType type) {
    var hasCtor = false;
    var hasToMsgPack = false;
    var hasFromMsgPack = false;

    if (type.element case ClassElement(fields: final fields, constructors: final ctors, methods: final methods)) {
      for (final ctor in ctors) {
        if (ctor
            case ConstructorElement(
              name: 'fromMsgPack',
              parameters: [
                ParameterElement(
                  type: DartType(
                    element: ClassElement(
                      name: 'Deserializer',
                      library: LibraryElement(name: 'msgpack_dart'),
                    )
                  )
                )
              ]
            )) {
          hasFromMsgPack = true;
        }
      }
      hasCtor = ctorName(ctors, fields) != null;
      for (final method in methods) {
        if (method
            case MethodElement(
              isStatic: false,
              name: 'toMsgPack',
              parameters: [
                ParameterElement(
                  type: DartType(
                    element: ClassElement(
                      name: 'Serializer',
                      library: LibraryElement(name: 'msgpack_dart'),
                    )
                  )
                )
              ],
            )) {
          hasToMsgPack = true;
        }
      }
    }

    return hasCtor && hasToMsgPack && hasFromMsgPack;
  }

  @override
  String toMsgPack(String Function(Reference) allocate, String? prefix, DartType type, String name) {
    return '${refName(prefix, name)}.toMsgPack(serializer)';
  }

  String fromMsgPack(String Function(Reference) allocate, String package, DartType type) {
    return '${allocate(refer(type.getDisplayString(), package))}.fromMsgPack(deserializer)';
  }

  String? ctorName(List<ConstructorElement> ctors, List<FieldElement> fields) {
    for (final ctor in ctors) {
      if (ctor case ConstructorElement(name: '', parameters: final params)) {
        if (params.every((param) =>
            param.isNamed && param is FieldFormalParameterElement && fields.any((field) => field.name == param.name))) {
          return ctor.name;
        }
      }
    }
    return null;
  }
}

class ListCodeGenerator extends CodeGenerator {
  @override
  TypeKind get kind => TypeKind.list;

  @override
  bool supportsType(DartType type) {
    return type.isDartCoreList;
  }

  @override
  String toMsgPack(String Function(Reference) allocate, String? prefix, DartType type, String name) {
    if (type case InterfaceType(typeArguments: [final typeArgumentType])) {
      final kind = kindForType(typeArgumentType);
      if (kind == TypeKind.core) {
        return 'serializer.encode(${refName(prefix, name)});';
      } else if (kind == TypeKind.unsupported) {
        return "throw UnsupportedError('$type $name');";
      } else {
        return '${allocate(refer('encodeList', 'package:msgpack_annotation/msgpack_annotation.dart'))}(serializer, ${refName(prefix, name)}, (serializer, item) => ${generateToMsgPack(allocate, null, typeArgumentType, 'item', embedded: true)})';
      }
    }
    return "throw UnsupportedError('$type $name');";
  }

  String fromMsgPack(String Function(Reference) allocate, String package, DartType type) {
    if (type case InterfaceType(typeArguments: [final typeArgumentType])) {
      final kind = kindForType(typeArgumentType);
      if (kind == TypeKind.core) {
        return "deserializer.decode()";
      } else if (kind == TypeKind.unsupported) {
        return "throw UnsupportedError('$type')";
      } else {
        return '${allocate(refer('decodeList', 'package:msgpack_annotation/msgpack_annotation.dart'))}(deserializer, (deserializer) => ${generateFromMsgPack(allocate, package, typeArgumentType, embedded: true)})';
      }
    }
    return "throw UnsupportedError('$type')";
  }
}

class SetCodeGenerator extends CodeGenerator {
  @override
  TypeKind get kind => TypeKind.set;

  @override
  bool supportsType(DartType type) {
    return type.isDartCoreSet;
  }

  @override
  String toMsgPack(String Function(Reference) allocate, String? prefix, DartType type, String name) {
    if (type case InterfaceType(typeArguments: [final typeArgumentType])) {
      final kind = kindForType(typeArgumentType);
      if (kind == TypeKind.core) {
        return 'serializer.encode(${refName(prefix, name)});';
      } else if (kind == TypeKind.unsupported) {
        return "throw UnsupportedError('$type $name');";
      } else {
        return '${allocate(refer('encodeSet', 'package:msgpack_annotation/msgpack_annotation.dart'))}(serializer, ${refName(prefix, name)}, (serializer, item) => ${generateToMsgPack(allocate, null, typeArgumentType, 'item', embedded: true)})';
      }
    }
    return "throw UnsupportedError('$type $name');";
  }

  String fromMsgPack(String Function(Reference) allocate, String package, DartType type) {
    if (type case InterfaceType(typeArguments: [final typeArgumentType])) {
      final kind = kindForType(typeArgumentType);
      if (kind == TypeKind.core) {
        return "deserializer.decode()";
      } else if (kind == TypeKind.unsupported) {
        return "throw UnsupportedError('$type')";
      } else {
        return '${allocate(refer('decodeSet', 'package:msgpack_annotation/msgpack_annotation.dart'))}(deserializer, (deserializer) => ${generateFromMsgPack(allocate, package, typeArgumentType, embedded: true)})';
      }
    }
    return "throw UnsupportedError('$type')";
  }
}

class MapCodeGenerator extends CodeGenerator {
  @override
  TypeKind get kind => TypeKind.map;

  @override
  bool supportsType(DartType type) {
    return type.isDartCoreMap;
  }

  @override
  String toMsgPack(String Function(Reference) allocate, String? prefix, DartType type, String name) {
    if (type case InterfaceType(typeArguments: [final typeArgumentTypeKey, final typeArgumentTypeValue])) {
      final kindKey = kindForType(typeArgumentTypeKey);
      final kindValue = kindForType(typeArgumentTypeValue);
      if (kindKey == TypeKind.unsupported || kindValue == TypeKind.unsupported) {
        return "throw UnsupportedError('$type $name')";
      } else {
        return '${allocate(refer('encodeMap', 'package:msgpack_annotation/msgpack_annotation.dart'))}(serializer, ${refName(prefix, name)}, (serializer, key) => ${generateToMsgPack(allocate, null, typeArgumentTypeKey, 'key', embedded: true)}, (serializer, value) => ${generateToMsgPack(allocate, null, typeArgumentTypeValue, 'value', embedded: true)})';
      }
    }
    return "throw UnsupportedError('$type $name');";
  }

  String fromMsgPack(String Function(Reference) allocate, String package, DartType type) {
    if (type case InterfaceType(typeArguments: [final typeArgumentTypeKey, final typeArgumentTypeValue])) {
      final kindKey = kindForType(typeArgumentTypeKey);
      final kindValue = kindForType(typeArgumentTypeValue);
      if (kindKey == TypeKind.unsupported || kindValue == TypeKind.unsupported) {
        return "throw UnsupportedError('$type')";
      } else {
        return '${allocate(refer('decodeMap', 'package:msgpack_annotation/msgpack_annotation.dart'))}(deserializer, (deserializer) => ${generateFromMsgPack(allocate, package, typeArgumentTypeKey, embedded: true)}, (deserializer) => ${generateFromMsgPack(allocate, package, typeArgumentTypeValue, embedded: true)})';
      }
    }
    return "throw UnsupportedError('$type');";
  }
}

final generators = [
  CoreCodeGenerator(),
  EnumerationCodeGenerator(),
  ComplexCodeGenerator(),
  ListCodeGenerator(),
  SetCodeGenerator(),
  MapCodeGenerator(),
];

TypeKind kindForType(DartType type) {
  for (final generator in generators) {
    if (generator.supportsType(type)) {
      return generator.kind;
    }
  }
  return TypeKind.unsupported;
}

String generateToMsgPack(
  String Function(Reference) allocate,
  String? prefix,
  DartType type,
  String name, {
  bool embedded = false,
}) {
  for (final generator in generators) {
    if (generator.supportsType(type)) {
      return '${generator.toMsgPack(allocate, prefix, type, name)}${!embedded ? ';' : ''}';
    }
  }

  return "throw UnsupportedError('$type $name')}${!embedded ? ';' : ''}";
}

String generateFromMsgPack(
  String Function(Reference) allocate,
  String package,
  DartType type, {
  bool embedded = false,
}) {
  for (final generator in generators) {
    if (generator.supportsType(type)) {
      return '${generator.fromMsgPack(allocate, package, type)}${!embedded ? ',' : ''}';
    }
  }

  return "throw UnsupportedError('')${!embedded ? ',' : ''}";
}
