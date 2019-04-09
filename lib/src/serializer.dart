import 'model.dart';

abstract class Serializer {
  // /// Serialize raw strings without subsequent base64-encoding.
  // /// The payload must not contain newline characters.
  // /// 
  // Serializer raw(String component);

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

  /// Serialize a collection value.
  /// 
  /// Provide the collection of payloads to be encoded,
  /// plus an [encodeFn]. The [encodeFn] will be called
  /// with this serializer instance and each element 
  /// of the collection.
  /// 
  Serializer collection<T>(
    Iterable<T> components,
    void encodeFn(Serializer s, T item),
  );
}