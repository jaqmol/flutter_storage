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