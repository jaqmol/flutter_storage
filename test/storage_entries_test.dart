import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_storage/src/backend_entries.dart';
import 'package:flutter_storage/src/serialization.dart';
import 'package:flutter_storage/src/log_file.dart';
import 'dart:math';

void main() {
  var gen = Random.secure();

  test("Storage state entry", () {
    var expectedEntries = List<MapEntry<String, LogRange>>.generate(
      100,
      (int index) => MapEntry<String, LogRange>(
        'EntryKey$index',
        LogRange((index + 1) * 10, (index + 1) * 20),
      ),
    );
    var undos = UndoStack();
    var stateEntry = StorageStateEntry(
      indexEntries: expectedEntries,
      changesCount: gen.nextInt(100),
      undoStack: undos,
    );

    var encodedStateEntry = stateEntry.encode()();

    var decodedStateEntry = StorageStateEntry.decode(
      Deserializer(encodedStateEntry),
    );
    expect(decodedStateEntry.changesCount, equals(stateEntry.changesCount));
    
    var decodedEntries = decodedStateEntry.indexEntries.toList();
    for (int i = 0; i < expectedEntries.length; i++) {
      var expectedEntry = expectedEntries[i];
      var decodedEntry = decodedEntries[i];
      expect(decodedEntry.key, equals(expectedEntry.key));
      expect(decodedEntry.value.start, equals(expectedEntry.value.start));
      expect(decodedEntry.value.length, equals(expectedEntry.value.length));
    }
  });

  test("Change value entry", () {
    var expectedEntries = List<ChangeValueEntry>.generate(
      100,
      (int index) => ChangeValueEntry(
        key: 'Key_$index',
        encodedModel: 'Model_#$index',
      ),
    );

    var encodedEntries = expectedEntries
      .map((ChangeValueEntry entry) => entry.encode()())
      .toList();

    var decodedEntries = encodedEntries
      .map((String value) => ChangeValueEntry.decode(Deserializer(value)))
      .toList();
    
    for (int i = 0; i < expectedEntries.length; i++) {
      var expectedEntry = expectedEntries[i];
      var decodedEntry = decodedEntries[i];
      expect(decodedEntry.key, equals(expectedEntry.key));
      expect(decodedEntry.encodedModel, equals(expectedEntry.encodedModel));
    }
  });

  test("RemoveValueEntry", () {
    var expectedEntries = List<RemoveValueEntry>.generate(
      100,
      (int index) => RemoveValueEntry('Key_$index'),
    );

    var encodedEntries = expectedEntries
      .map((RemoveValueEntry entry) => entry.encode()())
      .toList();

    var decodedEntries = encodedEntries
      .map((String value) => RemoveValueEntry.decode(Deserializer(value)))
      .toList();
    
    for (int i = 0; i < expectedEntries.length; i++) {
      var expectedEntry = expectedEntries[i];
      var decodedEntry = decodedEntries[i];
      expect(decodedEntry.key, equals(expectedEntry.key));
    }
  });

  test("ChangesCountEntry", () {
    var expectedEntries = List<ChangesCountEntry>.generate(
      100,
      (_) => ChangesCountEntry(gen.nextInt(100)),
    );

    var encodedEntries = expectedEntries
      .map((ChangesCountEntry entry) => entry.encode()())
      .toList();

    var decodedEntries = encodedEntries
      .map((String value) => ChangesCountEntry.decode(Deserializer(value)))
      .toList();
    
    for (int i = 0; i < expectedEntries.length; i++) {
      var expectedEntry = expectedEntries[i];
      var decodedEntry = decodedEntries[i];
      expect(
        decodedEntry.changesCount,
        equals(expectedEntry.changesCount),
      );
    }
  });

  test('UndoRangeItem', () {
    var expectedItems = createUndoRangeItems(100, gen);
    var serialize = Serializer('${UndoRangeItem.type}-collection');
    var encodedItems = serialize.collection(
      expectedItems,
      (Serializer s, UndoRangeItem i) => i.encode(s),
    )();
    var deserialize = Deserializer(encodedItems);
    var decodedItems = deserialize
      .collection<UndoRangeItem>(UndoRangeItem.decodeItem);
    expect(decodedItems.length, equals(expectedItems.length));
    for (int i = 0; i < expectedItems.length; i++) {
      compareUndoRangeItems(expectedItems[i], decodedItems[i]);
    }
  });

  test('UndoGroup', () {
    var expectedGroup = UndoGroup(createUndoRangeItems(100, gen));
    var encodedGroup = expectedGroup.encode()();
    var deserialize = Deserializer(encodedGroup);
    var decodedGroup = UndoGroup.decodeGroup(deserialize);
    expect(decodedGroup.length, equals(expectedGroup.length));
    compareUndoGroups(expectedGroup, decodedGroup);
  });

  test('UndoStack', () {
    var expectedGroups = List<UndoGroup>.generate(20, (_) {
      return UndoGroup(createUndoRangeItems(20, gen));
    });
    var expectedStack = UndoStack(expectedGroups);
    var encodedStack = expectedStack.encode()();
    var decodedStack = UndoStack.decode(Deserializer(encodedStack));
    UndoGroup poppedExpected = expectedStack.pop();
    int counter = 0;
    while (poppedExpected != null) {
      counter++;
      UndoGroup poppedDecoded = decodedStack.pop();
      compareUndoGroups(poppedExpected, poppedDecoded);
      poppedExpected = expectedStack.pop();
    }
    expect(counter, equals(20));
  });
}

List<UndoRangeItem> createUndoRangeItems(int amount, Random gen) {
  var undoTypes = <int>[UndoRangeItem.typeChange, UndoRangeItem.typeRemove];
  return List<UndoRangeItem>.generate(
    amount,
    (int index) => UndoRangeItem(
      undoTypes[gen.nextInt(undoTypes.length)],
      'UndoRangeItem_$index',
      LogRange(
        gen.nextInt(100),
        gen.nextInt(100),
      ),
    ),
  );
}

void compareUndoGroups(UndoGroup a, UndoGroup b) {
  for (int i = 0; i < a.length; i++) {
    compareUndoRangeItems(a[i], b[i]);
  }
}

void compareUndoRangeItems(UndoRangeItem a, UndoRangeItem b) {
  expect(a.undoType, equals(b.undoType));
  expect(a.key, equals(b.key));
  expect(a.range.start, equals(b.range.start));
  expect(a.range.length, equals(b.range.length));
}