import 'comp_buffer.dart';
import 'control_chars.dart';

typedef NewlineIndexCallback(int newlineIndex);

class ByteArrayCompBuffer extends CompBuffer {
  final List<int> _allBytes;
  int _currentIndex;
  final NewlineIndexCallback _newlineIndexCallback;
  final List<int> _compBuffer;

  ByteArrayCompBuffer(
    List<int> bytes,
    int startIndex, 
    NewlineIndexCallback newlineIndexCallback,
  ) : _allBytes = bytes,
      _currentIndex = startIndex,
      _newlineIndexCallback = newlineIndexCallback,
      _compBuffer = List<int>();

  fill() {
    _compBuffer.clear();
    int b = _allBytes[_currentIndex];
    while (true) {
      if (b == -1) {
        break;
      } else if (b == ControlChars.semicolonByte) {
        break;
      } else if (b == ControlChars.newlineByte) {
        _newlineIndexCallback(_currentIndex);
        break;
      }
      _compBuffer.add(b);
      _currentIndex++;
      b = _allBytes[_currentIndex];
    }
  }

  List<int> get bytes => _compBuffer;

  List<int> readAllBytes() => _allBytes;

  int fixReadPosition() => _currentIndex;
}