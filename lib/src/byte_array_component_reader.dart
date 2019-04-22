import 'component_reader.dart';
import 'control_chars.dart';
import 'dart:collection';

typedef NewlineIndexCallback(int newlineIndex);

class ByteArrayComponentReader extends ComponentReader {
  final List<int> _allBytes;
  final int _startIndex;
  final NewlineIndexCallback _newlineIndexCallback;

  ByteArrayComponentReader(
    List<int> _allBytes,
    int startIndex, 
    NewlineIndexCallback newlineIndexCallback,
  ) : _allBytes = _allBytes,
      _startIndex = startIndex,
      _newlineIndexCallback = newlineIndexCallback;

  ByteArrayComponentReaderIterator get iterator =>
    ByteArrayComponentReaderIterator(_allBytes, _startIndex, _newlineIndexCallback);

  ByteArrayComponentReaderChunks chunks(int bufferSize) =>
    ByteArrayComponentReaderChunks(_allBytes, bufferSize);

  int get startIndex => _startIndex;
}

class ByteArrayComponentReaderIterator extends Iterator<List<int>> {
  final List<int> _allBytes;
  final int _startIndex;
  int _currentIndex;
  final NewlineIndexCallback _newlineIndexCallback;
  final List<int> _compBuffer;
  bool _finished;

  ByteArrayComponentReaderIterator(
    List<int> allBytes,
    int startIndex,
    NewlineIndexCallback newlineIndexCallback,
  ) : _allBytes = allBytes,
      _startIndex = startIndex,
      _currentIndex = startIndex,
      _newlineIndexCallback = newlineIndexCallback,
      _compBuffer = List<int>(),
      _finished = false;

  bool moveNext() {
    if (_finished) return false;

    _compBuffer.clear();
    int b = _allBytes[_currentIndex];
    while (true) {
      if (b == ControlChars.newlineByte) {
        _newlineIndexCallback(_currentIndex);
        _finished = true;
        break;
      } else if (b == -1) {
        _finished = true;
        break;
      } else if (b == ControlChars.semicolonByte) {
        break;
      }
      _compBuffer.add(b);
      _currentIndex++;
      b = _allBytes[_currentIndex];
    }

    return true;
  }

  List<int> get current => _compBuffer;
}

class ByteArrayComponentReaderChunks extends IterableBase<List<int>> {
  final List<int> _compBuffer;
  final int _bufferSize;

  ByteArrayComponentReaderChunks(
    List<int> compBuffer,
    int bufferSize,
  ) : this._compBuffer = compBuffer,
      this._bufferSize = bufferSize;

  ByteArrayComponentReaderChunkIterator get iterator =>
    ByteArrayComponentReaderChunkIterator(_compBuffer, _bufferSize);
}

class ByteArrayComponentReaderChunkIterator extends Iterator<List<int>> {
  final List<int> _compBuffer;
  final List<int> _chunkBuffer;
  final int _bufferSize;
  int _index;

  ByteArrayComponentReaderChunkIterator(
    List<int> compBuffer,
    int bufferSize,
  ) : _compBuffer = compBuffer,
      _chunkBuffer = List<int>(bufferSize),
      _bufferSize = bufferSize;

  bool moveNext() {
    if (_index == null) {
      _index = 0;
    } else {
      _index += _bufferSize;
    }
    return _index < _compBuffer.length;
  }

  List<int> get current {
    _chunkBuffer.clear();
    int end = _index + _bufferSize;
    if (end > _compBuffer.length) {
      end = _compBuffer.length;
    }
    return _chunkBuffer..addAll(_compBuffer.sublist(_index, end));
  }
}