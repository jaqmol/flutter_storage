import 'dart:async';
import '../serialization/control_chars.dart';

class ReadLinesTransformer extends StreamTransformerBase<List<int>, Stream<List<int>>> {
  final StreamController<Stream<List<int>>> _replayCtrl;
  StreamController<List<int>> _lineCtrl;
  StreamSubscription<List<int>> _subscription;

  ReadLinesTransformer()
    : _replayCtrl = StreamController<Stream<List<int>>>(),
      _lineCtrl = StreamController<List<int>>() {
        _replayCtrl.add(_lineCtrl.stream);
      }

  void _newLineCtrl() {
    _lineCtrl.close();
    _lineCtrl = StreamController<List<int>>();
    _replayCtrl.add(_lineCtrl.stream);
  }

  @override
  Stream<Stream<List<int>>> bind(Stream<List<int>> stream) {
    this._subscription = stream.listen(
      (List<int> data) async {
        print('Line-transforming data of length: ${data.length}');
        var newlineIndexes = _newlineIndexes(data);
        if (newlineIndexes.length > 0) {
          await for (var line in _yieldLines(data, newlineIndexes)) {
            _lineCtrl.add(line);
            _newLineCtrl();
          }
        } else {
          _lineCtrl.add(data);
        }
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
      if (ControlChars.newlineByte == b) a.add(i);
      i++;
      return a;
    });
  }

  Stream<List<int>> _yieldLines(List<int> data, List<int> newlineIndexes) async* {
    var starts = newlineIndexes.map<int>((int i) => i + 1).toList()..insert(0, 0);
    var ends = newlineIndexes.toList()..add(data.length);
    for (int i = 0; i < starts.length; i++) {
      var sublist =  data.sublist(starts[i], ends[i]);      
      if (sublist.length > 0) yield sublist;
    }
  }
}
