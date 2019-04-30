import 'model.dart';
import 'serializer.dart';
import 'deserializer.dart';

class Index extends Model {
  String type = 'index';
  int version = 0;
  Map<String, int> _data;
  List<MapEntry<String, _Entry>> _changes;

  Index() : _data = Map<String, int>(),
            _changes = List<MapEntry<String, _Entry>>();

  int operator[] (String key) => _data[key];

  Iterable<String> get keys => _data.keys;
  Iterable<int> get startIndexes => _data.values;

  void operator[]= (String key, int startIndex) {
    _data[key] = startIndex;
    _changes.add(MapEntry(key, _ChangeEntry(startIndex)));
  }

  int remove(String key) {
    var lastStartIndex = _data.remove(key);
    if (lastStartIndex != null) {
      _changes.add(MapEntry(key, _RemoveEntry(lastStartIndex)));
    }
    return lastStartIndex;
  }

  void clear() {
    _data.clear();
    _changes.clear();
  }

  void replaceIndex(Map<String, int> keyStartIndexMapping) {
    _data = keyStartIndexMapping;
    _changes = _data.entries.map<MapEntry<String, _Entry>>((MapEntry<String, int> e) {
      return MapEntry(e.key, _ChangeEntry(e.value));
    }).toList();
  }

  double get staleRatio {
    return _changes.length.toDouble() / _data.length.toDouble();
  }

  int get length => _data.length;
  // int get changesCount => _changesCount;

  void undo() {
    var changeEntry = _changes.last;
    if (changeEntry == null) return;
    var lastChangeEntry = _changes.lastWhere((var entry) => 
      entry != changeEntry && 
      entry.key == changeEntry.key
    );
    if (lastChangeEntry != null) {
      var change = lastChangeEntry.value;
      if (change is _ChangeEntry) {
        _data[lastChangeEntry.key] = change.startIndex;
        _changes.removeLast();
      } else if (change is _RemoveEntry) {
        _data.remove(lastChangeEntry.key);
        _changes.removeLast();
      }
    } else {
      _data.remove(changeEntry.key);
      _changes.removeLast();
    }
  }
  
  Serializer encode(Serializer serialize) =>
    serialize.list<MapEntry<String, _Entry>>(
      _changes,
      (MapEntry<String, _Entry> me) {
        serialize.string(me.key);
        var v = me.value;
        serialize.string(v.type);
        serialize.integer(v.startIndex);
      }
    );

  Index.decode(String type, int version, Deserializer deserialize)
    : _changes = deserialize.list<MapEntry<String, _Entry>>(
        () {
          var key = deserialize.string();
          var type = deserialize.string();
          var startIndex = deserialize.integer();
          return MapEntry<String, _Entry>(
            key, 
            _Entry.create(type, startIndex),
          );
        },
      ),
      _data = Map<String, int>() {
        for (MapEntry<String, _Entry> me in _changes) {
          _Entry e = me.value;
          if (e is _ChangeEntry) {
            _data[me.key] = e.startIndex;
          }
        }
      }
}

abstract class _Entry {
  int get startIndex;
  String get type;

  static _Entry create(String type, int startIndex) =>
    type == _Type.change
      ? _ChangeEntry(startIndex)
      : _RemoveEntry(startIndex);
}

class _ChangeEntry extends _Entry {
  final int startIndex;
  _ChangeEntry(this.startIndex);
  String get type => 'C';
}

class _RemoveEntry extends _Entry {
  final int startIndex;
  _RemoveEntry(this.startIndex);
  String get type => 'R';
}

class _Type {
  static String get change => 'C';
  static String get remove => 'R';
}

// enum _Type {
//   Change,
//   Remove,
// }
