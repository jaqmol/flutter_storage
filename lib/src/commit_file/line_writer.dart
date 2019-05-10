import 'dart:async';
import 'dart:io';
import '../serialization/control_chars.dart';

class LineWriter implements StreamSink<List<int>> {
  final IOSink _sink;

  LineWriter(this._sink);

  @override
  void add(List<int> data) {
    _sink.add(data);
  }

  @override
  void addError(Object error, [StackTrace stackTrace]) {
    _sink.addError(error, stackTrace);
  }

  @override
  Future addStream(Stream<List<int>> stream) {
    return _sink.addStream(stream);
  }

  @override
  Future close() async {
    _sink.add(ControlChars.newlineBytes);
    await _sink.flush();
    return _sink.close();
  }

  @override
  Future get done => _sink.done;
}
