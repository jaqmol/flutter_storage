import 'dart:io';
import 'dart:async';
import 'line_sink.dart';
import 'reverse_lines_reader.dart';
import 'line_wise_transformer.dart';
import 'byte_wise_transformer.dart';
import 'byte_data.dart';
import 'till_eol_transformer.dart';
import 'line_data.dart';

class CommitFile {
  final File _file;
  final String path;

  CommitFile(this.path)
    : assert(path != null),
      _file = File(path) {
        var type = FileSystemEntity.typeSync(path);
        if (type == FileSystemEntityType.notFound) {
          _file.createSync();
        }
      }

  Future<int> length() => _file.length();

  // TODO TEST
  StreamSink<List<int>> writeLine() =>
    LineSink(_file.openWrite(mode: FileMode.append));

  // TODO TEST Error behavior
  Future<LineData> readLine(int startIndex) =>
    _file.openRead(startIndex)
      .transform<ByteData>(byteWiseTransformer(startIndex))
      .transform<LineData>(TillEolTransformer(startIndex))
      .single;

  // TODO TEST
  Stream<LineData> readLines() =>
    _file.openRead(0)
      .transform<ByteData>(byteWiseTransformer(0))
      .transform<LineData>(lineWiseTransformer(0));

  // TODO TEST
  Stream<LineData> readLinesReverse() => reverseLinesReader(_file);
}
