import 'deserializer.dart';
import 'unescaping.dart';
import 'dart:convert';
import 'entry_info.dart';
import 'control_chars.dart';
// import '../component_reader.dart';

class LineDeserializer implements Deserializer {
  List<int> _data;
  int _index;
  EntryInfo _entryInfo;

  LineDeserializer(List<int> data)
    : assert(data != null),
      _data = data,
      _index = 0 {
        _readEntryInfo();
      }

  List<int> _nextComponent() {
    int semidx = _data.indexOf(ControlChars.semicolonBytes.first, _index);
    List<int> comp;
    if (semidx > -1) {
      comp = _data.sublist(_index, semidx);
      _index = semidx + 1;
    } else {
      comp = _data.sublist(_index);
      _index = _data.length;
    }
    return comp;
  }

  _readEntryInfo() {
    if (_entryInfo != null) return;
    assert(_index < _data.length);
    var infoString = utf8.decode(_nextComponent());
    _entryInfo = EntryInfo.fromString(infoString);
  }

  EntryInfo get entryInfo => _entryInfo;

  String string() {
    assert(_index < _data.length);
    var escaped = utf8.decode(_nextComponent());
    return unescapeString(escaped);
  }

  List<int> bytes() {
    assert(_index < _data.length);
    return unescapeBytes(_nextComponent());
  }

  bool boolean() {
    assert(_index < _data.length);
    var v = utf8.decode(_nextComponent());
    return v == 'T';
  }

  int integer() {
    assert(_index < _data.length);
    var v = utf8.decode(_nextComponent());
    return int.parse(v, radix: 16);
  }

  double float() {
    assert(_index < _data.length);
    var v = utf8.decode(_nextComponent());
    return radixDecodeFloat(v);
  }

  List<T> list<T>(T decodeFn()) {
    return List<T>.generate(
      integer(),
      (_) => decodeFn(),
    );
  }

  Map<K, V> map<K, V>(MapEntry<K, V> decodeFn()) {
    return Map<K, V>.fromEntries(
      List<MapEntry<K, V>>.generate(
        integer(),
        (_) => decodeFn(),
      ),
    );
  }

  // int get startIndex => _reader.startIndex;
}
