import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_storage/log_file.dart';
import 'dart:math';
import 'dart:io';

void main() {
  var generator = Random.secure();

  test("Writing and reading", () {
    var testData = _TestData();
    var batch1EndIndex = 100;
    var batch2EndIndex = batch1EndIndex * 2;
    var dataPrefix = 'Writing and reading test line';
    var file = LogFile(_TestData.filename);

    _writeLines(
      dataPrefix, 0, batch1EndIndex, file, 
      testData.lines, testData.ranges,
    );

    file.flushAndClose();
    file = LogFile(_TestData.filename);

    _writeLines(
      dataPrefix, batch1EndIndex, batch2EndIndex, file, 
      testData.lines, testData.ranges,
    );

    _checkWrittenLines(testData.ranges, file, testData.lines);

    File(file.path).deleteSync();
  });

  test("Writing and replaying", () {
    var testData = _TestData();
    var dataPrefix = 'Writing and replaying test line';
    var file = LogFile(_TestData.filename);

    _writeLines(dataPrefix, 0, 100, file, testData.lines, testData.ranges);
    
    int lineIndex = 0;
    for (LogLine ll in file.replay) {
      var range = testData.ranges[lineIndex];
      expect(range.start, equals(ll.range.start));
      expect(range.length, equals(ll.range.length));
      var data = testData.lines[lineIndex];
      expect(ll.data, equals(data));
      lineIndex++;
    }

    File(file.path).deleteSync();
  });

  test("Random alternation of reading and writing", () {
    var testData = _TestData();
    var dataPrefix = 'Random alternation test line';
    var file = LogFile(_TestData.filename);

    void performWrite() {
      _writeLine(
        dataPrefix, testData.lines.length, file,
        testData.lines, testData.ranges,
      );
    }
    for (int i = 0; i < 100; i++) {
      performWrite();
    }

    void performRead() {
      var randomIndex = generator.nextInt(testData.ranges.length);
      var writtenRange = testData.ranges[randomIndex];
      var exptectedLine = testData.lines[randomIndex];
      _readAndCheckLine(writtenRange, file, exptectedLine);
    }

    var performers = <VoidFn>[performRead, performWrite];
    for (int i = 0; i < 100; i++) {
      performers[generator.nextInt(performers.length)]();
    }

    File(file.path).deleteSync();
  });

  test("Compaction", () {
    var file = LogFile(_TestData.filename);

    for (int i = 0; i < 100; i++) {
      file.appendLine('remove $i');
      file.appendLine('keep $i');
    }

    file.flush();
    var fullSize = File(_TestData.filename).lengthSync();
    var fullRemoveCount = _occurrencesCount(_TestData.filename, 'remove');
    var fullKeepCount = _occurrencesCount(_TestData.filename, 'keep');
    expect(fullRemoveCount, equals(fullKeepCount));
    
    var compactionList = <String>[];
    file.compaction(
      map: (LogRange range, String line) {
        if (line.startsWith('keep')) compactionList.add(line);
      },
      reduce: () => compactionList,
    );

    var compactSize = File(_TestData.filename).lengthSync();
    expect(fullSize, greaterThan(compactSize));

    var compactRemoveCount = _occurrencesCount(_TestData.filename, 'remove');
    expect(compactRemoveCount, equals(0));
    var compactKeepCount = _occurrencesCount(_TestData.filename, 'keep');
    expect(compactKeepCount, equals(fullKeepCount));

    File(file.path).deleteSync();
  });

  test("Reading last line", () {
    var file = LogFile(_TestData.filename);
    
    file.appendLine('Test line 1');
    file.flush();

    var lastLine = file.lastLine;
    expect(lastLine, equals('Test line 1'));

    for (var i = 1; i < 10; i++) {
      file.appendLine('Test line ${i + 1}');
    }
    file.flush();

    lastLine = file.lastLine;
    expect(lastLine, equals('Test line 10'));

    File(file.path).deleteSync();
  });
}

typedef void VoidFn();

class _TestData {
  static final String filename = 'log-file-test-file.log';
  List<LogRange> ranges;
  List<String> lines;

  _TestData()
    : ranges = List<LogRange>(),
      lines = List<String>();
}

void _writeLines(
  String dataPrefix,
  int startIndex,
  int amount,
  LogFile file,
  List<String> linesCollector,
  List<LogRange> rangesCollector,
) {
  for (int i = startIndex; i < amount; i++) {
    _writeLine(
      dataPrefix, i, file,
      linesCollector, rangesCollector,
    );
  }
}

void _writeLine(
  String dataPrefix,
  int index,
  LogFile file,
  List<String> linesCollector,
  List<LogRange> rangesCollector,
) {
  var data = '$dataPrefix $index';
  linesCollector.add(data);
  var range = file.appendLine(data);
  rangesCollector.add(range);
}

void _checkWrittenLines(
  List<LogRange> writtenRanges,
  LogFile file,
  List<String> exptectedLines,
) {
  for (int i = 0; i < writtenRanges.length; i++) {
    _readAndCheckLine(
      writtenRanges[i],
      file,
      exptectedLines[i],
    );
  }
}

void _readAndCheckLine(
  LogRange writtenRange,
  LogFile file,
  String exptectedLine,
) {
  var writtenData = file.readRange(writtenRange);
  expect(writtenData, equals(exptectedLine));
}

int _occurrencesCount(String filePath, String searchString) {
  var content = File(filePath).readAsStringSync();
  return content.allMatches(searchString).length;
}