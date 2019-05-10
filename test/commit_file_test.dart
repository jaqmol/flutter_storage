import 'package:flutter_test/flutter_test.dart';
// import 'line_serializer_utils.dart';
import '../lib/src/commit_file/commit_file.dart';
import '../lib/src/serialization/entry_info.dart';
import '../lib/src/serialization/entry_info_private.dart';
import '../lib/src/index.dart';
import '../lib/src/serialization/line_deserializer.dart';
import 'dart:io';
import 'dart:convert';
import 'dart:async';
// import 'commit_file_utils.dart';

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

  // test('Value serializer and deserializer', () {
  //   var r = CommitFileUtils.serializeValue();
  //   var d = r.commitFile.deserializer(r.startIndex);
  //   expect(d.entryInfo.key, equals(r.key));
  //   var content = d.string();
  //   expect(content, equals(LineSerializerUtils.testText));
  //   File(r.filename).deleteSync();
  // });
  // test('Multiple values serializer and deserializer', () {
  //   var r = CommitFileUtils.serializeMultipleValues();
  //   var shuffledIndexes = List<int>();
  //   for (int i = 0; i < r.keys.length; i++) {
  //     shuffledIndexes.add(i);
  //   }
  //   shuffledIndexes.shuffle();
  //   var readWords = List<String>.filled(r.keys.length, null);
  //   for (int i in shuffledIndexes) {
  //     var d = r.commitFile.deserializer(r.startIndexes[i]);
  //     expect(d.entryInfo.key, equals(r.keys[i]));
  //     readWords[i] = d.string();
  //   }
  //   expect(readWords, equals(r.words));
  //   File(r.filename).deleteSync();
  // });
  // test('Model serializer and deserializer', () {
  //   var r = CommitFileUtils.serializeModel();
  //   var d = r.commitFile.deserializer(r.startIndex);
  //   var info = d.entryInfo as ModelInfo;
  //   var readUser = User.decode(info.modelType, info.modelVersion, d);
  //   expect(readUser.firstName, equals(r.user.firstName));
  //   expect(readUser.lastName, equals(r.user.lastName));
  //   expect(readUser.postalCode, equals(r.user.postalCode));
  //   expect(readUser.birthday, equals(r.user.birthday));
  //   File(r.filename).deleteSync();
  // });
  // test('Multiple models serializer and deserializer', () {
  //   var r = CommitFileUtils.serializeMultipleModels();
  //   r.startIndexes.shuffle();
  //   for (int startIndex in r.startIndexes) {
  //     var d = r.commitFile.deserializer(startIndex);
  //     var info = d.entryInfo as ModelInfo;
  //     var expectedUser = r.users[r.keys.indexOf(info.key)];
  //     var user = User.decode(info.modelType, info.modelVersion, d);
  //     expect(user.firstName, equals(expectedUser.firstName));
  //     expect(user.lastName, equals(expectedUser.lastName));
  //     expect(user.postalCode, equals(expectedUser.postalCode));
  //     expect(user.birthday, equals(expectedUser.birthday));
  //   }
  //   File(r.filename).deleteSync();
  // });
  // test('Remove serializer', () {
  //   var r = CommitFileUtils.serializeModel();
  //   int removeUserStartIndex = r.commitFile.removeSerializer(r.key).concludeWithStartIndex();
  //   var ud = r.commitFile.deserializer(r.startIndex);
  //   var rd = r.commitFile.deserializer(removeUserStartIndex);
  //   expect(r.key, equals(ud.entryInfo.key));
  //   expect(r.key, equals(rd.entryInfo.key));
  //   expect(ud.entryInfo.key, equals(rd.entryInfo.key));
  //   expect(rd.entryInfo, isInstanceOf<RemoveInfo>());
  //   File(r.filename).deleteSync();
  // });
  // test('Serialize empty index to empty commit file', () {
  //   var r = CommitFileUtils.serializeEmptyIndex();
  //   Index readIndex = _findLastIndex(r.commitFile);
  //   expect(readIndex, isNotNull);
  //   expect(r.index.length, equals(readIndex.length));
  //   File(r.filename).deleteSync();
  // });
  // test('Index serializer', () {
  //   var r = CommitFileUtils.serializeFullIndex();
  //   expect(r.index.length, greaterThan(0));
  //   Index readIndex = _findLastIndex(r.commitFile);
  //   expect(readIndex, isNotNull);
  //   expect(r.index.length, equals(readIndex.length));
  //   File(r.filename).deleteSync();
  // });
  // test('Multiple index serializers', () {
  //   var r1 = CommitFileUtils.serializeFullIndex();
  //   int length1 = r1.index.length;
  //   expect(length1, greaterThan(0));
  //   var r2 = CommitFileUtils.serializeFullIndex(r1.commitFile, r1.index);
  //   int length2 = r2.index.length;
  //   expect(length2, greaterThan(0));
  //   expect(length2, greaterThan(length1));
  //   Index readIndex = _findLastIndex(r2.commitFile);
  //   expect(readIndex, isNotNull);
  //   expect(readIndex.length, equals(length2));
  //   File(r2.filename).deleteSync();
  // });
  // test('Replay', () {
  //   var r = CommitFileUtils.serializeFullIndex();
  //   var readWordsForKeys = Map<String, String>();
  //   var readUsersForKeys = Map<String, User>();
  //   var readIndexes = List<Index>();
  //   for (LineDeserializer deserialize in r.commitFile.replay) {
  //     var info = deserialize.entryInfo;
  //     if (info is ValueInfo) {
  //       readWordsForKeys[info.key] = deserialize.string();
  //     } else if (info is ModelInfo) {
  //       readUsersForKeys[info.key] = User.decode(
  //         info.modelType, 
  //         info.modelVersion, 
  //         deserialize,
  //       );
  //     } else if (info is IndexInfo) {
  //       readIndexes.add(Index.decode(
  //         null, 
  //         info.modelVersion, 
  //         deserialize,
  //       ));
  //     }
  //   }
  //   expect(readWordsForKeys.length, greaterThan(0));
  //   expect(readUsersForKeys.length, greaterThan(0));
  //   expect(readIndexes.length, greaterThan(0));
  //   for (String originalWordKey in r.wordKeys) {
  //     var originalWord = r.words[r.wordKeys.indexOf(originalWordKey)];
  //     var readWord = readWordsForKeys[originalWordKey];
  //     expect(readWord, equals(originalWord));
  //   }
  //   for (String originalUserKey in r.userKeys) {
  //     var originalUser = r.users[r.userKeys.indexOf(originalUserKey)];
  //     var readUser = readUsersForKeys[originalUserKey];
  //     expect(readUser.firstName, equals(originalUser.firstName));
  //     expect(readUser.lastName, equals(originalUser.lastName));
  //     expect(readUser.postalCode, equals(originalUser.postalCode));
  //     expect(readUser.birthday, equals(originalUser.birthday));
  //   }
  //   File(r.filename).deleteSync();
  // });
  // test('Compaction', () {
  //   var filename = 'compaction_commit_file.scl';
  //   var c = CommitFile(filename);
  //   var idx = Index();
  //   var r = CommitFileUtils.serializeMultipleModels(c);
  //   for (int i = 0; i < r.keys.length; i++) {
  //     idx[r.keys[i]] = r.startIndexes[i];
  //   }
  //   var changedUsers = r.users.map<User>((User u) =>
  //     User(
  //       firstName: u.firstName.toUpperCase(),
  //       lastName: u.lastName.toUpperCase(),
  //       postalCode: u.postalCode,
  //       birthday: u.birthday,
  //     )
  //   ).toList();
  //   for (int i = 0; i < r.keys.length; i++) {
  //     var cu = changedUsers[i];
  //     var ke = r.keys[i];
  //     var s = c.modelSerializer(ke, cu.type, cu.version);
  //     cu.encode(s);
  //     int newStartIndex = s.concludeWithStartIndex();
  //     idx[ke] = newStartIndex;
  //     int oldStartIndex = r.startIndexes[i];
  //     expect(newStartIndex, greaterThan(oldStartIndex));
  //   }

  //   int sizeBeforeCompaction = File(filename).statSync().size;

  //   var newIdxForOldIdx = c.compaction(idx.startIndexes);
  //   idx.replaceStartIndexes(newIdxForOldIdx);

  //   int sizeAfterCompaction = File(filename).statSync().size;
  //   expect(sizeAfterCompaction, lessThan(sizeBeforeCompaction));

  //   for (int i = 0; i < r.keys.length; i++) {
  //     var expected = changedUsers[i];
  //     var startIndex = idx[r.keys[i]];
  //     var d = c.deserializer(startIndex);
  //     var mi = d.entryInfo as ModelInfo;
  //     var retrieved = User.decode(mi.modelType, mi.modelVersion, d);
  //     expect(retrieved.firstName, equals(expected.firstName));
  //     expect(retrieved.lastName, equals(expected.lastName));
  //     expect(retrieved.postalCode, equals(expected.postalCode));
  //     expect(retrieved.birthday, equals(expected.birthday));
  //   }

  //   File(filename).deleteSync();
  // });
}

// Index _findLastIndex(CommitFile commitFile) {
//   Index finding;
//   for (LineDeserializer deline in commitFile.indexTail) {
//     var entryInfo = deline.entryInfo;
//     if (entryInfo is IndexInfo) {
//       finding = Index.decode(null, entryInfo.modelVersion, deline);
//     }
//   }
//   return finding;
// }