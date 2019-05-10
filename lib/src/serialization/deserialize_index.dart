import 'dart:async';
import 'control_chars.dart';
import 'entry_info_private.dart';
import 'entry_info.dart';
import 'line_deserializer.dart';
import '../index.dart';
import '../commit_file/data_batch.dart';

// TODO: Refactore in DataBatch-support

Future<Index> deserializeIndex(Stream<Stream<List<int>>> reverseLinesReplay, int fileLength) async {
  var lines = List<List<int>>();
  var startIndexes = List<int>();
  int counter = 0;
  Index index;
  await for(Stream<List<int>> reverseLine in reverseLinesReplay) {
    var reversedData = List<int>();
    await for (List<int> data in reverseLine) {
      reversedData.insertAll(0, data);
    }
    var line = reversedData.reversed.toList();
    counter += line.length;
    if (ControlChars.newlineBytes.first == line.first) {
      var d = LineDeserializer(line);
      var info = d.entryInfo as IndexInfo;
      index = Index.decode(Index.staticType, info.modelVersion, d);
      break;
    } else {
      lines.insert(0, line);
      startIndexes.insert(0, fileLength - counter);
    }
  }
  if (index == null) {
    index = Index();
  }
  for (List<int> line in lines) {
    var d = LineDeserializer(line);
    var info = d.entryInfo;
    if (info is ModelInfo) {
      index[info]
    }
  }
  return index;
}