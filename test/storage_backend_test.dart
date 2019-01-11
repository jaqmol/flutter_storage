import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_storage/src/storage_backend.dart';
import 'package:flutter_storage/src/serialization.dart';
import 'package:flutter_storage/src/frontend_entries.dart';
import 'dart:math';
import 'dart:io';
import 'test_models.dart';
import 'dart:collection';

void main() {
  var gen = Random.secure();

  test("StorageBackend Add", () {
    var path = './storage-test-file-add.scl';
    var expectedPeople = generatePeople(gen, 100);
    var expectedMeals = generateMeals(gen, 100);

    var storage = StorageBackend(path);

    storage.addEntries(expectedPeople);
    storage.addEntries(expectedMeals);

    checkCountOfModelType(storage, Person.type, expectedPeople.length);
    checkCountOfModelType(storage, Meal.type, expectedMeals.length);

    storage.flushStateAndClose();
    storage = StorageBackend(path);

    checkCountOfModelType(storage, Person.type, expectedPeople.length);
    checkCountOfModelType(storage, Meal.type, expectedMeals.length);
    
    checkRandomEntry<Person>(gen, storage, expectedPeople, checkPerson);
    checkRandomEntry<Meal>(gen, storage, expectedMeals, checkMeal);

    File(path).deleteSync();
  });

  test("StorageBackend Remove", () {
    var path = './storage-test-file-remove.scl';
    var expectedPeople = generatePeople(gen, 100);
    var expectedMeals = generateMeals(gen, 100);

    var storage = StorageBackend(path);

    storage.addEntries(expectedPeople);
    storage.addEntries(expectedMeals);

    var deletedMeals = removeRandomEntries<Meal>(gen, storage, expectedMeals, checkMealToRemove);
    checkCountOfModelType(storage, Person.type, expectedPeople.length);

    for (var deletedEntry in deletedMeals) {
      var deserialize = storage.value(deletedEntry.key);
      expect(deserialize, isNull);
    }

    storage.flushStateAndClose();
    storage = StorageBackend(path);

    checkCountOfModelType(storage, Person.type, expectedPeople.length);
    checkCountOfModelType(storage, Meal.type, expectedMeals.length - deletedMeals.length);

    for (var deletedEntry in deletedMeals) {
      var deserialize = storage.value(deletedEntry.key);
      expect(deserialize, isNull);
    }

    File(path).deleteSync();
  });

  test("StorageBackend Compaction", () {
    var path = './storage-test-file-compaction.scl';
    var expectedPeople = generatePeople(gen, 100);
    var expectedMeals = generateMeals(gen, 100);

    var storage = StorageBackend(path);

    storage.addEntries(expectedPeople);
    storage.addEntries(expectedMeals);

    storage.flushState();
    int uncompactedLength = File(path).lengthSync();

    var removedPeople = HashMap<String, Person>.fromEntries(
      removeRandomEntries<Person>(gen, storage, expectedPeople, checkPersonToRemove)
        .map<MapEntry<String, Person>>((StorageEncodeEntry<Person> pe) => MapEntry<String, Person>(pe.key, pe.value))
    );
    var removedMeals = HashMap<String, Meal>.fromEntries(
      removeRandomEntries<Meal>(gen, storage, expectedMeals, checkMealToRemove)
        .map<MapEntry<String, Meal>>((StorageEncodeEntry<Meal> pe) => MapEntry<String, Meal>(pe.key, pe.value))
    );

    expect(storage.staleRatio, greaterThan(0.0));
    storage.compaction();

    int compactedLength = File(path).lengthSync();
    expect(uncompactedLength, greaterThan(compactedLength));

    var remainingPeople = expectedPeople.where((StorageEncodeEntry<Person> pe) {
      return !removedPeople.containsKey(pe.key);
    });
    var remainingMeals = expectedMeals.where((StorageEncodeEntry<Meal> me) {
      return !removedMeals.containsKey(me.key);
    });

    for (StorageEncodeEntry<Person> pe in remainingPeople) {
      Deserializer deserialize = storage.value(pe.key);
      checkPerson(pe.value, deserialize);
    }
    for (StorageEncodeEntry<Meal> pe in remainingMeals) {
      Deserializer deserialize = storage.value(pe.key);
      checkMeal(pe.value, deserialize);
    }
    
    File(path).deleteSync();
  });

  test("StorageBackend Undo", () {
    var path = './storage-test-file-undo.scl';
    var expectedPeople = generatePeople(gen, 100);
    var expectedMeals = generateMeals(gen, 100);

    var storage = StorageBackend(path);

    storage.addEntries(expectedPeople);
    storage.addEntries(expectedMeals);

    storage.flushState();
    int originalMealsCount = countOfModelType(storage, Meal.type);

    storage.openUndoGroup();
    removeRandomEntries<Meal>(gen, storage, expectedMeals, checkMealToRemove);
    storage.closeUndoGroup();

    int mealsCountAfterRemove = countOfModelType(storage, Meal.type);
    expect(originalMealsCount, greaterThan(mealsCountAfterRemove));

    storage.undo();

    int mealsCountAfterUndo = countOfModelType(storage, Meal.type);
    expect(mealsCountAfterUndo, equals(originalMealsCount));
    expect(mealsCountAfterUndo, greaterThan(mealsCountAfterRemove));

    checkRandomEntry<Meal>(gen, storage, expectedMeals, checkMeal);
    
    File(path).deleteSync();
  });
}

void checkRandomEntry<T extends Model>(
  Random gen,
  StorageBackend storage,
  List<StorageEncodeEntry<T>> expectedEntries,
  void checker(T expectedEntry, Deserializer deserialize),
) {
  var indexes = List<int>.generate(expectedEntries.length, (int i) => i);
  for (int i = 0; i < 50; i++) {
    var idx = indexes[gen.nextInt(indexes.length)];
    var expectedEntry = expectedEntries[idx];
    var expectedEntryValue = expectedEntry.value;
    var deserializeEntry = storage.value(expectedEntry.key);
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

List<StorageEncodeEntry<T>> removeRandomEntries<T extends Model>(
  Random gen,
  StorageBackend storage,
  List<StorageEncodeEntry<T>> expectedEntries,
  T checker(T expectedEntry, Deserializer deserialize),
) {
  var indexes = List<int>.generate(expectedEntries.length, (int i) => i);
  var deletedEntries = List<StorageEncodeEntry<T>>();
  for (int i = 0; i < 50; i++) {
    var idx = indexes.removeAt(gen.nextInt(indexes.length));
    var expectedEntry = expectedEntries[idx];
    var deserialize = storage.remove(expectedEntry.key);
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
Person checkPersonToRemove(Person expectedPerson, Deserializer deserialize) {
  expect(deserialize.meta.type, equals(Person.type));
  var removedPerson = Person.decode(deserialize);
  expect(expectedPerson.name.first, equals(removedPerson.name.first));
  expect(expectedPerson.name.last, equals(removedPerson.name.last));
  expect(expectedPerson.birthday, equals(removedPerson.birthday));
  return removedPerson;
}

void checkCountOfModelType(StorageBackend storage, String type, int expectedCount) {
  expect(countOfModelType(storage, type), equals(expectedCount));
}

int countOfModelType(StorageBackend storage, String type) {
  int count = 0;
  for (StorageDecodeEntry entry in storage.entries) {
    if (entry.value.meta.type == type) count++;
  }
  return count;
}



