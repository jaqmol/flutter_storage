import 'dart:collection';
import 'commit_file.dart';
// import 'backend_entries.dart';
// import 'frontend_entries.dart';
// import 'serialization.dart';
// import 'log_line.dart';
// import 'log_range.dart';
// import 'line_serializer.dart';
import 'serializer.dart';
import 'deserializer.dart';
import 'model.dart';
import 'index.dart';
import 'line_deserializer.dart';
import 'line_serializer.dart';
import 'entry_info.dart';

const String _closedErrorMsg = "Storage cannot be used after it's closed";

/// Storage
/// 
/// Backing store for commit log with map-interface.
/// 
class Storage {
  CommitFile _log;
  Index _index;
  String path;
  bool _isOpen;
  LineSerializer _openSerializer;
  
  Storage(this.path)
    : _index = Index(),
      _log = CommitFile(path),
      _isOpen = true {
        _readIndex();
      }

  void _readIndex() {
    var multiDeserializer = _log.lastIndexToEnd;
    if (multiDeserializer != null) {
      LineDeserializer deserialize = multiDeserializer.nextLine;
      while (deserialize != null) {
        var info = deserialize.entryInfo;
        if (info is IndexInfo) {
          _index = Index.decode(null, info.modelVersion, deserialize);
        } else {
          if (_index == null) {
            _index = Index();
          }
          _index[info.key] = deserialize.startIndex;
        }
        deserialize = multiDeserializer.nextLine;
      }
    } else {
      _index = Index();
    }
  }

  void _concludeOpenSerializerIfNeeded() {
    if (_openSerializer != null && _openSerializer.isOpen) {
      int startIndex = _openSerializer.conclude();
      _index[_openSerializer.entryInfo.key] = startIndex;
      _openSerializer = null;
    }
  }

  /// Sets the given model for the given key.
  /// 
  /// Logs the change to the underlaying file.
  /// 
  void setModel(String key, Model model) {
    assert(_isOpen, _closedErrorMsg);
    _concludeOpenSerializerIfNeeded();
    var serialize = _log.modelSerializer(key, model);
    serialize = model.encode(serialize);
    int startIndex = serialize.conclude();
    _index[key] = startIndex;
  }

  /// Sets one or several values for the given key.
  /// 
  /// Logs the change to the underlaying file.
  /// 
  Serializer setValue(String key) {
    assert(_isOpen, _closedErrorMsg);
    _concludeOpenSerializerIfNeeded();
    _openSerializer = _log.valueSerializer(key);
    return _openSerializer;
  }

  /// Get a deserializer for the given key.
  /// 
  /// Check the deserializer's meta field for the
  /// type.
  /// 
  Deserializer entry(String key) {
    assert(_isOpen, _closedErrorMsg);
    int startIndex = _index[key];
    if (startIndex == -1) return null;
    return _log.deserializer(startIndex);
  }

  /// Get a value deserializer for the given key.
  /// 
  /// Check the deserializer's meta field for the
  /// type of the model for decoding.
  ///
  bool remove(String key) {
    assert(_isOpen, _closedErrorMsg);
    var startIndex = _index.remove(key);
    _log.removeSerializer(key).conclude();
    return startIndex > -1;
  }

  // Undo

  /// Undo last change.
  /// 
  void undo() => _index.undo();

  // Iteration

  /// Iterate keys only
  /// 
  Iterable<String> get keys {
    assert(_isOpen, _closedErrorMsg);
    return _index.keys;
  }

  /// Iterate values only
  /// 
  Iterable<Deserializer> get values {
    assert(_isOpen, _closedErrorMsg);
    return _index.startIndexes
      .map((int startIndex) => _log.deserializer(startIndex));
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
  void compaction() {
    assert(_isOpen, _closedErrorMsg);    
    var acc = Map<String, int>();
    _log.compaction(
      map: (LineDeserializer deserialize) {
        var info = deserialize.entryInfo;
        if (info is ModelInfo) {
          acc[info.key] = deserialize.startIndex;
        } else if (info is ValueInfo) {
          acc[info.key] = deserialize.startIndex;
        } else if (info is RemoveInfo) {
          acc.remove(info.key);
        }
      },
      reduce: () => acc.values,
    );

    _index.clear();
    for (MapEntry<String, int> entry in acc.entries) {
      _index[entry.key] = entry.value;
    }
    _log.indexSerializer(_index).conclude();
  }

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
    assert(_isOpen, _closedErrorMsg);
    return _index.staleRatio;
  }

  /// Check if storage needs compaction
  /// 
  /// Returns true in case the storage needs compaction.
  /// The treshold [staleRatio] is 0.5.
  /// 
  bool get needsCompaction {
    assert(_isOpen, _closedErrorMsg);
    return staleRatio >= 0.5;
  }

  // /// Clears the in-memory-cache of storage
  // /// 
  // /// Removes all cached values. Does not affect indexes
  // /// as indexes are always kept in memory.
  // /// 
  // void clearCache() {
  //   _cache.clear();
  // }

  /// Flush state of storage to solid state.
  /// 
  /// A flush appends all management state of
  /// a storage to the end of the log.
  /// Thus a storage can be opened fast and does not
  /// need to be replay the complete log.
  /// 
  /// If there's no change, no flush 
  /// will be performed.
  /// 
  void flushState() {
    if (_index.changesCount == 0) return;
    _log.indexSerializer(_index).conclude();
    _log.flush();
  }

  /// Flush state of storage and close.
  /// 
  /// In case a storage is not flushed and closed
  /// the complete log needs to be replayed to
  /// restore it's management state, thus
  /// making opening it slower.
  /// 
  /// Hint: always [close] a storage.
  /// 
  void close() {
    assert(_isOpen, _closedErrorMsg);
    _isOpen = false;
    flushState();
    // _log.flushAndClose();
    _log.close();
  }

  /// Close currently open storage and open other path.
  /// 
  /// Before opening the other path the currently open
  /// storage's state is flushed and closed.
  /// 
  /// After method concludes storage is reading 
  /// from and writing to new path.
  /// 
  void shiftToPath(String newPath) {
    assert(_isOpen, _closedErrorMsg);

    // Closing operations must reflect [close]
    flushState();
    _log.close();

    // Reset internal state
    path = newPath;
    _index.clear();
    _log = CommitFile(path);
    _readIndex();
  }
}
