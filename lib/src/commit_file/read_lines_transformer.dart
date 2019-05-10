import 'dart:async';
import '../serialization/control_chars.dart';
import 'data_batch.dart';

class ReadLinesTransformer extends StreamTransformerBase<List<int>, Stream<DataBatch>> {
  final StreamController<Stream<DataBatch>> _replayCtrl;
  StreamController<DataBatch> _lineCtrl;
  StreamSubscription<DataBatch> _subscription;
  int _startIndex;

  ReadLinesTransformer()
    : _replayCtrl = StreamController<Stream<DataBatch>>(),
      _lineCtrl = StreamController<DataBatch>(),
      _startIndex = 0 {
        _replayCtrl.add(_lineCtrl.stream);
      }

  void _newLineCtrl() {
    _lineCtrl.close();
    _lineCtrl = StreamController<DataBatch>();
    _replayCtrl.add(_lineCtrl.stream);
  }

  @override
  Stream<Stream<DataBatch>> bind(Stream<List<int>> stream) {
    this._subscription = stream.listen(
      (List<int> data) async {
        var newlineIndexes = _newlineIndexes(data);
        if (newlineIndexes.length > 0) {
          await for (var line in _yieldLines(_startIndex, data, newlineIndexes)) {
            _lineCtrl.add(line);
            _newLineCtrl();
          }
        } else {
          _lineCtrl.add(DataBatch(_startIndex, data));
        }
        _startIndex += data.length;
      },
      onError: (Object error, [StackTrace trace]) {
        _lineCtrl.close();
        _replayCtrl.addError(error, trace);
        _replayCtrl.close();
        _subscription.cancel();
      },
      onDone: () {
        _lineCtrl.close();
        _replayCtrl.close();
        _subscription.cancel();
      },
      cancelOnError: true,
    );
    return _replayCtrl.stream;
  }

  List<int> _newlineIndexes(List<int> data) {
    int i = 0;
    return data.fold(List<int>(), (var a, int b) {
      if (ControlChars.newlineBytes.first == b) a.add(i);
      i++;
      return a;
    });
  }

  Stream<DataBatch> _yieldLines(int startIndex, List<int> data, List<int> newlineIndexes) async* {
    var starts = newlineIndexes.map<int>((int i) => i + 1).toList()..insert(0, 0);
    var ends = newlineIndexes.toList()..add(data.length);
    for (int i = 0; i < starts.length; i++) {
      var sublist =  data.sublist(starts[i], ends[i]);      
      if (sublist.length > 0) yield DataBatch(startIndex, sublist);
    }
  }
}
