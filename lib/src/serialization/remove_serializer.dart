import 'package:meta/meta.dart';
import 'entry_info.dart';
import 'entry_info_private.dart';
import 'dart:async';
import 'dart:convert';

class RemoveSerializer {
  final StreamSink<List<int>> _sink;
  final EntryInfo entryInfo;
  final int startIndex;

  RemoveSerializer({
    @required StreamSink<List<int>> sink,
    @required String key,
    @required this.startIndex,
  }): assert(sink != null),
      assert(key != null),
      assert(startIndex != null),
      _sink = sink,
      entryInfo = RemoveInfo(key) {
        _sink.add(utf8.encode(entryInfo.toString()));
      }

  Future conclude() {
    return _sink.close();
  }
}