import 'serializer.dart';
import 'deserializer.dart';

/// Datamodel baseclass or interface for storage.
/// 
/// Best practice example:
/// 
/// ```dart
/// class Person implements Model {
///   static final String type = 'person';
///   final String firstName;
///   final String lastName;
///   final DateTime birthday;
/// 
///   Person(this.firstName, this.lastName, this.birthday);
/// 
///   Serializer encode([Serializer serialize]) =>
///     (serialize ?? Serializer(type))
///       .string(firstName)
///       .string(lastName)
///       .string(birthday.toIso8601String());
/// 
///   Person.decode(Deserializer deserialize)
///     : firstName = deserialize.string(),
///       lastName = deserialize.string(),
///       birthday = DateTime.parse(deserialize.string());
/// }
/// ```
/// 
/// This allows to check the [Person.type] against [Deserializer.meta.type] 
/// before calling [Person.decode(deserialize)].
/// 
/// This allows fruther to performed serialization with or without 
/// providing a [Serializer] instance.
/// 
/// Reusing another [Serializer] comes handy when encoding nested data models.
/// 
abstract class Model {
  String type;
  int version;
  Serializer encode(Serializer serialize);
  factory Model.decode(String type, int version, Deserializer deserialize) {
    return null;
  }
}