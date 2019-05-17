import 'dart:async';
import 'dart:io';
import 'byte_data.dart';
import 'line_data.dart';
import '../serialization/control_chars.dart';

/// Returns lines in reversed order, last line first, each line in correct order
Stream<LineData> reverseLinesReader(File file) async* {
  var acc = List<int>();
  await for (ByteData byte in _reverseBytes(file)) {
    if (byte.value == ControlChars.newlineBytes.first) {
      if (acc.length > 0) {
        yield LineData(byte.index + 1, acc.reversed);
        acc = List<int>();
      }
    } else {
      acc.add(byte.value);
    }
  }
  if (acc.length > 0) {
    yield LineData(0, acc.reversed);
  }
}

Stream<ByteData> _reverseBytes(File file) async* {
  await for (_Range range in _reverseRanges(file)) {
    var reader = file.openRead(range.start, range.end);
    await for (List<int> chunk in reader) {
      for (int i = chunk.length - 1; i >= 0; i--) {
        yield ByteData(i + range.start, chunk[i]);
      }
    }
  }
}

Stream<_Range> _reverseRanges(File file) async* {
  const chunkSize = 64000;
  int len = await file.length();
  int end = len, start = len;
  while (start > -1) {
    start = end - chunkSize;
    if (start < 0) {
      yield _Range(0, end);
      break;
    } else {
      yield _Range(start, end);
    }
    end = start;
  }
}

class _Range {
  final int start;
  final int end;
  _Range(this.start, this.end);
}