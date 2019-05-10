import 'commit_file/commit_file.dart';
import 'index.dart';
import 'serialization/line_deserializer.dart';
import 'serialization/entry_info_private.dart';
import 'serialization/serializer.dart';
import 'serialization/deserializer.dart';
import 'serialization/line_serializer.dart';
import 'serialization/model.dart';
// import 'operators/writer.dart';
// import 'operators/reader.dart';
// import 'operators/controller.dart';
// import "step.dart";
import 'dart:async';

// TODO: Refactore in DataBatch-support

const String _closedErrorMsg = "Storage cannot be used after it's closed";

/// Storage
/// 
class Storage {
  CommitFile _log;
  Index _index;
  String _path;
  bool _isOpen;
  // final List<Step> _sequence;
  
  Storage(String path)
    : assert(path != null),
      _index = Index(),
      _log = CommitFile(path),
      _path = path,
      _isOpen = true /*,
      _sequence = List<Step>()*/ {
        // _readIndex();
      }
  


  // Writing

  Future putModel(String key, Model model) async {
    var startIndex = await _log.length();
    var s = LineSerializer.model(
      sink: _log.writeLine(),
      key: key,
      modelType: model.type,
      modelVersion: model.version,
      startIndex: startIndex,
    );
    s.model(model);
    return s.conclude();
  }

  Future<Serializer> putValue(String key) async {
    var startIndex = await _log.length();
    return LineSerializer.value(
      sink: _log.writeLine(),
      key: key,
      startIndex: startIndex,
    );
  }

  bool remove(String key) {

  }

  void undo() {

  }

  // Reading

  void getEntry(String key) {

  }

  Iterable<String> get keys {

  }

  Iterable<Deserializer> get values {

  }

  // Controlling

  double get staleRatio {

  }
  bool get needsCompaction {

  }

  Storage compaction() {

  }

  Storage flush() {

  }

  void close() {

  }

  Storage shiftToPath(String newPath) {

  }

  bool get isOpen => _isOpen;
}
