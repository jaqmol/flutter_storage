import 'deserializer.dart';
import 'unescaping.dart';
import 'dart:convert';
import 'entry_info.dart';
import 'component_reader.dart';

class LineDeserializer implements Deserializer {
  ComponentReader _reader;
  EntryInfo _entryInfo;

  LineDeserializer(ComponentReader reader)
    : assert(reader != null),
      _reader = reader {
      _readEntryInfo();
    }

  // Iterable<List<int>> chunks(int bufferSize) => _reader.chunks(bufferSize);

  _readEntryInfo() {
    if (_entryInfo != null) return;
    assert(_reader.moveNext());
    var infoString = utf8.decode(_reader.current);
    _entryInfo = EntryInfo.fromString(infoString);
  }

  EntryInfo get entryInfo => _entryInfo;

  String string() {
    _reader.moveNext();
    var escaped = utf8.decode(_reader.current);
    return unescapeString(escaped);
  }

  List<int> bytes() {
    _reader.moveNext();
    return unescapeBytes(_reader.current);
  }

  bool boolean() {
    _reader.moveNext();
    var v = utf8.decode(_reader.current);
    return v == 'T';
  }

  int integer() {
    _reader.moveNext();
    var v = utf8.decode(_reader.current);
    return int.parse(v, radix: 16);
  }

  double float() {
    _reader.moveNext();
    var v = utf8.decode(_reader.current);
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

  int get startIndex => _reader.startIndex;
}
