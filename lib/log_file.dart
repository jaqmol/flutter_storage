import 'dart:io';
import 'dart:convert';
import 'package:meta/meta.dart';
import 'identifier.dart';
import 'package:path/path.dart' as p;
import 'dart:collection';

class LogFile {
  static final _newlineByte = utf8.encode(_newline).first;
  static final _backupSuffix = 'backup';
  static final _carriageReturn = '\r';
  static final _newline = '\n';

  RandomAccessFile _raf;
  final String path;

  LogFile(this.path) {
    _openRaf();
  }

  void _openRaf() {
    _raf = File(path).openSync(mode: FileMode.append);
  }

  LogRange appendLine(String data) {
    assert(
      !data.contains(_newline) && !data.contains(_carriageReturn),
      "Loggable lines must not contain newline characters.",
    );
    int start = _raf.lengthSync();
    _raf.writeStringSync(data);
    int end = _raf.lengthSync();
    _raf.writeStringSync(_newline);
    return LogRange(start, end - start);
  }

  String readRange(LogRange range) {
    int appendPosition = _raf.positionSync();
    _raf.setPositionSync(range.start);
    var value = utf8.decode(_raf.readSync(range.length));
    _raf.setPositionSync(appendPosition);
    return value;
  }

  String get lastLine {
    if (_raf.lengthSync() == 0) {
      return null;
    }
    int appendPosition = _raf.positionSync();
    var buffer =_lastLineContainingBuffer();
    var value = _lastLineValueFromBuffer(buffer);
    _raf.setPositionSync(appendPosition);
    return utf8.decode(value);
  }
  List<int> _lastLineContainingBuffer() {
    var buffer = List<int>();
    var chunksIterator = BackwardsChunkIterable(_raf.lengthSync());
    int foundNewlinesCount = 0;
    for (LogRange chunkRange in chunksIterator) {
      _raf.setPositionSync(chunkRange.start);
      var chunk = _raf.readSync(chunkRange.length);
      buffer.insertAll(0, chunk);
      for (int char in chunk) {
        if (char == _newlineByte) {
          foundNewlinesCount += 1;
          if (foundNewlinesCount == 2) break;
        }
      }
      if (foundNewlinesCount == 2) break;
    }
    return buffer;
  }
  List<int> _lastLineValueFromBuffer(List<int> buffer) {
    int end = buffer.lastIndexOf(_newlineByte);
    int start = buffer.lastIndexOf(_newlineByte, end - 2);
    if (start == -1) { start = 0; } // If only 1 line in file
    else { start++; } // Start points to newline
    return buffer.sublist(start, end);
  }

  int get length => _raf.lengthSync();

  void flushAndClose() {
    _raf.flushSync();
    _raf.closeSync();
  }

  void flush() => _raf.flushSync();
  void close() => _raf.closeSync();

  LogLineReplay get replay {
    flush();
    return LogLineReplay(path, _newlineByte);
  }

  List<LogRange> compaction({
    @required void map(LogRange range, String data),
    @required Iterable<String> reduce(),
  }) {
    for (LogLine ll in replay) map(ll.range, ll.data);
    var compactionFile = LogFile(_randomCompactionPath);
    var ranges = reduce()
      .map((String data) => compactionFile.appendLine(data))
      .toList();
    
    compactionFile.flushAndClose();
    flushAndClose();
    
    _raf = null;
    var backupFile = File(path).renameSync(compactionBackupPath);
    File(compactionFile.path).renameSync(path);
    backupFile.deleteSync();
    _openRaf();

    return ranges;
  }

  String get _randomCompactionPath => _suffixedFilenamePath(path, identifier());
  String get compactionBackupPath => _suffixedFilenamePath(path, _backupSuffix);
}

class LogRange {
  final int start;
  final int length;

  LogRange(this.start, this.length);

  String toString() => 'LogRange($start, $length)';
}

String _suffixedFilenamePath(String originalFilePath, String nameSuffix) {
  String name = p.basenameWithoutExtension(originalFilePath);
  String ext = p.extension(originalFilePath);
  String base = p.dirname(originalFilePath);
  return p.join(base, '$name-$nameSuffix.$ext');
}

class LogLine {
  final LogRange range;
  final String data;

  LogLine(this.range, this.data);
}

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

class BackwardsChunkIterable extends IterableBase<LogRange> {
  final int _length;

  BackwardsChunkIterable(this._length);

  Iterator<LogRange> get iterator => BackwardsChunkIterator(_length);
}

class BackwardsChunkIterator implements Iterator<LogRange> {
  final int _length;
  LogRange _current;

  BackwardsChunkIterator(this._length)
    : _current = LogRange(_length, 0);

  bool moveNext() {
    if (_current.start == 0) {
      return false;
    } else if (_current.start <= 64) {
      _current = LogRange(0, _current.start);
    } else {
      _current = LogRange(_current.start - 64, 64);
    }
    return true;
  }

  LogRange get current => _current;
}