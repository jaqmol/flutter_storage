import 'package:meta/meta.dart';
import 'entry_info.dart';
import 'entry_info_private.dart';
import 'dart:async';
import 'dart:convert';

class RemoveSerializer {
  final StreamSink<List<int>> _sink;
  final EntryInfo entryInfo;

  RemoveSerializer({
    @required StreamSink<List<int>> sink,
    @required String key,
  }): assert(sink != null),
      assert(key != null),
      _sink = sink,
      entryInfo = RemoveInfo(key) {
        _sink.add(utf8.encode(entryInfo.toString()));
      }

  Future<void> close() => _sink.close();
}