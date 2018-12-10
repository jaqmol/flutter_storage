import 'serialization.dart';
import 'package:meta/meta.dart';
import 'log_file.dart';
import 'dart:collection';
import 'frontend_entries.dart';

typedef bool HasValueForKeyFn(String key);
typedef String GetValueForKeyFn(String key);

class StorageBackendIterable extends IterableBase<StorageDecodeEntry> {
  final LogFile _log;
  final Iterator<MapEntry<String, LogRange>> _ito;
  final HasValueForKeyFn _hasCachedValue;
  final GetValueForKeyFn _getCachedValue;

  StorageBackendIterable(this._log, this._ito, this._hasCachedValue, this._getCachedValue);

  Iterator<StorageDecodeEntry> get iterator => StorageBackendIterator(
    _log, _ito, _hasCachedValue, _getCachedValue,
  );
}

class StorageBackendIterator implements Iterator<StorageDecodeEntry> {
  final LogFile _log;
  final Iterator<MapEntry<String, LogRange>> _ito;
  final HasValueForKeyFn hasCachedValue;
  final GetValueForKeyFn getCachedValue;

  StorageBackendIterator(this._log, this._ito, this.hasCachedValue, this.getCachedValue);

  bool moveNext() => _ito.moveNext();

  StorageDecodeEntry get current {
    var entry = _ito.current;
    Deserializer deserialize;
    if (hasCachedValue(entry.key)) {
      var value = getCachedValue(entry.key);
      deserialize = Deserializer(value);
    } else {
      deserialize = modelDeserializerForRange(entry.value, _log);
    }
    return StorageDecodeEntry(entry.key, deserialize);
  }
}

Deserializer modelDeserializerForRange(
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

abstract class ValueEntry extends Model {}

class StorageStateEntry extends ValueEntry {
  static final String type = 'storage-state-entry';
  final List<MapEntry<String, LogRange>> indexEntries;
  final int changesCount;
  final UndoStack undoStack;

  StorageStateEntry({
    @required this.changesCount,
    @required this.indexEntries,
    @required this.undoStack,
  });

  Serializer encode([Serializer serialize]) {
    serialize = serialize ?? Serializer(type);
    serialize.integer(changesCount)
      .collection<MapEntry<String, LogRange>>(
        indexEntries,
        (Serializer s, MapEntry<String, LogRange> entry) => s
          .string(entry.key)
          .integer(entry.value.start)
          .integer(entry.value.length),
      );
    return undoStack.encode(serialize);
  }

  factory StorageStateEntry.decode(Deserializer deserialize) {
    int changesCount = deserialize.integer();
    var indexEntries = deserialize
      .collection<MapEntry<String, LogRange>>(
        (Deserializer d) => MapEntry<String, LogRange>(
          d.string(),
          LogRange(
            d.integer(),
            d.integer(),
          ),
        ),
      );
    var undoStack = UndoStack.decode(deserialize);
    return StorageStateEntry(
      changesCount: changesCount,
      indexEntries: indexEntries,
      undoStack: undoStack,
    );
  }
}

class ChangeValueEntry extends ValueEntry {
  static final String type = 'change-value-entry';
  final String encodedModel;
  final String key;

  ChangeValueEntry({
    @required this.key,
    @required this.encodedModel,
  });
  
  Serializer encode([Serializer serialize]) =>
    (serialize ?? Serializer(type))
      .string(key)
      .raw(encodedModel);

  ChangeValueEntry.decode(Deserializer deserialize)
    : key = deserialize.string(),
      encodedModel = deserialize.raw();
}

class RemoveValueEntry extends ValueEntry {
  static final String type = 'remove-value-entry';
  final String key;

  RemoveValueEntry(this.key);
  
  Serializer encode([Serializer serialize]) =>
    (serialize ?? Serializer(type))
      .string(key);

  RemoveValueEntry.decode(Deserializer deserialize)
    : key = deserialize.string();
}

class ChangesCountEntry extends ValueEntry {
  static final String type = 'changes-count-entry';
  final int changesCount;

  ChangesCountEntry(this.changesCount);
  
  Serializer encode([Serializer serialize]) =>
    (serialize ?? Serializer(type))
      .integer(changesCount);

  ChangesCountEntry.decode(Deserializer deserialize)
    : changesCount = deserialize.integer();
}

// UNDO-SUPPORT

class UndoStack extends ValueEntry with IterableMixin<UndoGroup>{
  static final String type = 'undo-stack';
  final List<UndoGroup> _stack;

  UndoStack([List<UndoGroup> stack])
    : _stack = stack ?? List<UndoGroup>();

  void push(UndoGroup undoGroup) => _stack.add(undoGroup);

  UndoGroup pop() => _stack.length > 0
    ? _stack.removeLast()
    : null;

  int get length => _stack.length;
  UndoGroup operator[] (int i) => _stack[i];

  Iterator<UndoGroup> get iterator => _stack.iterator;

  void clear() => _stack.clear();

  Serializer encode([Serializer serialize]) =>
    (serialize ?? Serializer(type))
      .collection<UndoGroup>(_stack, UndoGroup.encodeGroup);

  UndoStack.decode(Deserializer deserialize)
    : _stack = deserialize.collection<UndoGroup>(UndoGroup.decodeGroup);
}

class UndoGroup extends Model with IterableMixin<UndoRangeItem> {
  static final String type = 'undo-group';
  final List<UndoRangeItem> _items;

  UndoGroup([List<UndoRangeItem> items]) 
    : _items = items ?? List<UndoRangeItem>();

  int get length => _items.length;
  UndoRangeItem operator[] (int i) => _items[i];

  Iterator<UndoRangeItem> get iterator => _items.iterator;

  void add(UndoRangeItem item) => _items.add(item);

  Serializer encode([Serializer serialize]) =>
    (serialize ?? Serializer(type))
      .collection<UndoRangeItem>(
        _items,
        UndoRangeItem.encodeItem,
      );

  static Serializer encodeGroup(Serializer serialize, UndoGroup group) =>
    group.encode(serialize);

  static UndoGroup decodeGroup(Deserializer deserialize) => UndoGroup(
    deserialize.collection<UndoRangeItem>(UndoRangeItem.decodeItem),
  );
}

class UndoRangeItem extends Model {
  static final String type = 'undo-group-item';
  static int typeChange = 0;
  static int typeRemove = 1;
  
  final LogRange range;
  final int undoType;
  final String key;

  UndoRangeItem(this.undoType, this.key, this.range);

  UndoRangeItem.change(this.key, this.range)
    : undoType = typeChange;

  UndoRangeItem.remove(this.key, this.range)
    : undoType = typeRemove;

  Serializer encode([Serializer serialize]) =>
    (serialize ?? Serializer(type))
      .integer(undoType)
      .string(key)
      .integer(range.start)
      .integer(range.length);

  static Serializer encodeItem(
    Serializer s,
    UndoRangeItem i,
  ) => i.encode(s);

  static UndoRangeItem decodeItem(Deserializer deserialize) => UndoRangeItem(
    deserialize.integer(),
    deserialize.string(),
    LogRange(
      deserialize.integer(),
      deserialize.integer(),
    ),
  );
}
