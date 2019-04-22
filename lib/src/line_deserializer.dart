import 'deserializer.dart';
import 'unescaping.dart';
import 'dart:convert';
import 'entry_info.dart';
import 'component_reader.dart';

class LineDeserializer implements Deserializer {
  ComponentReader _reader;
  EntryInfo _entryInfo;
  Iterator<List<int>> _iterator;

  LineDeserializer(ComponentReader reader)
    : assert(reader != null),
      _reader = reader {
      _iterator = reader.iterator;
      _readEntryInfo();
    }

  Iterable<List<int>> chunks(int bufferSize) => _reader.chunks(bufferSize);

  _readEntryInfo() {
    if (_entryInfo != null) return;
    _iterator.moveNext();
    var infoString = utf8.decode(_iterator.current);
    _entryInfo = EntryInfo.fromString(infoString);
  }

  EntryInfo get entryInfo => _entryInfo;

  String string() {
    _iterator.moveNext();
    var escaped = utf8.decode(_iterator.current);
    return unescapeString(escaped);
  }

  List<int> bytes() {
    _iterator.moveNext();
    return unescapeBytes(_iterator.current);
  }

  bool boolean() {
    _iterator.moveNext();
    var v = utf8.decode(_iterator.current);
    return v == 'T';
  }

  int integer() {
    _iterator.moveNext();
    var v = utf8.decode(_iterator.current);
    return int.parse(v, radix: 16);
  }

  double float() {
    _iterator.moveNext();
    var v = utf8.decode(_iterator.current);
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
