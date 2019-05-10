import 'package:flutter_test/flutter_test.dart';
import 'dart:io';
import '../lib/src/commit_file.dart';
import '../lib/src/index.dart';
import '../lib/src/identifier.dart';
import '../lib/src/serialization/line_deserializer.dart';
import '../lib/src/serialization/entry_info_private.dart';
import 'dart:math';

void main() {
  test('Index encoding, decoding and simple modification', () {
    var filename = 'index_basic_test_file.scl';
    var cf = CommitFile(filename);
    var idx1 = Index();
    var rand = Random(DateTime.now().millisecondsSinceEpoch);
    var testData = _createTestData(rand, 100);

    testData.forEach((String key, int startIndex) {
      idx1[key] = startIndex;
    });

    var s = cf.indexSerializer(idx1.version);
    idx1.encode(s);
    s.concludeWithStartIndex();
    Index idx2 = _readIndex(cf);

    testData.forEach((String key, int startIndex) {
      expect(startIndex, equals(idx2[key]));
      expect(idx1[key], equals(idx2[key]));
    });

    var testDataModification1 = testData
      .map<String, int>((String key, int startIndex) =>
        MapEntry<String, int>(key, rand.nextInt(100))
      );

    testDataModification1.forEach((String key, int startIndex) {
      idx2[key] = startIndex;
    });

    s = cf.indexSerializer(idx2.version);
    idx2.encode(s);
    s.concludeWithStartIndex();
    Index idx3 = _readIndex(cf);

    testDataModification1.forEach((String key, int startIndex) {
      expect(startIndex, equals(idx3[key]));
      expect(idx2[key], equals(idx3[key]));
    });

    File(filename).deleteSync();
  });
  test('Index removing entries and undoing', () {
    var idx = Index();
    var rand = Random(DateTime.now().millisecondsSinceEpoch);
    var testData = _createTestData(rand, 100);
    testData.forEach((String key, int startIndex) {
      idx[key] = startIndex;
    });
    
    var keysToDelete = Set<String>();
    var allKeys = testData.keys.toList();
    while (keysToDelete.length < 10) {
      keysToDelete.add(allKeys[rand.nextInt(allKeys.length)]);
    }
    
    keysToDelete.forEach((String key) {
      idx.remove(key);
    });
    keysToDelete.forEach((String key) {
      expect(idx[key], equals(-1));
    });
    keysToDelete.forEach((String key) {
      idx.undo();
    });
    keysToDelete.forEach((String key) {
      expect(idx[key], equals(testData[key]));
    });
  });
  test('Index modifications and undoing ', () {
    var idx = Index();
    var rand = Random(DateTime.now().millisecondsSinceEpoch);
    var testData = _createTestData(rand, 100);
    testData.forEach((String key, int startIndex) {
      idx[key] = startIndex;
    });
    
    var keysToModify = Set<String>();
    var allKeys = testData.keys.toList();
    while (keysToModify.length < 10) {
      keysToModify.add(allKeys[rand.nextInt(allKeys.length)]);
    }

    var modifications = Map<String, int>.fromIterable(
      keysToModify,
      key: (key) => key as String,
      value: (_) => rand.nextInt(100),
    );

    modifications.forEach((String key, int startIndex) {
      idx[key] = startIndex;
    });

    testData.forEach((String key, int originalStartIndex) {
      int expectedStartIndex = modifications[key] ?? originalStartIndex;
      int currentStartIndex = idx[key];
      expect(currentStartIndex, equals(expectedStartIndex));
    });

    modifications.forEach((String key, int startIndex) {
      idx.undo();
    });

    testData.forEach((String key, int originalStartIndex) {
      int currentStartIndex = idx[key];
      expect(currentStartIndex, equals(originalStartIndex));
    });
  });
}

Map<String, int> _createTestData(Random rand, int length) => 
  Map<String, int>.fromEntries(
    List<MapEntry<String, int>>.generate(
      length,
      (int idx1) => MapEntry<String, int>(
        identifier(),
        rand.nextInt(100),
      ),
    ),
  );

Index _readIndex(CommitFile cf) {
  Index idx;
  var tail = Map<String, int>();
  for (LineDeserializer deserialize in cf.indexTail) {
    var entryInfo = deserialize.entryInfo;
    if (entryInfo is IndexInfo) {
      idx = Index.decode(null, entryInfo.modelVersion, deserialize);
    } else {
      tail[entryInfo.key] = deserialize.startIndex;
    }
  }
  return idx.updateIndex(tail);
}