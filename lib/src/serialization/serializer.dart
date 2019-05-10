import 'model.dart';
import 'dart:async';

abstract class Serializer {
  /// Serialize a [Model] instance using it's [encode(…)] method.
  /// Handy to chain serializer calls.
  /// 
  Serializer model(Model model);

  /// Serialize a string value. The payload will be base64-encoded for storage.
  /// 
  Serializer string(String component);

  /// Serialize a byte array.
  /// 
  Serializer bytes(List<int> component);

  /// Serialize a boolean value.
  /// 
  Serializer boolean(bool component);

  /// Serialize an integer value.
  /// 
  Serializer integer(int component);

  /// Serialize a float value.
  /// 
  Serializer float(double component);

  /// Serialize a list value.
  /// 
  /// Provide the list of items to be encoded,
  /// plus an [encodeFn]. The [encodeFn] will be called
  /// with this serializer instance and each item 
  /// of the list.
  /// 
  Serializer list<T>(
    Iterable<T> components,
    void encodeFn(T item),
  );

  /// Serialize a map value.
  /// 
  /// Provide the map of entries to be encoded,
  /// plus an [encodeFn]. The [encodeFn] will be called
  /// with this serializer instance and each key and value
  /// of the map.
  /// 
  Serializer map<K, V>(
    Map<K, V> components,
    void encodeFn(K k, V v),
  );

  /// Conclude the write operation.
  /// 
  /// Always finish writing of values with [conclude].
  /// 
  Future conclude();
}