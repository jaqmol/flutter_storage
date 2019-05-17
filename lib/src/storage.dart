import 'commit_file/commit_file.dart';
import 'commit_file/line_data.dart';
import 'index.dart';
import 'serialization/serializer.dart';
import 'serialization/deserializer.dart';
import 'serialization/line_serializer.dart';
import 'serialization/line_deserializer.dart';
import 'serialization/model.dart';
import 'serialization/control_chars.dart';
import 'serialization/entry_info_private.dart';
import 'serialization/entry_info.dart';
import 'serialization/remove_serializer.dart';
import 'dart:async';
import 'package:path/path.dart' as path;
import 'dart:io';

/// Storage
/// 
class Storage {
  CommitFile _log;
  Index _index;
  
  static Future<Storage> open(String path) async {
    var log = CommitFile(path);
    var index = await _initIndex(log);
    return Storage._create(log, index);
  }

  Storage._create(CommitFile log, Index index)
    : assert(log != null),
      assert(index != null),
      _log = log,
      _index = index;

  static Future<Index> _initIndex(CommitFile log) async {
    Index index;
    var rest = List<LineData>();
    await for (LineData line in log.readLinesReverse()) {
      if (line.first == ControlChars.indexPrefixBytes.first) {
        var d = LineDeserializer(line);
        assert(d.entryInfo is IndexInfo, 'Index was serialized with wrong entry info type');
        var info = d.entryInfo as IndexInfo;
        index = Index.decode(info.modelType, info.modelVersion, d);
        break;
      } else {
        rest.add(line);
      }
    }
    if (index == null) {
      index = Index();
    }
    for (int i = rest.length - 1; i >= 0; i--) {
      var line = rest[i];
      var d = LineDeserializer(line);
      var info = d.entryInfo;
      if (info is ModelInfo || info is ValueInfo) {
        index[info.key] = line.startIndex;
      } else if (info is RemoveInfo) {
        index.remove(info.key);
      }
    }
    return index;
  }

  // Writing

  /// Puts the given model for the given key.
  /// 
  /// Logs the change to the underlaying file.
  /// 
  Future<void> putModel(String key, Model model) async {
    var startIndex = await _log.length();
    var s = LineSerializer.model(
      sink: _log.writeLine(),
      key: key,
      modelType: model.type,
      modelVersion: model.version,
    );
    s.model(model);
    _index[key] = startIndex;
    return s.close();
  }

  /// Get a serializer for puting one or several values for a given key.
  /// 
  /// Logs the change to the underlaying file.
  /// Putting a value MUST ALWAYS be finished by calling
  /// [conclude()] on the [ValueSerializer].
  /// 
  Future<Serializer> serializer(String key) async {
    var startIndex = await _log.length();
    return LineSerializer.value(
      sink: _log.writeLine(),
      key: key,
      onClose: () {
        _index[key] = startIndex;
      },
    );
  }

  /// Remove an entry
  /// 
  /// Returns [true] if the value was present in the index.
  ///
  Future<bool> remove(String key) async {
    if (_index.contains(key)) {
      var s = RemoveSerializer(
        sink: _log.writeLine(),
        key: key,
      );
      await s.close();
      _index.remove(key);
      return true;
    } else {
      return false;
    }
  }
  
  /// Undo last change.
  /// 
  /// All changes to the storage can be undone.
  /// Compaction clears the log from previous entries.
  /// In other words: it resets the undo log.
  /// Returns the key of the entrie's state that was undone.
  /// 
  String undo() => _index.undo();

  // Reading

  /// Get a deserializer for the given key.
  /// 
  /// Check the deserializer's meta field for the
  /// type.
  /// 
  Future<Deserializer> deserializer(String key) async {
    int startIndex = _index[key];
    if (startIndex == -1) return null;
    var line = await _log.readLine(startIndex);
    return LineDeserializer(line);
  }

  /// Get the model for the given key.
  /// 
  /// Returns [null] if the given [key] wans't found.
  /// Throws an error, if [key] doesn't point to a valid model.
  /// 
  Future<T> getModel<T>(String key, T decode(String type, int version, Deserializer des)) async {
    var des = await deserializer(key);
    if (des == null) return null;
    assert(des.entryInfo is ModelInfo);
    var info = des.entryInfo as ModelInfo;
    return decode(info.modelType, info.modelVersion, des);
  }
  
  /// Iterate keys only
  /// 
  Iterable<String> get keys => _index.keys;
  
  /// Iterate values only
  /// 
  Stream<Deserializer> get values async* {
    for (int startIndex in _index.startIndexes) {
      var line = await _log.readLine(startIndex);
      yield LineDeserializer(line);
    }
  }

  // Controlling

  /// Get the stale data ratio
  /// 
  /// Calculated by dividing the amount of changes since
  /// last compaction by the amount of actual
  /// current values.
  /// 
  /// Non-actual and -current values, stale data resp., 
  /// are changes and removals.
  /// 
  /// A [staleRatio] of 0.5 means that 50% of the
  /// storage content consists of stale data.
  /// 
  /// A [staleRatio] of 2 means that there is 2 times 
  /// more stale data stored than current.
  /// 
  /// Stale data can be used to undo changes.
  /// Compaction removes stale data.
  ///
  double get staleRatio => _index.staleRatio;

  /// Check if storage needs compaction
  /// 
  /// Returns true in case the storage needs compaction.
  /// The treshold [staleRatio] is 0.5.
  /// 
  bool get needsCompaction => _index.staleRatio >= 1.5;

  /// Perform compaction
  /// 
  /// Compaction is the process of reducing all logged
  /// key-value-pairs to the most recent state.
  /// 
  /// Usually used before closing a storage:
  ///   1. Check [needsCompaction], if true continue:
  ///   2. Perform [compaction()] and
  ///   3. Conclude with [close()] or [closeAndOpen()].
  /// 
  /// Other situation appropriate for compaction:
  /// After operating system memory warning.
  /// 
  Future<Storage> compaction() async {
    var originalPath = _log.path;
    var basename = path.basenameWithoutExtension(_log.path);
    var extension = path.extension(_log.path);
    var compactionPath = '${basename}_compaction$extension';
    var backupPath = '${basename}_backup$extension}';
    var writeLog = CommitFile(compactionPath);
    var newIdxForOldIdx = <int, int>{};
    for (int oldIdx in _index.startIndexes) {
      int newIdx = await writeLog.length();
      var sink = writeLog.writeLine();
      var line = await _log.readLine(oldIdx);
      sink.add(line);
      await sink.close();
      newIdxForOldIdx[oldIdx] = newIdx;
    }
    await File(_log.path).rename(backupPath);
    await File(compactionPath).rename(_log.path);
    await File(backupPath).delete();
    _log = CommitFile(originalPath);
    _index.replaceStartIndexes(newIdxForOldIdx);
    return this.flush();
  }

  /// Flush state.
  /// 
  /// Flushing appends the current index
  /// snapshop to the end of the log.
  /// 
  /// A fresh index snapshot at the end of the log
  /// speeds up the opening process of a storage.
  /// 
  /// Always flush a storage after usage.
  /// 
  Future<Storage> flush() async {
    var s = LineSerializer.index(
      sink: _log.writeLine(),
      indexVersion: _index.version,
    );
    _index.encode(s);
    await s.close();
    return this;
  }
  
  /// Open a file.
  /// 
  /// After method concludes, storage is reading
  /// from and writing to the path specified.
  /// 
  Future<Storage> openFile(String newPath) async {
    _log = CommitFile(newPath);
    _index = await _initIndex(_log);
    return this;
  }
}
