import 'commit_file.dart';
import 'serializer.dart';
import 'deserializer.dart';
import 'model.dart';
import 'index.dart';
import 'line_deserializer.dart';
import 'line_serializer.dart';
import 'entry_info.dart';
import 'entry_info_private.dart';

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
    var tail = List<_EntryIndexAndStartIndex>();
    for (LineDeserializer deserialize in _log.indexTail) {
      var entryInfo = deserialize.entryInfo;
      var startIndex = deserialize.startIndex;
      if (entryInfo is IndexInfo) {
        _index = Index.decode(null, entryInfo.modelVersion, deserialize);
      } else {
        tail.add(_EntryIndexAndStartIndex(entryInfo, startIndex));
      }
    }
    if (_index == null) {
      _index = Index();
    }
    for (_EntryIndexAndStartIndex item in tail) {
      _index[item.entryInfo.key] = item.startIndex;
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
    var serialize = _log.modelSerializer(key, model.type, model.version);
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
    _log.removeSerializer(key).conclude();
    var startIndex = _index.remove(key);
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
    var keepIndex = Map<String, int>();
    var newIdxForOldIdx = _log.compaction(
      map: (LineDeserializer deserialize) {
        var info = deserialize.entryInfo;
        if (info is ModelInfo || info is ValueInfo) {
          keepIndex[info.key] = deserialize.startIndex;
        } else if (info is RemoveInfo) {
          keepIndex.remove(info.key);
        }
      },
      reduce: () => keepIndex.values,
    );
    _index.replaceIndex(keepIndex.map<String, int>((String key, int oldIdx) {
      return MapEntry<String, int>(key, newIdxForOldIdx[oldIdx]);
    }));
    _log.serializeIndex(_index);
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
    // if (_index.changesCount == 0) return;
    _log.serializeIndex(_index);
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

class _EntryIndexAndStartIndex {
  final EntryInfo entryInfo;
  final int startIndex;
  _EntryIndexAndStartIndex(
    this.entryInfo,
    this.startIndex,
  );
}
