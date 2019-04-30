import 'dart:io';
import 'dart:collection';
import 'line_deserializer.dart';
import 'raf_component_reader.dart';

class CommitFileReplay extends IterableBase<LineDeserializer> {
  RandomAccessFile _raf;
  CommitFileReplay(RandomAccessFile raf) : this._raf = raf;
  Iterator<LineDeserializer> get iterator => CommitFileIterator(_raf);
}

class CommitFileIterator implements Iterator<LineDeserializer> {
  final RandomAccessFile _raf;
  final int _initialPosition;
  final int _length;
  bool _active;

  CommitFileIterator(RandomAccessFile raf)
    : _raf = raf,
      _initialPosition = raf.positionSync(),
      _length = raf.lengthSync(),
      _active = true {
        _raf.setPositionSync(0);
      }

  bool moveNext() {
    if (_raf.positionSync() < _length) return true;
    _active = false;
    _raf.setPositionSync(_initialPosition);
    return false;
  }

  LineDeserializer get current {
    if (_active) {
      return LineDeserializer(
        RafComponentReader(_raf, _raf.positionSync())
      );
    }
    return null;
  }
}