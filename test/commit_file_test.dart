import 'package:flutter_test/flutter_test.dart';
import '../lib/src/commit_file/commit_file.dart';
import 'dart:io';
import 'dart:convert';
import 'dart:async';

void main() {
  final String testText = """Lorem ipsum dolor sit amet, consectetur adipiscing elit: Quisque augue turpis; varius in dignissim at, tempus id sem. Donec sodales, enim quis semper suscipit, felis diam sollicitudin augue, eu euismod augue ligula sed arcu. Fusce blandit risus in augue auctor, nec faucibus leo placerat. Vivamus suscipit accumsan leo sed rutrum. Nunc non ornare eros. Vivamus eget lacinia felis. Pellentesque eget magna ut lectus tristique auctor. Phasellus rhoncus mi sed cursus placerat. Suspendisse imperdiet urna eget dolor sollicitudin, a faucibus nunc tempor. Cras ut nisi odio. Praesent rhoncus consectetur augue, at condimentum quam laoreet non. Aenean in dictum libero. Fusce molestie tortor nisl, quis varius ligula venenatis sed. Aenean felis ex, sodales sit amet est sed, molestie volutpat lorem. Nam metus ante, varius tincidunt augue ac, blandit lacinia massa. Morbi vitae quam non mi ultrices scelerisque.
Phasellus convallis nibh eros, quis faucibus felis feugiat eu. Morbi augue nisl, convallis a consequat id, dignissim et leo. Mauris eu massa augue. Quisque ornare risus nibh, non porta nisi aliquet sit amet. Donec quis lorem placerat, consequat ipsum viverra, tincidunt tellus. Suspendisse vel metus elementum, hendrerit purus sed, varius dolor. Nullam id porttitor sapien. Donec posuere purus sed ipsum porttitor, at euismod orci accumsan. Donec vestibulum elit id magna fermentum, ac maximus elit mattis. Integer sit amet vulputate ante.
Etiam a magna ligula. Nunc ut vestibulum nulla, quis vulputate quam. Phasellus eget purus pharetra, iaculis mi quis, convallis elit. Donec tempus vitae ex mattis pretium. Cras elementum laoreet justo, ut maximus nunc feugiat eu. Curabitur id lectus blandit, tempor sem id, posuere arcu. Praesent vitae porttitor enim. Proin est nisl, pharetra a mi sed, fringilla congue est. Sed nec ex elit. Nam at magna non libero sodales bibendum id sit amet augue. Mauris a erat elementum, euismod justo ac, lacinia orci. In venenatis nisl a felis dictum, id scelerisque risus rutrum. Ut aliquet turpis id bibendum tempor. Ut imperdiet elementum euismod. Duis placerat congue velit, eu tempus sapien egestas id.
Suspendisse ac ornare libero. Cras commodo erat tellus, vitae ultricies libero tristique eget. Vivamus interdum nibh ut quam viverra, eget auctor quam dictum. Curabitur feugiat vel dolor ut facilisis. Maecenas fermentum pellentesque metus. Fusce eu fringilla dui. Curabitur mattis sapien sit amet eros congue auctor. Vestibulum nec odio dui.
Nunc at nisi eu nunc hendrerit viverra eu eu elit. Phasellus maximus massa eget mi malesuada porttitor ac quis tellus. Sed finibus risus vehicula tellus imperdiet, ac maximus tellus ornare. Donec auctor est vel euismod faucibus. Vestibulum ante ipsum primis in faucibus orci luctus et ultrices posuere cubilia Curae; Vivamus dignissim, lacus vitae mollis dignissim, dolor lectus iaculis sapien, quis vehicula massa ligula eu neque. Vestibulum tincidunt iaculis tempor. Maecenas ligula felis, commodo ut mauris eget, dignissim venenatis eros. Aliquam lobortis egestas aliquam. Vestibulum convallis ipsum non ex cursus fringilla. Nulla auctor enim augue, in auctor ipsum pharetra vitae. Aenean non ex tristique, rutrum turpis id, pharetra eros. Nulla risus justo, lacinia quis mollis eu, venenatis at lacus. Class aptent taciti sociosqu ad litora torquent per conubia nostra, per inceptos himenaeos. Vestibulum tempus neque ac quam convallis viverra. Proin lacinia, arcu eget sollicitudin molestie, nulla quam vulputate lectus, vitae fermentum dui sem id neque.""";

  test('Writing and reading multiple lines', () async {
    var filename = 'commit_file_write_read_multiple_lines_test.scl';
    var f = CommitFile(filename);
    var expectedLines = testText.split('\n');
    for (var l in expectedLines) {
      var s = f.writeLine();
      var el = utf8.encode(l);
      s.add(el);
      await s.close();
    }
    int i = 0;
    await for(Stream<List<int>> line in f.readLines()) {
      var readLine = '';
      await for (List<int> data in line) {
        var chunk = utf8.decode(data);
        readLine += chunk;
      }
      if (i < expectedLines.length) {
        expect(readLine, equals(expectedLines[i]));
      }
      i++;
    }
    await File(filename).delete();
  });

  test('Writing and reading single lines', () async {
    var filename = 'commit_file_write_read_single_lines_test.scl';
    var f = CommitFile(filename);
    var splitText = testText.split('\n');
    var expectedLines = List<String>();
    for (int i = 0; i < 100; i++) {
      for (var l in splitText) {
        expectedLines.add(l);
      }
    }
    var startIndexes = List<int>();
    for (var l in expectedLines) {
      var si = await f.length();
      startIndexes.add(si);
      var s = f.writeLine();
      var el = utf8.encode(l);
      s.add(el);
      await s.close();
    }
    int i = 0;
    for (int startIndex in startIndexes) {
      var readLine = '';
      await for (List<int> data in f.readLine(startIndex)) {
        var chunk = utf8.decode(data);
        readLine += chunk;
      }
      expect(readLine, expectedLines[i]);
      i++;
    }
    await File(filename).delete();
  });

  test('Reading multiple lines reverse', () async {
    var filename = 'commit_file_read_multiple_lines_reverse.scl';
    var f = CommitFile(filename);
    var splitText = testText.split('\n');
    var expectedLines = List<String>();
    for (int i = 0; i < 1; i++) {
      for (var l in splitText) {
        expectedLines.add(l);
      }
    }
    var startIndexes = List<int>();
    for (var l in expectedLines) {
      var si = await f.length();
      startIndexes.add(si);
      var s = f.writeLine();
      var el = utf8.encode(l);
      s.add(el);
      await s.close();
    }
    int i = expectedLines.length - 1;
    await for(Stream<List<int>> reverseLine in f.readLinesReverse()) {
      var readLineData = List<int>();
      await for (List<int> data in reverseLine) {
        readLineData.insertAll(0, data);
      }
      if (i > 0) {
        var readLine = utf8.decode(readLineData.reversed.toList());
        expect(readLine, expectedLines[i]);
      }
      i--;
    }
    await File(filename).delete();
  });
}
