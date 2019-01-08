import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_storage/src/storage.dart';
import 'package:flutter_storage/src/serialization.dart';
import 'package:flutter_storage/src/frontend_entries.dart';
import 'test_models.dart';
import 'dart:math';
import 'dart:io';

void main() {
  var gen = Random.secure();

  test('Storage', () async {
    var path = './storage-test-file.scl';
    var storage = await Storage.open(path);
    var entry = randomPerson(gen);
    await storage.setValue(entry.key, entry.value);
    var deserialize = await storage.value(entry.key);
    checkPerson(entry.value, deserialize);
    File(path).deleteSync();
  });

  test("Storage Add", () async {
    var path = './storage-test-file-add.scl';
    var expectedPeople = generatePeople(gen, 100);
    var expectedMeals = generateMeals(gen, 100);

    var storage = await Storage.open(path);

    await storage.addEntries(expectedPeople);
    await storage.addEntries(expectedMeals);

    await checkCountOfModelType(storage, Person.type, expectedPeople.length);
    await checkCountOfModelType(storage, Meal.type, expectedMeals.length);

    await storage.close();
    storage = await Storage.open(path);

    await checkCountOfModelType(storage, Person.type, expectedPeople.length);
    await checkCountOfModelType(storage, Meal.type, expectedMeals.length);
    
    await checkRandomEntry<Person>(gen, storage, expectedPeople, checkPerson);
    await checkRandomEntry<Meal>(gen, storage, expectedMeals, checkMeal);

    File(path).deleteSync();
  });

  test("Storage Remove", () async {
    var path = './storage-test-file-remove.scl';
    var expectedPeople = generatePeople(gen, 100);
    var expectedMeals = generateMeals(gen, 100);

    var storage = await Storage.open(path);

    await storage.addEntries(expectedPeople);
    await storage.addEntries(expectedMeals);

    var deletedMeals = await removeRandomEntries<Meal>(gen, storage, expectedMeals, checkMealToRemove);
    await checkCountOfModelType(storage, Person.type, expectedPeople.length);

    for (var deletedEntry in deletedMeals) {
      Deserializer deserialize = await storage.value(deletedEntry.key);
      expect(deserialize, isNull);
    }

    await storage.close();
    storage = await Storage.open(path);

    await checkCountOfModelType(storage, Person.type, expectedPeople.length);
    await checkCountOfModelType(storage, Meal.type, expectedMeals.length - deletedMeals.length);

    for (var deletedEntry in deletedMeals) {
      Deserializer deserialize = await storage.value(deletedEntry.key);
      expect(deserialize, isNull);
    }

    File(path).deleteSync();
  });

  test("Storage Compaction", () async {
    var path = './storage-test-file-compaction.scl';
    var expectedPeople = generatePeople(gen, 100);
    var expectedMeals = generateMeals(gen, 100);

    var storage = await Storage.open(path);

    await storage.addEntries(expectedPeople);
    await storage.addEntries(expectedMeals);

    await storage.flushState();
    int uncompactedLength = File(path).lengthSync();

    await removeRandomEntries<Meal>(gen, storage, expectedMeals, checkMealToRemove);
    
    expect(await storage.staleRatio, greaterThan(0.0));
    await storage.compaction();

    int compactedLength = File(path).lengthSync();

    expect(uncompactedLength, greaterThan(compactedLength));
    File(path).deleteSync();
  });

  test("Storage Undo", () async {
    var path = './storage-test-file-undo.scl';
    var expectedPeople = generatePeople(gen, 100);
    var expectedMeals = generateMeals(gen, 100);

    var storage = await Storage.open(path);

    await storage.addEntries(expectedPeople);
    await storage.addEntries(expectedMeals);

    await storage.flushState();
    int originalMealsCount = await countOfModelType(storage, Meal.type);

    await storage.openUndoGroup();
    await removeRandomEntries<Meal>(gen, storage, expectedMeals, checkMealToRemove);
    await storage.closeUndoGroup();

    int mealsCountAfterRemove = await countOfModelType(storage, Meal.type);
    expect(originalMealsCount, greaterThan(mealsCountAfterRemove));

    List<UndoAction> actions = await storage.undo();

    for (UndoAction a in actions) {
      expect(a.key, isNotNull);
      expect(a.value, isNotNull);
      expect(a.type, isNotNull);
    }

    int mealsCountAfterUndo = await countOfModelType(storage, Meal.type);
    expect(mealsCountAfterUndo, equals(originalMealsCount));
    expect(mealsCountAfterUndo, greaterThan(mealsCountAfterRemove));

    await checkRandomEntry<Meal>(gen, storage, expectedMeals, checkMeal);
    
    File(path).deleteSync();
  });
}

