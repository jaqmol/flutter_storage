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
    // TODO
  }

  void operator[]= (String key, int startIndex) {
    _data[key] = startIndex;
    _changes.add(MapEntry(key, _ChangeEntry(startIndex)));
  }

  int remove(String key) {
    var si = _data.remove(key);
    if (si != null) {
      _changes.add(MapEntry(key, _RemoveEntry()));
    }
    return si;
  }
  
  Serializer encode(Serializer serialize) =>
    serialize.list<MapEntry<String, _Entry>>(
      _changes,
      (MapEntry<String, _Entry> me) {
        serialize.string(me.key);
        var v = me.value;
        serialize.integer(v.type.index);
        if (v is _ChangeEntry) {
          serialize.integer(v.startIndex);
        }
      }
    );

  Index.decode(String type, int version, Deserializer deserialize)
    : _changes = deserialize.list<MapEntry<String, _Entry>>(
        () {
          var k = deserialize.string();
          var t = _Type.values[deserialize.integer()];
          return MapEntry<String, _Entry>(k, t == _Type.Change
              ? _ChangeEntry(deserialize.integer())
              : _RemoveEntry()
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
  _Type type;
}

class _ChangeEntry extends _Entry {
  final int startIndex;

  _ChangeEntry(this.startIndex) {
    type = _Type.Change;
  }
}

class _RemoveEntry extends _Entry {
  _RemoveEntry() {
    type = _Type.Remove;
  }
}

enum _Type {
  Change,
  Remove,
}
