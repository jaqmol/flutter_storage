import 'dart:io';
import 'dart:async';
import 'read_line_transformer.dart';
import 'read_lines_transformer.dart';
import 'line_writer.dart';
import 'read_reverse.dart';

class CommitFile {
  File _file;
  final String path;

  CommitFile(this.path){
    _file = File(path);
    var type = FileSystemEntity.typeSync(path);
    if (type == FileSystemEntityType.notFound) {
      _file.createSync();
    }
  }

  Future<int> length() => _file.length();

  StreamSink<List<int>> writeLine() {
    return LineWriter(_file.openWrite(mode: FileMode.append));
  }

  Stream<List<int>> readLine(int startIndex) {
    return _file.openRead(startIndex).transform<List<int>>(ReadLineTransformer());
  }

  Stream<Stream<List<int>>> readLines() {
    return _file.openRead(0).transform<Stream<List<int>>>(ReadLinesTransformer());
  }

  Stream<Stream<List<int>>> readLinesReverse() {
    return readReverse(_file).transform<Stream<List<int>>>(ReadLinesTransformer());
  }
}
