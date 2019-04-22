import 'model.dart';
import 'serializer.dart';
import 'deserializer.dart';

class Index extends Model {
  String type = 'index';
  int version = 0;
  final Map<String, int> _data;
  final List<MapEntry<String, _Entry>> _changes;

  Index() : _data = Map<String, int>(),
            _changes = List<MapEntry<String, _Entry>>();

  int operator[] (String key) => _data[key];

  Iterable<String> get keys => _data.keys;
  Iterable<int> get startIndexes => _data.values;

  void clear() {
    _data.clear();
    _changes.clear();
  }

  double get staleRatio {
    return _changes.length.toDouble() / _data.length.toDouble();
  }

  int get changesCount => _changes.length - _data.length;

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
  
  Serializer encode(Serializer serialize) =>
    serialize.list<MapEntry<String, _Entry>>(
      _changes,
      (MapEntry<String, _Entry> me) {
        serialize.string(me.key);
        var v = me.value;
        serialize.integer(v.type.index);
        serialize.integer(v.startIndex);
      }
    );

  Index.decode(String type, int version, Deserializer deserialize)
    : _changes = deserialize.list<MapEntry<String, _Entry>>(
        () {
          var key = deserialize.string();
          var type = _Type.values[deserialize.integer()];
          var index = deserialize.integer();
          return MapEntry<String, _Entry>(key, type == _Type.Change
              ? _ChangeEntry(index)
              : _RemoveEntry(index)
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

class _Entry {
  int _startIndex;
  _Type _type;

  int get startIndex => _startIndex;
  _Type get type => _type;
}

class _ChangeEntry extends _Entry {
  _ChangeEntry(int startIndex) {
    _startIndex = startIndex;
    _type = _Type.Change;
  }
}

class _RemoveEntry extends _Entry {
  _RemoveEntry(int startIndex) {
    _startIndex = startIndex;
    _type = _Type.Remove;
  }
}

enum _Type {
  Change,
  Remove,
}
