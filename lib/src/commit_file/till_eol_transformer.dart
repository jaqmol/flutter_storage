import 'dart:async';
import '../serialization/control_chars.dart';
import 'byte_data.dart';
import 'line_data.dart';

class TillEolTransformer extends StreamTransformerBase<ByteData, LineData> {
  final StreamController<LineData> _controller;
  final LineData _line;
  StreamSubscription<ByteData> _subscription;

  TillEolTransformer(int startIndex)
    : _controller = StreamController<LineData>(),
      _line = LineData(startIndex);

  @override
  Stream<LineData> bind(Stream<ByteData> stream) {
    this._subscription = stream.listen(
      (ByteData byte) {
        if (byte.value == ControlChars.newlineBytes.first) {
          _controller.add(_line);
          _subscription.cancel();
          _controller.close();
        } else {
          _line.add(byte.value);
        }
      },
      cancelOnError: true,
    );
    return _controller.stream;
  }
}