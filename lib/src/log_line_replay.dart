import 'dart:io';
import 'dart:collection';
import 'log_line.dart';
import 'log_range.dart';
import 'dart:convert';

class LogLineReplay extends IterableBase<LogLine> {
  final String _path;
  final int _newlineByte;

  LogLineReplay(this._path, this._newlineByte);

  Iterator<LogLine> get iterator => LogLineIterator(_path, _newlineByte);
}

class LogLineIterator implements Iterator<LogLine> {
  final RandomAccessFile _raf;
  final _buffer = List<int>();
  final int _newlineByte;
  int _start;
  int _length;

  LogLineIterator(String path, this._newlineByte)
    : _raf = File(path).openSync(mode: FileMode.read)
  {
    _length = _raf.lengthSync();
    _raf.setPositionSync(0);
  }

  bool moveNext() {
    var hasNext = false;
    _start = _raf.positionSync();
    for (int i = _start; i < _length; i++) {
      int byte = _raf.readByteSync();
      if (byte == -1) break;
      else if (byte == _newlineByte) {
        hasNext = true;
        break;
      }
      _buffer.add(byte);
      hasNext = true;
    }
    if (!hasNext) {
      _raf.closeSync();
    }
    return hasNext;
  }

  LogLine get current {
    var range = LogRange(_start, _buffer.length);
    var line = LogLine(range, utf8.decode(_buffer));
    _buffer.clear();
    return line;
  }
}