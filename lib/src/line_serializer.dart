import 'dart:io';
import 'serializer.dart';
import 'model.dart';
import 'escaping.dart';
import 'package:meta/meta.dart';
import 'entry_info.dart';
import 'entry_info_private.dart';
import 'index.dart';

String _notOpenErrorMsg = "Attempted write operation on concluded Serializer!";

class LineSerializer implements Serializer {
  final RandomAccessFile _raf;
  final _startIndex;
  final EntryInfo entryInfo;
  bool _isOpen;

  LineSerializer.serializeIndex({
    @required RandomAccessFile raf,
    @required Index index,
  }): assert(raf != null),
      assert(index != null),
      _raf = raf,
      _startIndex = raf.positionSync(),
      entryInfo = IndexInfo(index.version),
      _isOpen = true {
        _raf.writeStringSync(entryInfo.toString());
        index.encode(this);
      }

  LineSerializer.model({
    @required RandomAccessFile raf,
    @required String key,
    @required String modelType,
    @required int modelVersion,
  }): assert(raf != null),
      assert(key != null),
      assert(modelType != null),
      assert(modelVersion != null),
      _raf = raf,
      _startIndex = raf.positionSync(),
      entryInfo = ModelInfo(
        modelType: modelType,
        modelVersion: modelVersion,
        key: key,
      ),
      _isOpen = true {
        _raf.writeStringSync(entryInfo.toString());
      }

  LineSerializer.value({
    @required RandomAccessFile raf,
    @required String key,
  }): assert(raf != null),
      assert(key != null),
      _raf = raf,
      _startIndex = raf.positionSync(),
      entryInfo = ValueInfo(key),
      _isOpen = true {
        _raf.writeStringSync(entryInfo.toString());
      }

  Serializer model(Model model) {
    assert(_isOpen = true, _notOpenErrorMsg);
    _raf.writeStringSync(ModelInfo(
      modelType: model.type,
      modelVersion: model.version,
    ).toString());
    return this;
  }

  Serializer string(String component) {
    assert(_isOpen = true, _notOpenErrorMsg);
    _raf.writeStringSync(';');
    _raf.writeStringSync(escapeString(component));
    return this;
  }

  Serializer bytes(Iterable<int> component) {
    assert(_isOpen = true, _notOpenErrorMsg);
    _raf.writeStringSync(';');
    _raf.writeFromSync(escapeBytes(component));
    return this;
  }

  Serializer boolean(bool component) {
    assert(_isOpen = true, _notOpenErrorMsg);
    _raf.writeStringSync(';');
    _raf.writeStringSync(component ? 'T' : 'F');
    return this;
  }

  Serializer integer(int component) {
    assert(_isOpen = true, _notOpenErrorMsg);
    _raf.writeStringSync(';');
    _raf.writeStringSync(component.toRadixString(16));
    return this;
  }

  Serializer float(double component) {
    assert(_isOpen = true, _notOpenErrorMsg);
    _raf.writeStringSync(';');
    _raf.writeStringSync(radixEncodeFloat(component));
    return this;
  }

  Serializer list<T>(
    Iterable<T> components,
    void encodeFn(T item),
  ) {
    assert(_isOpen = true, _notOpenErrorMsg);
    integer(components.length);
    for (T c in components) {
      encodeFn(c);
    }
    return this;
  }

  Serializer map<K, V>(
    Map<K, V> components,
    void encodeFn(K k, V v),
  ) {
    assert(_isOpen = true, _notOpenErrorMsg);
    integer(components.length);
    for (MapEntry<K, V> c in components.entries) {
      encodeFn(c.key, c.value);
    }
    return this;
  }

  int conclude() {
    if (_isOpen) {
      _raf.writeStringSync('\n');
      _isOpen = false;
    }
    return _startIndex;
  }

  bool get isOpen => _isOpen;
}
