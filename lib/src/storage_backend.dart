import 'dart:collection';
import 'log_file.dart';
import 'storage_entries.dart';
import 'serialization.dart';

const String _closedErrorMsg = "Storage cannot be used after it's closed";

/// StorageBackend
/// 
/// Backing store for commit log with map-interface.
/// 
class StorageBackend {
  final HashMap<String, LogRange> _index;
  final HashMap<String, String> _cache;
  int _openUndoGroupsCount = 0;
  final UndoStack _undoStack;
  UndoGroup _openUndoGroup;
  int _changesCount = 0;
  final LogFile _log;
  final String path;
  bool _isOpen;
  
  StorageBackend(this.path /*, [this.fromFrontend, this.toFrontend]*/)
    : _index = HashMap<String, LogRange>(),
      _cache = HashMap<String, String>(),
      _undoStack = UndoStack(),
      _log = LogFile(path),
      _isOpen = true {
        _initState();
      }

  /// Sets the given value for the given key.
  /// 
  /// Logs the change to the underlaying file.
  /// Keeps the value in the cache until [clearCache] is called.
  /// To make a batch of changes undoable, wrap them in both:
  /// [openUndoGroup] and [closeUndoGroup].
  /// 
  // void operator[]= (String key, Model model) {
  void setValue(String key, Model model) {
    assert(_isOpen, _closedErrorMsg);
    var encodedModel = model.encode()();
    var entry = ChangeValueEntry(
      encodedModel: encodedModel,
      key: key,
    );
    var previousRange = _index[key];
    if (previousRange != null) {
      // If undos are logged right away, the undo
      // stack becomes difficult to manage.
      if (_openUndoGroup != null) {
        _openUndoGroup.add(UndoRangeItem.change(key, previousRange));
      }
      _changesCount++;
    }
    var value = entry.encode()();
    _index[key] = _log.appendLine(value);
    _cache[key] = encodedModel;
  }

  /// Adding a collection of key-value-pairs.
  /// 
  /// The key-value-pairs need to be provided as iterable
  /// of [StorageEncodeEntry]s.
  /// 
  void addEntries(Iterable<StorageEncodeEntry> entries) {
    for (StorageEncodeEntry entry in entries) {
      // this[entry.key] = entry.value;
      setValue(entry.key, entry.value);
    }
  }

  /// Get a value deserializer for the given key.
  /// 
  /// Check the deserializer's meta field for the
  /// type of the model for decoding.
  /// 
  // Deserializer operator[] (String key) {
  Deserializer value(String key) {
    assert(_isOpen, _closedErrorMsg);
    Deserializer value;
    if (_cache.containsKey(key)) {
      value = Deserializer(_cache[key]);
    } else {
      LogRange range = _index[key];
      if (range != null) {
        value = modelDeserializerForRange(range, _log, key, _cache);
      }
    }
    return value;
  }

  /// Get a value deserializer for the given key.
  /// 
  /// Check the deserializer's meta field for the
  /// type of the model for decoding.
  /// 
  Deserializer remove(String key) {
    assert(_isOpen, _closedErrorMsg);
    var range = _index.remove(key);
    // If undos are logged right away, the undo
    // stack becomes difficult to manage.
    if (_openUndoGroup != null) {
      _openUndoGroup.add(UndoRangeItem.remove(key, range));
    }
    var deserialize = modelDeserializerForRange(range, _log);
    var removeEntry = RemoveValueEntry(key);
    _log.appendLine(removeEntry.encode()());
    _index.remove(key);
    _cache.remove(key);
    _changesCount++;
    return deserialize;
  }

  // Undo Support

  /// Open an undo group to start grouping changes for undo.
  /// 
  /// Close the undo group with [closeUndoGroup].
  /// Call [undo] to revert the storage state.
  /// 
  /// For each call to [openUndoGroup] there must be a
  /// balancing call to [closeUndoGroup].
  /// The current undo group will be concluded only after
  /// the last balancing call to [closeUndoGroup].
  /// 
  void openUndoGroup() {
    bool noGroupOpen = _openUndoGroup == null && _openUndoGroupsCount == 0;
    bool groupsOpen = _openUndoGroup != null && _openUndoGroupsCount > 0;
    assert(noGroupOpen || groupsOpen, "Undo groups must be balanced");
    if (noGroupOpen) {
      _openUndoGroup = UndoGroup();
      _openUndoGroupsCount = 1;
      _undoStack.push(_openUndoGroup);
    } else if (groupsOpen) {
      _openUndoGroupsCount++;
    }
  }

