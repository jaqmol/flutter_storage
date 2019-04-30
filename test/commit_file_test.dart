import 'package:flutter_test/flutter_test.dart';
import 'line_serializer_utils.dart';
import '../lib/src/commit_file.dart';
import '../lib/src/identifier.dart';
import '../lib/src/model.dart';
import '../lib/src/serializer.dart';
import '../lib/src/deserializer.dart';
import '../lib/src/entry_info.dart';
import '../lib/src/entry_info_private.dart';
import '../lib/src/index.dart';
import '../lib/src/line_deserializer.dart';
import 'dart:io';
import 'package:meta/meta.dart';
import 'commit_file_utils.dart';

void main() {
  test('Value serializer and deserializer', () {
    var r = CommitFileUtils.serializeValue();
    var d = r.commitFile.deserializer(r.startIndex);
    expect(d.entryInfo.key, equals(r.key));
    var content = d.string();
    expect(content, equals(LineSerializerUtils.testText));
    File(r.filename).deleteSync();
  });
  test('Multiple values serializer and deserializer', () {
    var r = CommitFileUtils.serializeMultipleValues();
    var shuffledIndexes = List<int>();
    for (int i = 0; i < r.keys.length; i++) {
      shuffledIndexes.add(i);
    }
    shuffledIndexes.shuffle();
    var readWords = List<String>.filled(r.keys.length, null);
    for (int i in shuffledIndexes) {
      var d = r.commitFile.deserializer(r.startIndexes[i]);
      expect(d.entryInfo.key, equals(r.keys[i]));
      readWords[i] = d.string();
    }
    expect(readWords, equals(r.words));
    File(r.filename).deleteSync();
  });
  test('Model serializer and deserializer', () {
    var r = CommitFileUtils.serializeModel();
    var d = r.commitFile.deserializer(r.startIndex);
    var info = d.entryInfo as ModelInfo;
    var readUser = User.decode(info.modelType, info.modelVersion, d);
    expect(readUser.firstName, equals(r.user.firstName));
    expect(readUser.lastName, equals(r.user.lastName));
    expect(readUser.postalCode, equals(r.user.postalCode));
    expect(readUser.birthday, equals(r.user.birthday));
    File(r.filename).deleteSync();
  });
  test('Multiple models serializer and deserializer', () {
    var r = CommitFileUtils.serializeMultipleModels();
    r.startIndexes.shuffle();
    for (int startIndex in r.startIndexes) {
      var d = r.commitFile.deserializer(startIndex);
      var info = d.entryInfo as ModelInfo;
      var expectedUser = r.users[r.keys.indexOf(info.key)];
      var user = User.decode(info.modelType, info.modelVersion, d);
      expect(user.firstName, equals(expectedUser.firstName));
      expect(user.lastName, equals(expectedUser.lastName));
      expect(user.postalCode, equals(expectedUser.postalCode));
      expect(user.birthday, equals(expectedUser.birthday));
    }
    File(r.filename).deleteSync();
  });
  test('Remove serializer', () {
    var r = CommitFileUtils.serializeModel();
    var rs = r.commitFile.removeSerializer(r.key);
    int removeUserStartIndex = rs.conclude();
    var ud = r.commitFile.deserializer(r.startIndex);
    var rd = r.commitFile.deserializer(removeUserStartIndex);
    expect(r.key, equals(ud.entryInfo.key));
    expect(r.key, equals(rd.entryInfo.key));
    expect(ud.entryInfo.key, equals(rd.entryInfo.key));
    expect(rd.entryInfo, isInstanceOf<RemoveInfo>());
    File(r.filename).deleteSync();
  });
  test('Serialize empty index to empty commit file', () {
    var r = CommitFileUtils.serializeEmptyIndex();
    Index readIndex = _findLastIndex(r.commitFile);
    expect(readIndex, isNotNull);
    expect(r.index.length, equals(readIndex.length));
    File(r.filename).deleteSync();
  });
  test('Index serializer', () {
    var r = CommitFileUtils.serializeFullIndex();
    expect(r.index.length, greaterThan(0));
    Index readIndex = _findLastIndex(r.commitFile);
    expect(readIndex, isNotNull);
    expect(r.index.length, equals(readIndex.length));
    File(r.filename).deleteSync();
  });
  test('Multiple index serializers', () {
    var r1 = CommitFileUtils.serializeFullIndex();
    int length1 = r1.index.length;
    expect(length1, greaterThan(0));
    var r2 = CommitFileUtils.serializeFullIndex(r1.commitFile, r1.index);
    int length2 = r2.index.length;
    expect(length2, greaterThan(0));
    expect(length2, greaterThan(length1));
    Index readIndex = _findLastIndex(r2.commitFile);
    expect(readIndex, isNotNull);
    expect(readIndex.length, equals(length2));
    File(r2.filename).deleteSync();
  });
  test('Replay', () {
    var r = CommitFileUtils.serializeFullIndex();
    var readWordsForKeys = Map<String, String>();
    var readUsersForKeys = Map<String, User>();
    var readIndexes = List<Index>();
    for (LineDeserializer deserialize in r.commitFile.replay) {
      var info = deserialize.entryInfo;
      if (info is ValueInfo) {
        readWordsForKeys[info.key] = deserialize.string();
      } else if (info is ModelInfo) {
        readUsersForKeys[info.key] = User.decode(
          info.modelType, 
          info.modelVersion, 
          deserialize,
        );
      } else if (info is IndexInfo) {
        readIndexes.add(Index.decode(
          null, 
          info.modelVersion, 
          deserialize,
        ));
      }
    }
    expect(readWordsForKeys.length, greaterThan(0));
    expect(readUsersForKeys.length, greaterThan(0));
    expect(readIndexes.length, greaterThan(0));
    for (String originalWordKey in r.wordKeys) {
      var originalWord = r.words[r.wordKeys.indexOf(originalWordKey)];
      var readWord = readWordsForKeys[originalWordKey];
      expect(readWord, equals(originalWord));
    }
    for (String originalUserKey in r.userKeys) {
      var originalUser = r.users[r.userKeys.indexOf(originalUserKey)];
      var readUser = readUsersForKeys[originalUserKey];
      expect(readUser.firstName, equals(originalUser.firstName));
      expect(readUser.lastName, equals(originalUser.lastName));
      expect(readUser.postalCode, equals(originalUser.postalCode));
      expect(readUser.birthday, equals(originalUser.birthday));
    }
    File(r.filename).deleteSync();
  });
  test('Compaction', () {
    var filename = 'compaction_commit_file.scl';
    var c = CommitFile(filename);
    var idx = Index();
    var r = CommitFileUtils.serializeMultipleModels(c);
    for (int i = 0; i < r.keys.length; i++) {
      idx[r.keys[i]] = r.startIndexes[i];
    }
    var changedUsers = r.users.map<User>((User u) =>
      User(
        firstName: u.firstName.toUpperCase(),
        lastName: u.lastName.toUpperCase(),
        postalCode: u.postalCode,
        birthday: u.birthday,
      )
    ).toList();
    for (int i = 0; i < r.keys.length; i++) {
      var cu = changedUsers[i];
      var ke = r.keys[i];
      var s = c.modelSerializer(ke, cu.type, cu.version);
      cu.encode(s);
      int newStartIndex = s.conclude();
      idx[ke] = newStartIndex;
      int oldStartIndex = r.startIndexes[i];
      expect(newStartIndex, greaterThan(oldStartIndex));
    }

    int sizeBeforeCompaction = File(filename).statSync().size;

    var keepIndex = Map<String, int>();
    var newIdxForOldIdx = r.commitFile.compaction(
      map: (LineDeserializer deserialize) {
        var info = deserialize.entryInfo;
        if (info is ModelInfo || info is ValueInfo) {
          keepIndex[info.key] = deserialize.startIndex;
        } else if (info is RemoveInfo) {
          keepIndex.remove(info.key);
        }
      },
      reduce: () => keepIndex.values,
    );
    idx.replaceIndex(keepIndex.map<String, int>((String key, int oldIdx) {
      return MapEntry<String, int>(key, newIdxForOldIdx[oldIdx]);
    }));

    int sizeAfterCompaction = File(filename).statSync().size;
    expect(sizeAfterCompaction, lessThan(sizeBeforeCompaction));

    for (int i = 0; i < r.keys.length; i++) {
      var expected = changedUsers[i];
      var startIndex = idx[r.keys[i]];
      var d = c.deserializer(startIndex);
      var mi = d.entryInfo as ModelInfo;
      var retrieved = User.decode(mi.modelType, mi.modelVersion, d);
      expect(retrieved.firstName, equals(expected.firstName));
      expect(retrieved.lastName, equals(expected.lastName));
      expect(retrieved.postalCode, equals(expected.postalCode));
      expect(retrieved.birthday, equals(expected.birthday));
    }

    File(filename).deleteSync();
  });
}

Index _findLastIndex(CommitFile commitFile) {
  Index finding;
  for (LineDeserializer deline in commitFile.indexTail) {
    var entryInfo = deline.entryInfo;
    if (entryInfo is IndexInfo) {
      finding = Index.decode(null, entryInfo.modelVersion, deline);
    }
  }
  return finding;
}