Future<void> checkRandomEntry<T extends Model>(
  Random gen,
  Storage storage,
  List<StorageEncodeEntry<T>> expectedEntries,
  void checker(T expectedEntry, Deserializer deserialize),
) async {
  var indexes = List<int>.generate(expectedEntries.length, (int i) => i);
  for (int i = 0; i < 50; i++) {
    var idx = indexes[gen.nextInt(indexes.length)];
    var expectedEntry = expectedEntries[idx];
    var expectedEntryValue = expectedEntry.value;
    var deserializeEntry = await storage.value(expectedEntry.key);
    checker(expectedEntryValue, deserializeEntry);
  }
}

void checkPerson(Person expectedPerson, Deserializer deserialize) {
  expect(deserialize.meta.type, equals(Person.type));
  var receivedPerson = Person.decode(deserialize);
  expect(expectedPerson.name.first, equals(receivedPerson.name.first));
  expect(expectedPerson.name.last, equals(receivedPerson.name.last));
  expect(expectedPerson.birthday, equals(receivedPerson.birthday));
}
void checkMeal(Meal expectedMeal, Deserializer deserialize) {
  expect(deserialize.meta.type, equals(Meal.type));
  var receivedMeal = Meal.decode(deserialize);
  expect(expectedMeal.staple, equals(receivedMeal.staple));
  expect(expectedMeal.vegetable, equals(receivedMeal.vegetable));
  expect(expectedMeal.meat, equals(receivedMeal.meat));
  expect(expectedMeal.spice, equals(receivedMeal.spice));
}

Future<void> checkCountOfModelType(Storage storage, String type, int expectedCount) async {
  var foundCount = await countOfModelType(storage, type);
  expect(foundCount, equals(expectedCount));
}

Future<int> countOfModelType(Storage storage, String type) async {
  int count = 0;
  await for (StorageDecodeEntry entry in storage.entries) {
    if (entry.value.meta.type == type) count++;
  }
  return count;
}

Future<List<StorageEncodeEntry<T>>> removeRandomEntries<T extends Model>(
  Random gen,
  Storage storage,
  List<StorageEncodeEntry<T>> expectedEntries,
  T checker(T expectedEntry, Deserializer deserialize),
) async {
  var indexes = List<int>.generate(expectedEntries.length, (int i) => i);
  var deletedEntries = List<StorageEncodeEntry<T>>();
  for (int i = 0; i < 50; i++) {
    var idx = indexes.removeAt(gen.nextInt(indexes.length));
    var expectedEntry = expectedEntries[idx];
    Deserializer deserialize = await storage.remove(expectedEntry.key);
    T removedItem = checker(expectedEntry.value, deserialize);
    deletedEntries.add(StorageEncodeEntry(expectedEntry.key, removedItem));
  }
  return deletedEntries;
}
Meal checkMealToRemove(Meal expectedMeal, Deserializer deserialize) {
  expect(deserialize.meta.type, equals(Meal.type));
  var removedMeal = Meal.decode(deserialize);
  expect(expectedMeal.staple, equals(removedMeal.staple));
  expect(expectedMeal.vegetable, equals(removedMeal.vegetable));
  expect(expectedMeal.meat, equals(removedMeal.meat));
  expect(expectedMeal.spice, equals(removedMeal.spice));
  return removedMeal;
}