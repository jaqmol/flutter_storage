import 'dart:io';
import 'package:meta/meta.dart';
import 'identifier.dart';
import 'package:path/path.dart' as p;
import 'commit_file_replay.dart';
import 'line_serializer.dart';
import 'line_deserializer.dart';
import 'control_chars.dart';
import 'model.dart';
import 'index.dart';
import 'reverse_byte_reader.dart';
import 'byte_array_multiline_deserializer.dart';
import 'raf_component_reader.dart';

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

  LineSerializer indexSerializer(Index index) => LineSerializer.index(
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
    RafComponentReader(_raf, startIndex),
  );

  ByteArrayMultilineDeserializer get lastIndexToEnd {
    int len = _raf.lengthSync();
    if (len == 0) return null;
    int initialIndex = _raf.positionSync();
    _raf.setPosition(len);
    var r = ReverseByteReader(_raf, 16);
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
    _raf.setPositionSync(initialIndex);
    return ByteArrayMultilineDeserializer(acc);
  }

  int get length => _raf.lengthSync();

  void flushAndClose() {
    _raf.flushSync();
    _raf.closeSync();
  }

  void flush() => _raf.flushSync();
  void close() => _raf.closeSync();

  CommitFileReplay get replay => CommitFileReplay(_raf);

  void compaction({
    @required void map(LineDeserializer deserializer),
    @required Iterable<int> reduce(),
  }) {
    for (LineDeserializer deserialize in replay) {
      map(deserialize);
    }

    var compactionFile = CommitFile(_randomCompactionPath);
    const int bufferSize = 16;
    for (int startIndex in reduce()) {
      var ito = RafComponentReader(_raf, startIndex).chunks(bufferSize);
      for (List<int> chunk in ito) {
        _raf.writeFromSync(chunk);
      }
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