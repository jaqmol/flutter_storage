import 'dart:io';
import 'dart:convert';
import 'package:meta/meta.dart';
import 'identifier.dart';
import 'package:path/path.dart' as p;
import 'dart:collection';
// import 'log_range.dart';
// import 'log_line.dart';
import 'commit_file_replay.dart';
import 'line_serializer.dart';
import 'line_deserializer.dart';
import 'control_chars.dart';
import 'model.dart';
import 'index.dart';
import 'bitwise_reverse_line_reader.dart';
import 'deserializer.dart';
import 'byte_array_multiline_deserializer.dart';
import 'bitwise_line_reader_comp_buffer.dart';
import 'bitwise_line_reader.dart';

class CommitFile {
  static final _backupSuffix = 'backup';

  RandomAccessFile _raf;
  final String path;

  CommitFile(this.path) {
    _openRaf();
  }

  void _openRaf() {
    _raf = File(path).openSync(mode: FileMode.append);
  }

  LineSerializer indexSerializer(String key, Index index) => LineSerializer.index(
    raf: _raf, index: index,
  );
  LineSerializer valueSerializer(String key) => LineSerializer.value(
    raf: _raf, key: key,
  );
  LineSerializer modelSerializer(String key, Model model) => LineSerializer.model(
    raf: _raf, key: key, model: model,
  );
  LineSerializer removeSerializer(String key) => LineSerializer.remove(
    raf: _raf, key: key,
  );

  LineDeserializer deserializer(int startIndex) => LineDeserializer(
    BitwiseLineReaderCompBuffer(
      BitwiseLineReader(_raf, 16),
      startIndex,
    ),
  );

  // ReaderEndType writeLine(LineDeserializer d) {
  //   _raf.writeFromSync(d.readAllBytes());
  //   _raf.writeStringSync('\n');
  //   return d.conclude();
  // }

  ByteArrayMultilineDeserializer get lastIndexToEnd {
    int len = _raf.lengthSync();
    if (len == 0) return null;
    int appendPosition = _raf.positionSync();
    _raf.setPosition(len);
    var r = BitwiseReverseLineReader(_raf, 16);
    var acc = List<int>();
    int b = r.nextByte;
    while (true) {
      if (b == -1) {
        break;
      } else if (
        b == ControlChars.newlineByte && 
        acc.length > 0 && 
        acc.first == ControlChars.indexPrefixByte)
      {
        break;
      } else {
        acc.insert(0, b);
        b = r.nextByte;
      }
    }
    _raf.setPositionSync(appendPosition);
    return ByteArrayMultilineDeserializer(acc);
  }

  // LineDeserializer get lastLine {
  //   if (_raf.lengthSync() == 0) {
  //     return null;
  //   }
  //   int appendPosition = _raf.positionSync();
  //   var buffer = _lastLineContainingBuffer();
  //   var value = _lastLineValueFromBuffer(buffer);
  //   _raf.setPositionSync(appendPosition);
  //   return utf8.decode(value);
  // }
  // List<int> _lastLineContainingBuffer() {
  //   var buffer = List<int>();
  //   var chunksIterator = _BackwardsRangeIterable(_raf.lengthSync());
  //   int foundNewlinesCount = 0;
  //   for (_Range chunkRange in chunksIterator) {
  //     _raf.setPositionSync(chunkRange.start);
  //     var chunk = _raf.readSync(chunkRange.length);
  //     buffer.insertAll(0, chunk);
  //     for (int char in chunk) {
  //       if (char == ControlChars.newlineByte) {
  //         foundNewlinesCount += 1;
  //         if (foundNewlinesCount == 2) break;
  //       }
  //     }
  //     if (foundNewlinesCount == 2) break;
  //   }
  //   return buffer;
  // }
  // List<int> _lastLineValueFromBuffer(List<int> buffer) {
  //   int end = buffer.lastIndexOf(ControlChars.newlineByte);
  //   int start = buffer.lastIndexOf(ControlChars.newlineByte, end - 2);
  //   if (start == -1) { start = 0; } // If only 1 line in file
  //   else { start++; } // Start points to newline
  //   return buffer.sublist(start, end);
  // }

  int get length => _raf.lengthSync();

  void flushAndClose() {
    _raf.flushSync();
    _raf.closeSync();
  }

  void flush() => _raf.flushSync();
  void close() => _raf.closeSync();

  CommitFileReplay get replay {
    flush();
    return CommitFileReplay(_raf);
  }

  compaction({
    @required void map(int startIndex, LineDeserializer deserializer),
    @required Iterable<int> reduce(),
  }) {
    for (LineDeserializer d in replay) {
      map(d.startIndex, d);
    }
    var compactionFile = CommitFile(_randomCompactionPath);
    for (int startIndex in reduce()) {
      compactionFile.writeLine(deserializer(startIndex));
    }
    
    compactionFile.flushAndClose();
    flushAndClose();
    
    _raf = null;
    var backupFile = File(path).renameSync(compactionBackupPath);
    File(compactionFile.path).renameSync(path);
    backupFile.deleteSync();
    _openRaf();
  }

  String get _randomCompactionPath => _suffixedFilenamePath(path, identifier());
  String get compactionBackupPath => _suffixedFilenamePath(path, _backupSuffix);

  String toString() => File(path).readAsStringSync();
}

String _suffixedFilenamePath(String originalFilePath, String nameSuffix) {
  String name = p.basenameWithoutExtension(originalFilePath);
  String ext = p.extension(originalFilePath);
  String base = p.dirname(originalFilePath);
  return p.join(base, '$name-$nameSuffix.$ext');
}

// class _BackwardsRangeIterable extends IterableBase<_Range> {
//   final int _length;

//   _BackwardsRangeIterable(this._length);

//   Iterator<_Range> get iterator => _BackwardsRangeIterator(_length);
// }

// class _BackwardsRangeIterator implements Iterator<_Range> {
//   final int _length;
//   _Range _current;

//   _BackwardsRangeIterator(this._length)
//     : _current = _Range(_length, 0);

//   bool moveNext() {
//     if (_current.start == 0) {
//       return false;
//     } else if (_current.start <= 64) {
//       _current = _Range(0, _current.start);
//     } else {
//       _current = _Range(_current.start - 64, 64);
//     }
//     return true;
//   }

//   _Range get current => _current;
// }

// class _Range {
//   final int start;
//   final int length;

//   _Range(this.start, this.length);

//   String toString() => '_Range($start, $length)';
// }