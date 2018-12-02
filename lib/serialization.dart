import 'dart:convert' as c;

class Serializer {
  final List<String> _components;
  final Metadata meta;

  factory Serializer(String type, {int version: 0}) {
    var components = List<String>();
    var meta = Metadata(type, version, List<int>(), 0);
    return Serializer._init(components, meta);
  }

  Serializer._init(this._components, this.meta) {
    meta._edges.add(0);
  }

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

  Serializer raw(String component) {
    assert(
      !component.contains('\n') && !component.contains('\r'),
      "Raw strings must not contain newline characters.",
    );
    return _component(component);
  }

  Serializer string(String component) {
    return _component(c.base64.encode(c.utf8.encode(component)));
  }

  Serializer bytes(List<int> component) {
    return _component(c.base64.encode(component));
  }

  Serializer boolean(bool component) {
    return _component(component ? 'T' : 'F');
  }

  Serializer integer(int component) {
    return _component(component.toRadixString(16));
  }

  Serializer float(double component) {
    return _component(component.toString());
  }

  Serializer collection<T>(
    List<T> components,
    void encodeFn(Serializer s, T item),
  ) {
    integer(components.length);
    for (T c in components) encodeFn(this, c);
    return this;
  }
}

class Deserializer {
  final String _content;
  final Metadata meta;
  final int _lastEdgeIndex;
  int _edgeIndex = 0;

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

  String raw() => _component();

  String string() {
    String comp = _component();
    return c.utf8.decode(c.base64.decode(comp));
  }

  List<int> bytes() {
    String comp = _component();
    return c.base64.decode(comp);
  }

  bool boolean() {
    String comp = _component();
    return comp == 'T';
  }

  int integer() {
    String comp = _component();
    return int.parse(comp, radix: 16);
  }

  double float() {
    String comp = _component();
    return double.parse(comp);
  }

  List<T> collection<T>(T decodeFn(Deserializer d)) {
    return List<T>.generate(
      integer(),
      (_) => decodeFn(this),
    );
  }
}

class Metadata {
  final String type;
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

abstract class Model {
  static String type;
  Model();
  Serializer encode([Serializer serialize]);
  Model.decode(Deserializer deserialize);
}