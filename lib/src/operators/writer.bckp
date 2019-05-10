import '../commit_file.dart';
import '../serialization/serializer.dart';
import '../serialization/model.dart';
import '../index.dart';

/// Writer
/// 
class Writer {
  CommitFile _log;
  Index _index;

  Writer(
    CommitFile log,
    Index index,
  ) : assert(log != null),
      assert(index != null),
      this._log = log,
      this._index = index;

  /// Puts the given model for the given key.
  /// 
  /// Logs the change to the underlaying file.
  /// 
  Writer putModel(String key, Model model) {
    var serialize = _log.modelSerializer(key, model.type, model.version);
    serialize = model.encode(serialize);
    _index[key] = serialize.concludeWithStartIndex();
    return this;
  }

  /// Puts one or several values for the given key.
  /// 
  /// Logs the change to the underlaying file.
  /// Putting a value MUST ALWAYS be finished by calling
  /// [conclude()] on the [ValueSerializer].
  /// 
  Serializer putValue(String key) {
    return _log.valueSerializer(
      key,
      (int startIndex) {
        _index[key] = startIndex;
      },
    );
  }

  /// Get a value deserializer for the given key.
  /// 
  /// Check the deserializer's meta field for the
  /// type of the model for decoding.
  ///
  bool remove(String key) {
    var serialize = _log.removeSerializer(key);
    serialize.concludeWithStartIndex();
    var startIndex = _index.remove(key);
    return startIndex > -1;
  }

  // Undo

  /// Undo last change.
  /// Returns the key of the entrie's state that was undone.
  /// 
  String undo() {
    return _index.undo();
  }
}
