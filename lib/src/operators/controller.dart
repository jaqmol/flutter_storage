import '../commit_file.dart';
import '../index.dart';
import '../serialization/line_deserializer.dart';
import '../serialization/entry_info.dart';
import '../serialization/entry_info_private.dart';

typedef void ReadIndexCallback();

/// Controller
/// 
class Controller {
  CommitFile _log;
  Index _index;
  String _path;
  bool _isOpen;
  ReadIndexCallback _readIndexCallback;

  Controller(
    CommitFile log,
    Index index,
    String path,
    bool isOpen,
    ReadIndexCallback readIndexCallback,
  ) : assert(log != null),
      assert(index != null),
      assert(path != null),
      assert(isOpen != null),
      assert(readIndexCallback != null),
      this._log = log,
      this._index = index,
      this._path = path,
      this._isOpen = isOpen,
      this._readIndexCallback = readIndexCallback;

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
  double get staleRatio {
    return _index.staleRatio;
  }

  /// Check if storage needs compaction
  /// 
  /// Returns true in case the storage needs compaction.
  /// The treshold [staleRatio] is 0.5.
  /// 
  bool get needsCompaction {
    return staleRatio >= 1.5;
  }

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
  Controller compaction() {
    var newIdxForOldIdx = _log.compaction(_index.startIndexes);
    _index.replaceStartIndexes(newIdxForOldIdx);
    return this;
  }

  /// Flush state.
  /// 
  /// A flush appends all management state of
  /// a storage to the end of the log.
  /// 
  /// If there's no change, no flush 
  /// will be performed.
  /// 
  Controller flush() {
    var serialize = _log.indexSerializer(_index.version);
    _index.encode(serialize);
    serialize.concludeWithStartIndex();
    _log.flush();
    return this;
  }

  /// Close storage.
  /// 
  /// Hint: always [close] a storage when finished working on it.
  /// 
  void close() {
    _log.close();
    _isOpen = false;
  }

  /// Close currently open storage and open other path.
  /// 
  /// Before opening the other path the currently open
  /// storage's state is flushed and closed.
  /// 
  /// After method concludes storage is reading 
  /// from and writing to new path.
  /// 
  Controller shiftToPath(String newPath) {
    // Closing operations must reflect [close]
    flush();
    _log.close();

    // Reset internal state
    _path = newPath;
    _index.clear();
    _log = CommitFile(_path);
    _readIndexCallback();
    return this;
  }

  bool get isOpen => _isOpen;
}