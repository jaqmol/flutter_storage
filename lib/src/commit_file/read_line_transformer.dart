import 'dart:async';
import '../serialization/control_chars.dart';

class ReadLineTransformer extends StreamTransformerBase<List<int>, List<int>> {
  final StreamController<List<int>> _controller;
  StreamSubscription<List<int>> _subscription;

  ReadLineTransformer()
    : _controller = StreamController<List<int>>();

  @override
  Stream<List<int>> bind(Stream<List<int>> stream) {
    this._subscription = stream.listen(
      (List<int> data) {
        int newlineIndex = data.indexOf(ControlChars.newlineByte);
        if (newlineIndex > -1) {
          _controller.add(data.sublist(0, newlineIndex));
          _controller.close();
          _subscription.cancel();
        } else {
          _controller.add(data);
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