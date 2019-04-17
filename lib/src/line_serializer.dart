import 'dart:io';
import 'serializer.dart';
import 'model.dart';
import 'escaping.dart';
import 'package:meta/meta.dart';
import 'entry_info.dart';
import 'index.dart';

class LineSerializer implements Serializer {
  final RandomAccessFile _raf;
  final _startIndex;

  LineSerializer.index({
    @required RandomAccessFile raf,
    @required Index index,
  })
    : assert(raf != null),
      assert(index != null),
      _raf = raf,
      _startIndex = raf.positionSync() {
        _raf.writeStringSync(IndexInfo().toString());
        index.encode(this);
      }

  LineSerializer.model({
    @required RandomAccessFile raf,
    @required String key,
    @required Model model,
  })
    : assert(raf != null),
      assert(key != null),
      assert(model != null),
      _raf = raf,
      _startIndex = raf.positionSync() {
        this.model(model, key);
      }

  LineSerializer.value({
    @required RandomAccessFile raf,
    @required String key,
  })
    : assert(raf != null),
      assert(key != null),
      _raf = raf,
      _startIndex = raf.positionSync() {
        _raf.writeStringSync(ValueInfo(key).toString());
      }

  LineSerializer.remove({
    @required RandomAccessFile raf,
    @required String key,
  })
    : assert(raf != null),
      _raf = raf,
      _startIndex = raf.positionSync() {
        _raf.writeStringSync(RemoveInfo(key).toString());
      }

  Serializer model(Model model, [String key]) {
    _raf.writeStringSync(ModelInfo(
      modelType: model.type,
      modelVersion: model.version,
      key: key,
    ).toString());
    return this;
  }

  Serializer string(String component) {
    _raf.writeStringSync(';');
    _raf.writeStringSync(escapeString(component));
    return this;
  }

  Serializer bytes(Iterable<int> component) {
    _raf.writeStringSync(';');
    _raf.writeFromSync(escapeBytes(component));
    return this;
  }

  Serializer boolean(bool component) {
    _raf.writeStringSync(';');
    _raf.writeStringSync(component ? 'T' : 'F');
    return this;
  }

  Serializer integer(int component) {
    _raf.writeStringSync(';');
    _raf.writeStringSync(component.toRadixString(16));
    return this;
  }

  Serializer float(double component) {
    _raf.writeStringSync(';');
    _raf.writeStringSync(radixEncodeFloat(component));
    return this;
  }

  Serializer list<T>(
    Iterable<T> components,
    void encodeFn(T item),
  ) {
    integer(components.length);
    _raf.writeStringSync(';');
    for (T c in components) {
      encodeFn(c);
    }
    return this;
  }

  Serializer map<K, V>(
    Map<K, V> components,
    void encodeFn(K k, V v),
  ) {
    integer(components.length);
    _raf.writeStringSync(';');
    for (MapEntry<K, V> c in components.entries) {
      encodeFn(c.key, c.value);
    }
    return this;
  }

  int conclude() {
    _raf.writeStringSync('\n');
    return _startIndex;
  }
}
