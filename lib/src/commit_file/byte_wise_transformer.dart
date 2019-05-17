import 'dart:async';
import 'byte_data.dart';

StreamTransformer<List<int>, ByteData> byteWiseTransformer(int startIndex) {
  int currentIndex = startIndex;
  return StreamTransformer<List<int>, ByteData>.fromHandlers(
    handleData: (List<int> batch, EventSink<ByteData> sink) {
      for (int byte in batch) {
        sink.add(ByteData(currentIndex, byte));
        currentIndex++;
      }
    },
  );
}