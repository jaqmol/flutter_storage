import '../commit_file.dart';
import '../serialization/deserializer.dart';
import '../index.dart';

/// Reader
/// 
/// Backing store for commit log with map-interface.
/// 
class Reader {
  CommitFile _log;
  Index _index;

  Reader(
    CommitFile log,
    Index index,
  ) : assert(log != null),
      assert(index != null),
      this._log = log,
      this._index = index;

  /// Get a deserializer for the given key.
  /// 
  /// Check the deserializer's meta field for the
  /// type.
  /// 
  Deserializer getEntry(String key) {
    int startIndex = _index[key];
    if (startIndex == -1) return null;
    return _log.deserializer(startIndex);
  }

  // Iteration

  /// Iterate keys only
  /// 
  Iterable<String> get keys {
    return _index.keys;
  }

  /// Iterate values only
  /// 
  Iterable<Deserializer> get values {
    return _index.startIndexes
      .map((int startIndex) => _log.deserializer(startIndex));
  }
}