  /// Close an undo group to conclude an undoable collection of changes.
  /// 
  /// Open an undo group with [openUndoGroup].
  /// Call [undo] to revert the storage state.
  /// 
  /// For each call to [openUndoGroup] there must be a
  /// balancing call to [closeUndoGroup].
  /// The current undo group will be concluded only after
  /// the last balancing call to [closeUndoGroup].
  /// 
  void closeUndoGroup() {
    bool groupsOpen = _openUndoGroup != null && _openUndoGroupsCount > 0;
    assert(groupsOpen, "Undo groups must be balanced");
    _openUndoGroupsCount--;
    bool lastGroupClosed = _openUndoGroupsCount == 0 && _openUndoGroup != null;
    if (lastGroupClosed) {
      _openUndoGroup = null;
    }
  }

  /// Undo all changes made in an undo group;
  /// 
  /// Returns a [List<UndoAction>]s containing
  /// all [UndoAction]s for the user to 
  /// further process undo actions.
  /// 
  List<UndoAction> undo() {
    var group = _undoStack.pop();
    var actions = List<UndoAction>();
    for (UndoRangeItem item in group) {
      // Change and Remove have the same effect on index and cache
      _index[item.key] = item.range;
      _cache.remove(item.key);
      actions.add(UndoAction(
        item.undoType,
        item.key,
        value(item.key),
      ));
    }
    return actions;
  }



  // Iteration Support

  /// Iterate keys and values
  /// 
  Iterable<StorageDecodeEntry> get entries {
    assert(_isOpen, _closedErrorMsg);
    return StorageBackendIterable(
      _log, _index.entries.iterator,
      (String key) => _cache.containsKey(key),
      (String key) => _cache[key],
    );
  }

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
    return _index.entries.map((MapEntry<String, LogRange> entry) {
      if (_cache.containsKey(entry.key)) {
        return Deserializer(_cache[entry.key]);
      } else {
        return modelDeserializerForRange(entry.value, _log);
      }
    });
  }

  /// Perform compaction
  /// 
  /// Compaction is the process of reducing all logged
  /// key-value-pairs to the most recent state.
  /// 
  void compaction() {
    assert(_isOpen, _closedErrorMsg);
    var newIndex = HashMap<String, LogRange>();
    var rawValues = HashMap<String, String>();
    _log.compaction(
      map: (LogRange range, String rawVal) {
        var deserialize = Deserializer(rawVal);
        if (deserialize.meta.type == ChangeValueEntry.type) {
          var entry = ChangeValueEntry.decode(deserialize);
          rawValues[entry.key] = rawVal;
          newIndex[entry.key] = range;
        } else if (deserialize.meta.type == RemoveValueEntry.type) {
          var entry = RemoveValueEntry.decode(deserialize);
          rawValues.remove(entry.key);
          newIndex.remove(entry.key);
        }
      },
      reduce: () => rawValues.values,
    );
    _changesCount = 0;
    _index.clear();
    _index.addAll(newIndex);
    _undoStack.clear();
    _cache.clear();
    flushState();
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
    return _changesCount.toDouble() / _index.length.toDouble();
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

  void _initState() {
    var value = _log.lastLine;
    if (value == null) return;
    if (value.length > 0) {
      var deserialize = Deserializer(value);
      if (deserialize.meta.type == StorageStateEntry.type) {
        print('Using the previous state');
        var entry = StorageStateEntry.decode(deserialize);
        _changesCount = entry.changesCount;
        _index.addEntries(entry.indexEntries);
      } else _rebuildState();
    } else _rebuildState();
  }

  void _rebuildState() {
    for (LogLine ll in _log.replay) {
      var deserialize = Deserializer(ll.data);
      if (deserialize.meta.type == ChangeValueEntry.type) {
        var entry = ChangeValueEntry.decode(deserialize);
        _index[entry.key] = ll.range;
      } else if (deserialize.meta.type == RemoveValueEntry.type) {
        var entry = RemoveValueEntry.decode(deserialize);
        _index.remove(entry.key);
      } else if (deserialize.meta.type == ChangesCountEntry.type) {
        var entry = ChangesCountEntry.decode(deserialize);
        _changesCount = entry.changesCount;
      }
    }
  }

  /// Clears the in-memory-cache of storage
  /// 
  /// Removes all cached values. Does not affect indexes
  /// as indexes are always kept in memory.
  /// 
  void clearCache() {
    _cache.clear();
  }

  /// Flush state of storage to solid state.
  /// 
  /// A flush appends all management state of
  /// a storage to the end of the log.
  /// Thus a storage can be opened fast and does not
  /// need to be replay the complete log.
  /// 
  void flushState() {
    var entry = StorageStateEntry(
      changesCount: _changesCount,
      indexEntries: _index.entries.toList(),
      undoStack: _undoStack,
    );
    _log.appendLine(entry.encode()());
  }

  /// Flush state of storage and close.
  /// 
  /// In case a storage is not flushed and closed
  /// the complete log needs to be replayed to
  /// restore it's management state, thus
  /// making opening it slower.
  /// 
  /// Hint: always [flushStateAndClose] a storage.
  /// 
  void flushStateAndClose() {
    assert(_isOpen, _closedErrorMsg);
    _isOpen = false;
    flushState();
    _log.flushAndClose();
  }
}
