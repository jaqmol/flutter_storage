import 'component_reader.dart';
import 'control_chars.dart';
import 'dart:collection';
import 'dart:io';

class RafComponentReader extends ComponentReader {
  final RandomAccessFile _raf;
  final int _startIndex;

  RafComponentReader(
    RandomAccessFile raf,
    int startIndex,
  ) : _raf = raf,
      _startIndex = startIndex;

  RafComponentReaderIterator get iterator => 
    RafComponentReaderIterator(_raf, startIndex);
  
  RafComponentReaderChunks chunks(int bufferSize) =>
    RafComponentReaderChunks(_raf, _startIndex, bufferSize);

  int get startIndex => _startIndex;
}

class RafComponentReaderIterator extends Iterator<List<int>> {
  final RandomAccessFile _raf;
  final int _startIndex;
  final List<int> _bytes;
  bool _finished;

  RafComponentReaderIterator(
    RandomAccessFile raf,
    int startIndex,
  ) : _raf = raf,
      _startIndex = startIndex,
      _bytes = List<int>() {
        _raf.setPositionSync(startIndex);
        _finished = false;
      }

  bool moveNext() {
    if (_finished) return false;

    _bytes.clear();
    int b = _raf.readByteSync();
    while (true) {
      if (b == ControlChars.newlineByte || b == -1) {
        _finished = true;
        break;
      } else if (b == ControlChars.semicolonByte) {
        break;
      }
      _bytes.add(b);
      b = _raf.readByteSync();
    }

    return true;
  }

  List<int> get current => _bytes;
}

class RafComponentReaderChunks extends IterableBase<List<int>> {
  final RandomAccessFile _raf;
  final int _startIndex;
  final int _bufferSize;

  RafComponentReaderChunks(
    RandomAccessFile raf,
    int startIndex,
    int bufferSize,
  ) : _raf = raf,
      _startIndex = startIndex,
      _bufferSize = bufferSize;

  RafComponentReaderChunkIterator get iterator =>
    RafComponentReaderChunkIterator(_raf, _startIndex, _bufferSize);
}

class RafComponentReaderChunkIterator extends Iterator<List<int>> {
  final RandomAccessFile _raf;
  final int _bufferSize;
  final List<int> _bytes;
  int _finishedIndex;

  RafComponentReaderChunkIterator(
    RandomAccessFile raf,
    int startIndex,
    int bufferSize,
  ) : _raf = raf,
      _bufferSize = bufferSize,
      _bytes = List<int>.filled(bufferSize, null) {
        _raf.setPositionSync(startIndex);
        _finishedIndex = -1;
      }

  bool moveNext() {
    if (_finishedIndex > -1) return false;

    _bytes.fillRange(0, _bufferSize, null);
    _raf.readIntoSync(_bytes);

    _finishedIndex = _bytes.indexWhere(
      (int b) => b == -1 || b == ControlChars.newlineByte
    );

    return true;
  }

  List<int> get current => _finishedIndex > -1
    ? _bytes.sublist(0, _finishedIndex)
    : _bytes;
}
