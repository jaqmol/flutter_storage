import 'dart:io';
import 'dart:collection';
// import 'log_line.dart';
// import 'log_range.dart';
import 'line_deserializer.dart';
import 'bitwise_line_reader_comp_buffer.dart';
import 'bitwise_line_reader.dart';
import 'dart:convert';

class CommitFileReplay extends IterableBase<LineDeserializer> {
  RandomAccessFile _raf;

  CommitFileReplay(RandomAccessFile raf) : this._raf = raf;

  Iterator<LineDeserializer> get iterator => CommitFileIterator(_raf);
}

class CommitFileIterator implements Iterator<LineDeserializer> {
  final RandomAccessFile _raf;
  final int _appendPosition;
  final int _length;
  bool _active;

  CommitFileIterator(RandomAccessFile raf)
    : _raf = raf,
      _appendPosition = raf.positionSync(),
      _length = raf.lengthSync(),
      _active = true {
        _raf.setPositionSync(0);
      }

  bool moveNext() {
    if (_raf.positionSync() < _length) return true;
    // conclude:
    _active = false;
    _raf.setPositionSync(_appendPosition);
  }

  LineDeserializer get current {
    if (_active) {
      return LineDeserializer(BitwiseLineReaderCompBuffer(
        BitwiseLineReader(_raf, 16),
        _raf.positionSync(),
      ));
    }
    return null;
  }
}