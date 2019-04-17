import 'deserializer.dart';
import 'dart:io';
// import 'log_range.dart';
import 'control_chars.dart';
import 'unescaping.dart';
import 'dart:convert';
import 'entry_info.dart';
import 'bitwise_line_reader.dart';

class LineDeserializer implements Deserializer {
  static const int _bufferSize = 16;
  final RandomAccessFile _raf;
  final BitwiseLineReader _reader;
  final int startIndex;

  EntryInfo _entryInfo;
  
  final List<int> _compBuffer;
  ReaderEndType _compEnd;

  LineDeserializer({
    raf: RandomAccessFile,
    this.startIndex,
  }) : assert(raf != null),
       assert(startIndex != null),
       _raf = raf,
       _reader = BitwiseLineReader(raf, _bufferSize),
       _compBuffer = List<int>() {
         _raf.setPositionSync(startIndex);
         _readEntryInfo();
       }

  _fillCompBuffer() {
    _compBuffer.clear();
    int b = _reader.nextByte;
    while (true) {
      if (b == -1) {
        _compEnd = ReaderEndType.EOF;
        break;
      } else if (b == ControlChars.semicolonByte) {
        _compEnd = ReaderEndType.Semicolon;
        break;
      } else if (b == ControlChars.newlineByte) {
        _compEnd = ReaderEndType.EOL;
        break;
      }
      _compBuffer.add(b);
      b = _reader.nextByte;
    }
  }

  List<int> readAllBytes() {
    int currentIndex = _raf.positionSync();
    _raf.setPositionSync(startIndex);
    var r = BitwiseLineReader(_raf, _bufferSize);
    var acc = List<int>();
    int b = r.nextByte;
    while (true) {
      if (b == -1) {
        _compEnd = ReaderEndType.EOF;
        break;
      } else if (b == ControlChars.newlineByte) {
        _compEnd = ReaderEndType.EOL;
        break;
      }
      acc.add(b);
      b = r.nextByte;
    }
    _raf.setPositionSync(currentIndex);
    return acc;
  }

  _readEntryInfo() {
    if (_entryInfo != null) return;
    _fillCompBuffer();
    var infoString = utf8.decode(_compBuffer);
    _entryInfo = EntryInfo.fromString(infoString);
  }

  EntryInfo get entryInfo => _entryInfo;

  String string() {
    _fillCompBuffer();
    var escaped = utf8.decode(_compBuffer);
    return unescapeString(escaped);
  }

  List<int> bytes() {
    _fillCompBuffer();
    return unescapeBytes(_compBuffer);
  }

  bool boolean() {
    _fillCompBuffer();
    var v = utf8.decode(_compBuffer);
    return v == 'T';
  }

  int integer() {
    _fillCompBuffer();
    var v = utf8.decode(_compBuffer);
    return int.parse(v, radix: 16);
  }

  double float() {
    _fillCompBuffer();
    var v = utf8.decode(_compBuffer);
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

  ReaderEndType conclude() {
    _reader.fixReadPosition();
    return _compEnd;
  }
}

enum ReaderEndType {
  Semicolon,
  EOL,
  EOF,
}
