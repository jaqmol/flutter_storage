import 'dart:io';
import 'package:meta/meta.dart';
import 'identifier.dart';
import 'package:path/path.dart' as p;
import 'commit_file_replay.dart';
import 'serialization/line_serializer.dart';
import 'serialization/line_deserializer.dart';
import 'serialization/remove_serializer.dart';
// import 'control_chars.dart';
// import 'model.dart';
import 'index.dart';
// import 'reverse_byte_reader.dart';
// import 'byte_array_multiline_reader.dart';
import 'raf_component_reader.dart';
import 'index_tail_reader.dart';
import 'chunk_line_reader.dart';

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

  LineSerializer indexSerializer(int indexVersion) => LineSerializer.index(
    raf: _raf, indexVersion: indexVersion,
  );

  LineSerializer valueSerializer(String key, StartIndexCallback callback) => LineSerializer.value(
    raf: _raf, key: key, startIndexCallback: callback,
  );

  LineSerializer modelSerializer(String key, String modelType, int modelVersion) => LineSerializer.model(
    raf: _raf, key: key, modelType: modelType, modelVersion: modelVersion,
  );

  RemoveSerializer removeSerializer(String key) => RemoveSerializer(
    raf: _raf, key: key,
  );


  LineDeserializer deserializer(int startIndex) => LineDeserializer(
    RafComponentReader(_raf, startIndex),
  );

  ChunkLineReader _readChunks(int startIndex) => ChunkLineReader(
    raf: _raf, startIndex: startIndex, bufferSize: 16,
  );
  int _writeChunks(ChunkLineReader reader) {
    var startIndex = _raf.positionSync();
    for (List<int> buffer in reader) {
      _raf.writeFromSync(buffer);
    }
    return startIndex;
  }

  IndexTailIterable get indexTail => IndexTailReader(_raf).tailLines;

  int get length => _raf.lengthSync();

  void flushAndClose() {
    _raf.flushSync();
    _raf.closeSync();
  }

  bool flush() {
    _raf.flushSync();
    return true;
  }
  void close() => _raf.closeSync();

  CommitFileReplay get replay => CommitFileReplay(_raf);

  // Map<int, int> compaction({
  //   @required void map(LineDeserializer deserializer),
  //   @required Iterable<int> reduce(),
  // }) {
  //   for (LineDeserializer deserialize in replay) {
  //     map(deserialize);
  //   }

  //   var compactionFile = CommitFile(_randomCompactionPath);
  //   var newIndexForOldIndex = Map<int, int>();
  //   for (int oldIndex in reduce()) {
  //     int newIndex = compactionFile._writeChunks(_readChunks(oldIndex));
  //     newIndexForOldIndex[oldIndex] = newIndex;
  //   }
    
  //   compactionFile.flushAndClose();
  //   flushAndClose();
    
  //   _raf = null;
  //   var backupFile = File(path).renameSync(compactionBackupPath);
  //   File(compactionFile.path).renameSync(path);
  //   backupFile.deleteSync();
  //   _openRaf();
  //   return newIndexForOldIndex;
  // }

  Map<int, int> compaction(Iterable<int> indexesToKeep) {
    var compactionFile = CommitFile(_randomCompactionPath);
    var newIndexForOldIndex = Map<int, int>();
    for (int oldIndex in indexesToKeep) {
      int newIndex = compactionFile._writeChunks(_readChunks(oldIndex));
      newIndexForOldIndex[oldIndex] = newIndex;
    }
    
    compactionFile.flushAndClose();
    flushAndClose();
    
    _raf = null;
    var backupFile = File(path).renameSync(compactionBackupPath);
    File(compactionFile.path).renameSync(path);
    backupFile.deleteSync();
    _openRaf();
    return newIndexForOldIndex;
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