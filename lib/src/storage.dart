import 'commit_file/commit_file.dart';
import 'index.dart';
import 'serialization/line_deserializer.dart';
import 'serialization/entry_info_private.dart';
// import 'operators/writer.dart';
// import 'operators/reader.dart';
// import 'operators/controller.dart';
// import "step.dart";
import 'dart:async';

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

  // Future<T> write<T>(WriterCallback<T> callback) {
  //   assert(_isOpen, _closedErrorMsg);
  //   return _addStep<T>(WriteStep<T>(callback));
  // }

  // Future<T> read<T>(ReaderCallback<T> callback) {
  //   assert(_isOpen, _closedErrorMsg);
  //   return _addStep<T>(ReadStep<T>(callback));
  // }

  // Future<T> control<T>(ControlCallback<T> callback) {
  //   assert(_isOpen, _closedErrorMsg);
  //   return _addStep(ControlStep<T>(callback));
  // }

  // void _readIndex() {
  //   var tail = Map<String, int>();
  //   for (LineDeserializer deserialize in _log.indexTail) {
  //     var entryInfo = deserialize.entryInfo;
  //     if (entryInfo is IndexInfo) {
  //       _index = Index.decode(null, entryInfo.modelVersion, deserialize);
  //     } else if (entryInfo != null) {
  //       tail[entryInfo.key] = deserialize.startIndex;
  //     }
  //   }
  //   if (_index == null) {
  //     _index = Index();
  //   }
  //   _index.updateIndex(tail);
  // }

  // void _nextStep() {
  //   if (_sequence.length == 0) return;
  //   var step = _sequence.removeAt(0);
  //   if (step is WriteStep) {
  //     var writer = Writer(_log, _index);
  //     step.completer.complete(step.callback(writer));
  //   } else if (step is ReadStep) {
  //     var reader = Reader(_log, _index);
  //     step.completer.complete(step.callback(reader));
  //   } else if (step is ControlStep) {
  //     var controller = Controller(_log, _index, _path, _isOpen, this._readIndex);
  //     step.completer.complete(step.callback(controller));
  //     _isOpen = controller.isOpen;
  //   }
  //   Timer.run(_nextStep);
  // }

  // Future<T> _addStep<T>(Step oc) {
  //   _sequence.add(oc);
  //   Timer.run(_nextStep);
  //   return oc.completer.future;
  // }
}
