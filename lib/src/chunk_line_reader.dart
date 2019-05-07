import 'dart:collection';
import 'dart:io';
import 'package:meta/meta.dart';
import 'serialization/control_chars.dart';

class ChunkLineReader extends IterableBase<List<int>> {
  final RandomAccessFile _raf;
  final int _startIndex;
  final int _bufferSize;

  ChunkLineReader({
    @required RandomAccessFile raf,
    @required int startIndex,
    @required int bufferSize,
  }) :  _raf = raf,
        _startIndex = startIndex,
        _bufferSize = bufferSize;

  _ChunkLineReaderIterator get iterator => 
    _ChunkLineReaderIterator(_raf, _startIndex, _bufferSize);
}

class _ChunkLineReaderIterator extends Iterator<List<int>> {
  final RandomAccessFile _raf;
  final int _bufferSize;
  final List<int> _buffer;
  bool _active = true;
  int _endIndex = 0;

  _ChunkLineReaderIterator(RandomAccessFile raf, int startIndex, int bufferSize)
    : _raf = raf,
      _bufferSize = bufferSize,
      _buffer = List<int>(bufferSize) {
        _raf.setPositionSync(startIndex);
      }

  bool moveNext() {
    if (!_active) return false;
    _buffer.fillRange(0, _bufferSize, null);
    _raf.readIntoSync(_buffer);
    _endIndex = 0;
    for (int b in _buffer) {
      _endIndex++;
      if (b == ControlChars.newlineByte) {
        _active = false;
        _raf.setPositionSync(_endIndex);
        break;
      }
    }
    return true;
  }

  List<int> get current => _endIndex == _bufferSize
    ? _buffer
    : _buffer.sublist(0, _endIndex);
}