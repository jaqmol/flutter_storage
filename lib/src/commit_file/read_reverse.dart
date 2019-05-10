import 'dart:async';
import 'dart:io';

Stream<List<int>> readReverse(File file) async* {
  await for (_Range range in _reverseRanges(file)) {
    var reader = file.openRead(range.start, range.end);
    await for (List<int> data in reader) {
      yield data.reversed.toList();
    }
  }
}

Stream<_Range> _reverseRanges(File file) async* {
  const chunkSize = 65000;
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