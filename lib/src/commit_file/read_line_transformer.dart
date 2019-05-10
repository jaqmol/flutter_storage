import 'dart:async';
import '../serialization/control_chars.dart';
import 'data_batch.dart';

class ReadLineTransformer extends StreamTransformerBase<List<int>, DataBatch> {
  final int startIndex;
  final StreamController<DataBatch> _controller;
  StreamSubscription<DataBatch> _subscription;

  ReadLineTransformer(this.startIndex)
    : _controller = StreamController<List<int>>();

  @override
  Stream<DataBatch> bind(Stream<List<int>> stream) {
    this._subscription = stream.listen(
      (List<int> data) {
        int newlineIndex = data.indexOf(ControlChars.newlineBytes.first);
        if (newlineIndex > -1) {
          _controller.add(DataBatch(startIndex, data.sublist(0, newlineIndex)));
          _controller.close();
          _subscription.cancel();
        } else {
          _controller.add(DataBatch(startIndex, data));
        }
      },
      onError: (Object error, [StackTrace trace]) {
        _controller.addError(error, trace);
        _controller.close();
        _subscription.cancel();
      },
      onDone: () {
        _controller.close();
        _subscription.cancel();
      },
      cancelOnError: true,
    );
    return _controller.stream;
  }
}