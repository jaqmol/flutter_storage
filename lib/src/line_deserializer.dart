import 'deserializer.dart';
import 'dart:io';
// import 'log_range.dart';
import 'control_chars.dart';
import 'unescaping.dart';
import 'dart:convert';
import 'entry_info.dart';
// import 'bitwise_line_reader.dart';
import 'comp_buffer.dart';

class LineDeserializer implements Deserializer {
  CompBuffer _compBuffer;
  EntryInfo _entryInfo;

  LineDeserializer(CompBuffer compBuffer)
    : assert(compBuffer != null) {
      _readEntryInfo();
    }

  List<int> readAllBytes() => _compBuffer.readAllBytes();

  _readEntryInfo() {
    if (_entryInfo != null) return;
    _compBuffer.fill();
    var infoString = utf8.decode(_compBuffer.bytes);
    _entryInfo = EntryInfo.fromString(infoString);
  }

  EntryInfo get entryInfo => _entryInfo;

  String string() {
    _compBuffer.fill();
    var escaped = utf8.decode(_compBuffer.bytes);
    return unescapeString(escaped);
  }

  List<int> bytes() {
    _compBuffer.fill();
    return unescapeBytes(_compBuffer.bytes);
  }

  bool boolean() {
    _compBuffer.fill();
    var v = utf8.decode(_compBuffer.bytes);
    return v == 'T';
  }

  int integer() {
    _compBuffer.fill();
    var v = utf8.decode(_compBuffer.bytes);
    return int.parse(v, radix: 16);
  }

  double float() {
    _compBuffer.fill();
    var v = utf8.decode(_compBuffer.bytes);
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

  int conclude() => _compBuffer.fixReadPosition();
}
