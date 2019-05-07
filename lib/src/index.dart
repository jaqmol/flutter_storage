import 'serialization/model.dart';
import 'serialization/serializer.dart';
import 'serialization/deserializer.dart';

class Index extends Model {
  String type = 'index';
  int version = 0;
  Map<String, int> _data;
  List<MapEntry<String, _Entry>> _changes;

  Index() : _data = Map<String, int>(),
            _changes = List<MapEntry<String, _Entry>>();

  int operator[] (String key) => _data[key] ?? -1;

  Iterable<String> get keys => _data.keys;
  List<int> get startIndexes {
    List<int> idxs = _data.values.toList()..sort();
    return List<int>.unmodifiable(idxs);
  }

  void operator[]= (String key, int startIndex) {
    _data[key] = startIndex;
    _changes.add(MapEntry(key, _ChangeEntry(startIndex)));
  }

  int remove(String key) {
    var lastStartIndex = _data.remove(key);
    if (lastStartIndex != null) {
      _changes.add(MapEntry(key, _RemoveEntry()));
    }
    return lastStartIndex;
  }

  void clear() {
    _data.clear();
    _changes.clear();
  }

  void replaceStartIndexes(Map<int, int> newIdxForOldIdx) {
    _data = _data.map<String, int>((String key, int oldidx) => 
      MapEntry<String, int>(key, newIdxForOldIdx[oldidx]));
    _changes = _data.entries.map<MapEntry<String, _Entry>>((MapEntry<String, int> e) =>
      MapEntry(e.key, _ChangeEntry(e.value))
    ).toList();
  }

  Index updateIndex(Map<String, int> keyStartIndexMapping) {
    _data.addAll(keyStartIndexMapping);
    keyStartIndexMapping.forEach((String key, int startIndex) {
      _changes.add(MapEntry(key, _ChangeEntry(startIndex)));
    });
    return this;
  }

  double get staleRatio {
    return _changes.length.toDouble() / _data.length.toDouble();
  }

  int get length => _data.length;

  String undo() {
    var lastEntry = _changes.last;
    if (lastEntry == null) return null;
    var priorChangeEntry = _changes.lastWhere((MapEntry<String, _Entry> me) => 
      me != lastEntry &&
      me.value is _ChangeEntry &&
      me.key == lastEntry.key
    );
    if (priorChangeEntry != null) {
      var change = priorChangeEntry.value;
      if (change is _ChangeEntry) {
        _data[priorChangeEntry.key] = change.startIndex;
        _changes.removeLast();
      } else if (change is _RemoveEntry) {
        _data.remove(priorChangeEntry.key);
        _changes.removeLast();
      }
    } else {
      _data.remove(lastEntry.key);
      _changes.removeLast();
    }
    return lastEntry.key;
  }
  
  Serializer encode(Serializer serialize) =>
    serialize.list<MapEntry<String, _Entry>>(
      _changes,
      (MapEntry<String, _Entry> me) {
        serialize.string(me.key);
        _Entry e = me.value;
        serialize.string(e.type);
        if (e is _ChangeEntry) {
          serialize.integer(e.startIndex);
        }
      }
    );

  Index.decode(String type, int version, Deserializer deserialize)
    : _changes = deserialize.list<MapEntry<String, _Entry>>(
        () {
          var key = deserialize.string();
          var type = deserialize.string();
          if (_Type.change  == type) {
            int startIndex = deserialize.integer();
            return MapEntry<String, _Entry>(key, _ChangeEntry(startIndex));
          } else {
            return MapEntry<String, _Entry>(key, _RemoveEntry());
          }
        },
      ),
      _data = Map<String, int>() {
        for (MapEntry<String, _Entry> me in _changes) {
          _Entry e = me.value;
          if (e is _ChangeEntry) {
            _data[me.key] = e.startIndex;
          } else if (e is _RemoveEntry) {
            _data.remove(me.key);
          }
        }
      }
}

abstract class _Entry {
  String get type;
}

class _ChangeEntry extends _Entry {
  String get type => _Type.change;
  final int startIndex;
  _ChangeEntry(this.startIndex);
}

class _RemoveEntry extends _Entry {
  String get type => _Type.remove;
  _RemoveEntry();
}

class _Type {
  static String get change => 'C';
  static String get remove => 'R';
}
