import 'entry_info.dart';

/// Deserializer used to decode Dart datamodels from storage
/// 
abstract class Deserializer {
  EntryInfo get entryInfo;

  /// Deserialize a string value. The payload will be decoded from a base64-encoded storage representation.
  ///
  String string();

  /// Deserialize a byte array.
  ///
  List<int> bytes();

  /// Deserialize a boolean value.
  /// 
  bool boolean();

  /// Deserialize an integer value.
  ///
  int integer();

  /// Deserialize a float value.
  ///
  double float();

  /// Deserialize a list value.
  /// 
  /// The [decodeFn] will be called
  /// with this deserializer instance for each item 
  /// of the list that is decoded.
  ///
  List<T> list<T>(T decodeFn());

  /// Deserialize a map value.
  /// 
  /// The [decodeFn] will be called
  /// with this deserializer instance for each key and value 
  /// of the map that is decoded.
  ///
  Map<K, V> map<K, V>(MapEntry<K, V> decodeFn());
}
