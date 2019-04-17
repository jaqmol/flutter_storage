import 'dart:io';

class BitwiseLineReader {
  final RandomAccessFile _raf;
  final int _bufferSize;
  final List<int> _buffer;
  int _bufferIndex;

  BitwiseLineReader(RandomAccessFile raf, int bufferSize)
    : assert(raf != null),
      assert(bufferSize != null),
      _raf = raf,
      _bufferSize = bufferSize,
      _buffer = List<int>.filled(bufferSize, null),
      _bufferIndex = bufferSize;

  int get nextByte {
    if (_bufferIndex == _bufferSize) {
      _raf.readIntoSync(_buffer);
      _bufferIndex = 0;
    }
    int b = _buffer[_bufferIndex];
    _bufferIndex++;
    return b;
  }

  setReadPosition(int position) => _raf.setPositionSync(position);
  int readPosition() => _raf.positionSync();

  int fixReadPosition() {
    int difference = _buffer.length - _bufferIndex;
    int filePosition = _raf.positionSync();
    if (difference == 0) return filePosition;
    filePosition -= difference;
    _raf.setPositionSync(filePosition);
    return filePosition;
  }
}