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
  
  StorageBackend(this.path)
    : _index = HashMap<String, LogRange>(),
      _cache = HashMap<String, String>(),
      _undoStack = UndoStack(),
      _log = LogFile(path),
      _isOpen = true {
        _initState();
      }

  // Map API

  /// Sets the given key to the given value.
  /// 
  /// Logs the change to the underlaying file.
  /// Keeps the value in the cache until [clearCache] is called.
  /// To make a batch of changes undoable, wrap them in both:
  /// [openUndoGroup] and [closeUndoGroup].
  /// 
  void operator[]= (String key, Model model) {
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
        _openUndoGroup.add(UndoGroupItem.change(key, previousRange));
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
  /// of [StorageBackendEncodeEntry]s.
  /// 
  void addEntries(Iterable<StorageBackendEncodeEntry> entries) {
    for (StorageBackendEncodeEntry entry in entries) {
      this[entry.key] = entry.value;
    }
  }

  /// Get a value deserializer for the given key.
  /// 
  /// Check the deserializer's meta field for the
  /// type of the model for decoding.
  /// 
  Deserializer operator[] (String key) {
    assert(_isOpen, _closedErrorMsg);
    Deserializer value;
    if (_cache.containsKey(key)) {
      value = Deserializer(_cache[key]);
    } else {
      LogRange range = _index[key];
      if (range != null) {
        value = _modelDeserializerForRange(range, _log, key, _cache);
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
      _openUndoGroup.add(UndoGroupItem.remove(key, range));
    }
    var deserialize = _modelDeserializerForRange(range, _log);
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
  /// Returns a [StorageBackendUndoGroup] containing
  /// all [StorageBackendUndoAction]s for the user to 
  /// further process undo actions.
  /// 
  StorageBackendUndoGroup undo() {
    var group = _undoStack.pop();
    for (UndoGroupItem item in group) {
      // Change and Remove have the same effect on index and cache
      _index[item.key] = item.range;
      _cache.remove(item.key);
    }
    return StorageBackendUndoGroup(group.iterator, this);
  }



  // Iteration Support

  /// Iterate keys and values
  /// 
  Iterable<StorageBackendDecodeEntry> get entries {
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
        return _modelDeserializerForRange(entry.value, _log);
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
  void flushStateAndClose() async {
    assert(_isOpen, _closedErrorMsg);
    _isOpen = false;
    flushState();
    _log.flushAndClose();
  }
}

Deserializer _modelDeserializerForRange(
  LogRange range,
  LogFile log,
  [String key, HashMap<String, String> cache]
) {
  String value = log.readRange(range);
  var entry = ChangeValueEntry.decode(Deserializer(value));
  if (key != null && cache != null) {
    cache[key] = entry.encodedModel;
  }
  return Deserializer(entry.encodedModel);
}

/// StorageBackendDecodeEntry
/// 
/// Iteration entry.
/// The [key] identifies the key-value-pair.
/// The [value] is the deserializer of the gicen value.
/// [Deserializer.meta.type] helps with identifying the encoded data's type.
/// 
class StorageBackendDecodeEntry {
  final Deserializer value;
  final String key;

  StorageBackendDecodeEntry(this.key, this.value);
}

/// StorageBackendEncodeEntry
/// 
/// Add a collection entry.
/// The [key] identifies the key-value-pair.
/// The [value] is the model to be added.
/// 
class StorageBackendEncodeEntry<T extends Model> {
  final String key;
  final T value;

  StorageBackendEncodeEntry(this.key, this.value);
}


/// StorageBackendUndoGroup
/// 
/// Groups [StorageBackendUndoAction]s.
/// Exposes an iterable interface throught an iterator.
/// 
class StorageBackendUndoGroup extends IterableBase {
  final Iterator<UndoGroupItem> _ito;
  final StorageBackend _backend;

  StorageBackendUndoGroup(this._ito, this._backend);

  StorageBackendUndoGroupIterator get iterator {
    return StorageBackendUndoGroupIterator(_ito, _backend);
  }
}

class StorageBackendUndoGroupIterator implements Iterator<StorageBackendUndoAction> {
  final Iterator<UndoGroupItem> _ito;
  final StorageBackend _backend;

  StorageBackendUndoGroupIterator(this._ito, this._backend);

  bool moveNext() => _ito.moveNext();

  StorageBackendUndoAction get current {
    var item = _ito.current;
    var deserialize = _backend[item.key];
    return StorageBackendUndoAction(
      item.undoType,
      item.key,
      deserialize,
    );
  }
}

/// StorageBackendUndoAction
/// 
/// Represents an action that was undone.
/// Process this action according to it's [type].
/// The static fields [typeChange] and [typeRemove] 
/// can be used for identification.
/// 
class StorageBackendUndoAction {
  static final int typeChange = UndoGroupItem.typeChange;
  static final int typeRemove = UndoGroupItem.typeRemove;
  final Deserializer value;
  final String key;
  final int type;

  StorageBackendUndoAction(this.type, this.key, this.value);
}



typedef bool HasValueForKeyFn(String key);
typedef String GetValueForKeyFn(String key);

class StorageBackendIterable extends IterableBase<StorageBackendDecodeEntry> {
  final LogFile _log;
  final Iterator<MapEntry<String, LogRange>> _ito;
  final HasValueForKeyFn _hasCachedValue;
  final GetValueForKeyFn _getCachedValue;

  StorageBackendIterable(this._log, this._ito, this._hasCachedValue, this._getCachedValue);

  Iterator<StorageBackendDecodeEntry> get iterator => StorageBackendIterator(
    _log, _ito, _hasCachedValue, _getCachedValue,
  );
}

class StorageBackendIterator implements Iterator<StorageBackendDecodeEntry> {
  final LogFile _log;
  final Iterator<MapEntry<String, LogRange>> _ito;
  final HasValueForKeyFn hasCachedValue;
  final GetValueForKeyFn getCachedValue;

  StorageBackendIterator(this._log, this._ito, this.hasCachedValue, this.getCachedValue);

  bool moveNext() => _ito.moveNext();

  StorageBackendDecodeEntry get current {
    var entry = _ito.current;
    Deserializer deserialize;
    if (hasCachedValue(entry.key)) {
      var value = getCachedValue(entry.key);
      deserialize = Deserializer(value);
    } else {
      deserialize = _modelDeserializerForRange(entry.value, _log);
    }
    return StorageBackendDecodeEntry(entry.key, deserialize);
  }
}