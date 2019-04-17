import 'model.dart';
import 'serializer.dart';
import 'deserializer.dart';
import 'dart:collection';

class Index extends Model {
  String type = 'index';
  final Map<String, _Entry> _data;
  final List<MapEntry<String, _Entry>> _changes;

  Index() : _data = Map<String, _Entry>(),
            _changes = List<MapEntry<String, _Entry>>();

  int operator[] (String key) {
    var e = _data[key];
    return e is _ChangeEntry ? e.startIndex : -1;
  }

  void operator[]= (String key, int startIndex) {
    var e = _ChangeEntry(startIndex);
    _data[key] = e;
    _changes.add(MapEntry(key, e));
  }

  int remove(String key) {
    var e = _data.remove(key);
    if (e != null) {
      _changes.add(MapEntry(key, _RemoveEntry()));
      return e is _ChangeEntry ? e.startIndex : -1;
    }
    return -1;
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
      _data = Map<String, _Entry>() {
        _data.addEntries(_changes);
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
