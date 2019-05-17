import 'dart:async';
import 'control_chars.dart';
import 'entry_info_private.dart';
import 'entry_info.dart';
import 'line_deserializer.dart';
import '../index.dart';
import '../commit_file/line_data.dart';

Future<Index> deserializeIndex(Stream<LineData> reversedLinesReplay) async {
  Index index;
  var reverseRest = List<LineData>();
  await for(LineData line in reversedLinesReplay) {
    if (ControlChars.newlineBytes.first == line.first) {
      var d = LineDeserializer(line);
      var info = d.entryInfo as IndexInfo;
      index = Index.decode(Index.staticType, info.modelVersion, d);
      break;
    } else {
      reverseRest.add(line);
    }
  }
  if (index == null) {
    index = Index();
  }
  for (LineData line in reverseRest.reversed) {
    var d = LineDeserializer(line);
    var info = d.entryInfo;
    if (info is ModelInfo || info is ValueInfo) {
      index[info.key] = line.startIndex;
    } else if (info is RemoveInfo) {
      index.remove(info.key);
    }
  }
  return index;
}