import 'component_reader.dart';
import 'control_chars.dart';
import 'dart:io';

class RafComponentReader extends ComponentReader {
  final RandomAccessFile _raf;
  final int startIndex;
  final List<int> _buffer;
  bool _finished;

  RafComponentReader(
    RandomAccessFile raf,
    this.startIndex,
  ) : _raf = raf,
      _finished = false,
      _buffer = List<int>() {
        _raf.setPositionSync(startIndex);
      }

  bool moveNext() {
    if (_finished) return false;

    _buffer.clear();
    int b = _raf.readByteSync();
    while (!_finished) {
      if (b == ControlChars.newlineByte || b == -1) {
        _finished = true;
        break;
      } else if (b == ControlChars.semicolonByte) {
        break;
      }
      _buffer.add(b);
      b = _raf.readByteSync();
    }

    return true;
  }

  List<int> get current => _buffer;
}