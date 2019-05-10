import 'dart:io';
import 'serializer.dart';
import 'model.dart';
import 'escaping.dart';
import 'package:meta/meta.dart';
import 'entry_info.dart';
import 'entry_info_private.dart';
import 'dart:async';
import 'dart:convert';
import 'control_chars.dart';

String _notOpenErrorMsg = "Attempted write operation on concluded Serializer!";

typedef void StartIndexCallback(int startIndex);

class LineSerializer implements Serializer {
  final StreamSink<List<int>> _sink;
  final startIndex;
  final EntryInfo entryInfo;
  bool _isOpen;

  LineSerializer.index({
    @required StreamSink<List<int>> sink,
    @required int indexVersion,
    @required this.startIndex,
  }): assert(sink != null),
      assert(indexVersion != null),
      assert(startIndex != null),
      _sink = sink,
      entryInfo = IndexInfo(indexVersion),
      _isOpen = true {
        _sink.add(utf8.encode(entryInfo.toString()));
      }

  LineSerializer.model({
    @required StreamSink<List<int>> sink,
    @required String key,
    @required String modelType,
    @required int modelVersion,
    @required this.startIndex,
  }): assert(sink != null),
      assert(key != null),
      assert(modelType != null),
      assert(modelVersion != null),
      assert(startIndex != null),
      _sink = sink,
      entryInfo = ModelInfo(
        modelType: modelType,
        modelVersion: modelVersion,
        key: key,
      ),
      _isOpen = true {
        _sink.add(utf8.encode(entryInfo.toString()));
      }

  LineSerializer.value({
    @required StreamSink<List<int>> sink,
    @required String key,
    @required this.startIndex,
  }): assert(sink != null),
      assert(key != null),
      assert(startIndex != null),
      _sink = sink,
      entryInfo = ValueInfo(key),
      _isOpen = true {
        _sink.add(utf8.encode(entryInfo.toString()));
      }

  Serializer model(Model model) {
    assert(_isOpen = true, _notOpenErrorMsg);
    _sink.add(utf8.encode(ModelInfo(
      modelType: model.type,
      modelVersion: model.version,
    ).toString()));
    return this;
  }

  Serializer string(String component) {
    assert(_isOpen = true, _notOpenErrorMsg);
    _sink.add(ControlChars.semicolonBytes);
    _sink.add(utf8.encode(escapeString(component)));
    return this;
  }

  Serializer bytes(Iterable<int> component) {
    assert(_isOpen = true, _notOpenErrorMsg);
    _sink.add(ControlChars.semicolonBytes);
    _sink.add(escapeBytes(component));
    return this;
  }

  Serializer boolean(bool component) {
    assert(_isOpen = true, _notOpenErrorMsg);
    _sink.add(ControlChars.semicolonBytes);
    _sink.add(utf8.encode(component ? 'T' : 'F'));
    return this;
  }

  Serializer integer(int component) {
    assert(_isOpen = true, _notOpenErrorMsg);
    _sink.add(ControlChars.semicolonBytes);
    _sink.add(utf8.encode(component.toRadixString(16)));
    return this;
  }

  Serializer float(double component) {
    assert(_isOpen = true, _notOpenErrorMsg);
    _sink.add(ControlChars.semicolonBytes);
    _sink.add(utf8.encode(radixEncodeFloat(component)));
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

  Future conclude() {
    assert(_isOpen = true, _notOpenErrorMsg);
    _isOpen = false;
    return _sink.close();
  }

  bool get isOpen => _isOpen;
}
