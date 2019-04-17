import 'dart:io';

class BitwiseReverseLineReader {
  final RandomAccessFile _raf;
  final int _bufferSize;
  final List<int> _buffer;
  int _bufferIndex;

  BitwiseReverseLineReader(RandomAccessFile raf, int bufferSize)
    : assert(raf != null),
      assert(bufferSize != null),
      _raf = raf,
      _bufferSize = bufferSize,
      _buffer = List<int>.filled(bufferSize, null),
      _bufferIndex = 0;

  int get nextByte {
    if (_bufferIndex == 0) {
      int newPos = _raf.positionSync() - _bufferSize;
      if (newPos < 0) return -1;
      _raf.setPositionSync(newPos);
      _raf.readIntoSync(_buffer);
      _bufferIndex = _bufferSize;
    }
    int b = _buffer[_bufferIndex];
    _bufferIndex--;
    return b;
  }

  int fixReadPosition() {
    int difference = _buffer.length - _bufferIndex;
    int filePosition = _raf.positionSync();
    if (difference == 0) return filePosition;
    filePosition -= difference;
    _raf.setPositionSync(filePosition);
    return filePosition;
  }
}