import 'dart:async';
import 'byte_data.dart';
import 'line_data.dart';
import '../serialization/control_chars.dart';

StreamTransformer<ByteData, LineData> lineWiseTransformer(int startIndex) {
  int currentIndex = startIndex;
  var line = LineData(currentIndex);
  return StreamTransformer<ByteData, LineData>.fromHandlers(
    handleData: (ByteData byte, EventSink<LineData> sink) {
      currentIndex++;
      if (byte.value == ControlChars.newlineBytes.first) {
        sink.add(line);
        line = LineData(currentIndex);
      } else {
        line.add(byte.value);
      }
    },
    handleDone: (EventSink<LineData> sink) {
      if (line.length != 0) sink.add(line);
      sink.close();
    },
  );
}