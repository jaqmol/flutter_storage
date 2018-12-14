import 'dart:convert' as c;

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
  static String type;
  Model();
  Serializer encode([Serializer serialize]);
  Model.decode(Deserializer deserialize);
}

/// Serializer used to encode Dart datamodels for storage
/// 
class Serializer {
  final List<String> _components;
  final Metadata meta;

  /// Initialize a serializer
  /// 
  /// The [type] parameter is mandatory and is used to identify
  /// the encoded data during decoding.
  /// 
  /// The [version] parameter can optionally be used to identify
  /// a specific version of encoded data during decoding.
  /// 
  /// Serialization is done by calling the methods
  /// [raw(…)], [string(…)], [bytes(…)], [boolean(…)], [integer(…)], [float(…)], [collection(…)],
  /// in sequence, thus serializing the fields of a model.
  /// 
  /// Using a [Deserializer] instance and call the equivalent methods
  /// on it in the same order to deserialize a model.
  /// 
  factory Serializer(String type, {int version: 0}) {
    var components = List<String>();
    var meta = Metadata(type, version, List<int>(), 0);
    return Serializer._init(components, meta);
  }

  Serializer._init(this._components, this.meta) {
    meta._edges.add(0);
  }

  /// Call the serializer as a function to encode all
  /// components provided in the previous
  /// serialization sequence.
  /// 
  String call() {
    _components.insert(0, meta.toString());
    String serializedLine = _components.join('');
    _components.clear();
    return serializedLine;
  }

  Serializer _component(String component) {
    _components.add(component);
    meta._edges.add(meta._edges.last + component.length);
    return this;
  }

  /// Serialize raw strings without subsequent base64-encoding.
  /// The payload must not contain newline characters.
  /// 
  Serializer raw(String component) {
    assert(
      !component.contains('\n') && !component.contains('\r'),
      "Raw strings must not contain newline characters.",
    );
    return _component(component);
  }

  /// Serialize a [Model] instance using it's [encode(…)] method.
  /// Handy to chain serializer calls.
  /// 
  Serializer model(Model model) {
    return model.encode(this);
  }

  /// Serialize a string value. The payload will be base64-encoded for storage.
  /// 
  Serializer string(String component) {
    return _component(c.base64.encode(c.utf8.encode(component)));
  }

  /// Serialize a byte array.
  /// 
  Serializer bytes(List<int> component) {
    return _component(c.base64.encode(component));
  }

  /// Serialize a boolean value.
  /// 
  Serializer boolean(bool component) {
    return _component(component ? 'T' : 'F');
  }

  /// Serialize an integer value.
  /// 
  Serializer integer(int component) {
    return _component(component.toRadixString(16));
  }

  /// Serialize a float value.
  /// 
  Serializer float(double component) {
    return _component(component.toString());
  }

  /// Serialize a collection value.
  /// 
  /// Provide the collection of payloads to be encoded,
  /// plus an [encodeFn]. The [encodeFn] will be called
  /// with this serializer instance and each element 
  /// of the collection.
  /// 
  Serializer collection<T>(
    List<T> components,
    void encodeFn(Serializer s, T item),
  ) {
    integer(components.length);
    for (T c in components) encodeFn(this, c);
    return this;
  }
}

/// Deserializer used to decode Dart datamodels from storage
/// 
class Deserializer {
  final String _content;
  final Metadata meta;
  final int _lastEdgeIndex;
  int _edgeIndex = 0;

  /// Initialize a deserializer
  /// 
  /// The [stringValue] parameter is the serialized 
  /// representation of a Dart datamodel.
  /// 
  /// After initialization the [meta] fiedl can be used to identify
  /// the [type] and optionally the [version] of the model.
  /// 
  /// Deserialization is done by calling the methods
  /// [raw(…)], [string(…)], [bytes(…)], [boolean(…)], [integer(…)], [float(…)], [collection(…)],
  /// in sequence, thus retrieving the fields of a model.
  /// 
  /// Using a [Serializer] instance and call the equivalent methods
  /// on it in the same order to serialize a model.
  /// 
  factory Deserializer(String stringValue) {
    var meta = Metadata.fromString(stringValue);
    var content = stringValue.substring(meta._contentStart);
    return Deserializer._init(meta, content);
  }

  Deserializer._init(this.meta, this._content)
    : _lastEdgeIndex = meta._edges.length - 1;

  String _component() {
    assert(_edgeIndex < _lastEdgeIndex);
    int start = meta._edges[_edgeIndex];
    int end = meta._edges[_edgeIndex + 1];
    _edgeIndex++;
    return _content.substring(start, end);
  }

  /// Deserialize raw strings without previous base64-decoding.
  /// 
  String raw() => _component();
  
  /// Deserialize a string value. The payload will be decoded from a base64-encoded storage representation.
  ///
  String string() {
    String comp = _component();
    return c.utf8.decode(c.base64.decode(comp));
  }

  /// Deserialize a byte array.
  ///
  List<int> bytes() {
    String comp = _component();
    return c.base64.decode(comp);
  }

  /// Deserialize a boolean value.
  /// 
  bool boolean() {
    String comp = _component();
    return comp == 'T';
  }

  /// Deserialize an integer value.
  ///
  int integer() {
    String comp = _component();
    return int.parse(comp, radix: 16);
  }

  /// Deserialize a float value.
  ///
  double float() {
    String comp = _component();
    return double.parse(comp);
  }

  /// Deserialize a collection value.
  /// 
  /// The [decodeFn] will be called
  /// with this deserializer instance for each element 
  /// of the collection that is decoded.
  ///
  List<T> collection<T>(T decodeFn(Deserializer d)) {
    return List<T>.generate(
      integer(),
      (_) => decodeFn(this),
    );
  }
}

/// Serialization metadata
/// 
/// Can be accessed via the [meta] field of a Deserializer instance.
/// Used to identify the [type] and [version] of encoded data.
///
class Metadata {
  /// The type of the encoded data.
  final String type;
  /// The version of the encoded data.
  final int version;
  final List<int> _edges;
  final int _contentStart;

  Metadata(this.type, this.version, this._edges, this._contentStart);

  String toString() {
    var buffer = StringBuffer();
    buffer.write(c.base64.encode(c.utf8.encode(type)));
    buffer.write(_MetaSeparator.value);
    buffer.write(version.toRadixString(16));
    buffer.write(_MetaSeparator.value);
    buffer.write(_edges
      .map((int v) => v.toRadixString(16))
      .join(_MetaSeparator.edge),
    );
    buffer.write(_MetaSeparator.content);
    return buffer.toString();
  }

  factory Metadata.fromString(String content) {
    int ti = content.indexOf(_MetaSeparator.value);
    String type = c.utf8.decode(c.base64.decode(
      content.substring(0, ti),
    ));
    ti++;
    int vi = content.indexOf(_MetaSeparator.value, ti);
    int version = int.parse(
      content.substring(ti, vi),
      radix: 16,
    );
    vi++;
    int ci = content.indexOf(_MetaSeparator.content, vi);
    List<int> edges = content.substring(vi, ci)
      .split(_MetaSeparator.edge)
      .map((var v) => int.parse(v, radix: 16))
      .toList();
    return Metadata(type, version, edges, ci + _MetaSeparator.content.length);
  }
}

abstract class _MetaSeparator {
  static final String content = '#%#';
  static final String value = '|';
  static final String edge = ',';
}