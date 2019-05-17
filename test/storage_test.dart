import 'package:flutter_test/flutter_test.dart';
import '../lib/src/storage.dart';
import '../lib/src/serialization/deserializer.dart';
import '../lib/src/serialization/model.dart';
import '../lib/src/serialization/entry_info.dart';
import 'dart:math';
import 'dart:io';
import 'storage_test_utils.dart';
import 'dart:collection';
import 'package:path/path.dart' as path;

void main() {
  var tmp = Directory.systemTemp.path;
  print('Temporary directory: $tmp');

  var gen = Random.secure();

  test("Storage Compaction", () async {
    var filename = path.join(tmp, 'storage_compaction_test.scl');
    var expectedPeopleMEs = generatePeople(gen, 100);
    var expectedPeople = Map<String, Person>.fromEntries(expectedPeopleMEs);
    var expectedMealsMEs = generateMeals(gen, 100);
    var expectedMeals = Map<String, Meal>.fromEntries(expectedMealsMEs);

    var storage = await Storage.open(filename);

    await addEntries(storage, expectedPeopleMEs);
    await addEntries(storage, expectedMealsMEs);

    await storage.flush();
    int uncompactedLength = File(filename).lengthSync();

    storage = await Storage.open(filename);

    var removedPeopleMEs = await removeRandomEntries<Person>(gen, storage, expectedPeopleMEs, deserializePerson, checkPersonToRemove);
    var removedPeople = Map<String, Person>.fromEntries(removedPeopleMEs);
    var removedMealsMEs = await removeRandomEntries<Meal>(gen, storage, expectedMealsMEs, deserializeMeal, checkMealToRemove);
    var removedMeals = HashMap<String, Meal>.fromEntries(removedMealsMEs);

    expect(removedPeople.length, lessThan(expectedPeopleMEs.length));
    expect(removedMeals.length, lessThan(expectedMealsMEs.length));

    expect(storage.needsCompaction, isTrue);
    await storage.compaction();

    int compactedLength = File(filename).lengthSync();

    expect(uncompactedLength, greaterThan(compactedLength));

    storage = await Storage.open(filename);

    for (String personKey in expectedPeople.keys) {
      var d = await storage.deserializer(personKey);
      if (removedPeople.containsKey(personKey)) {
        expect(d, isNull);
      } else {
        expect(d, isNotNull);
      }
    }
    for (String mealKey in expectedMeals.keys) {
      var d = await storage.deserializer(mealKey);
      if (removedMeals.containsKey(mealKey)) {
        expect(d, isNull);
      } else {
        expect(d, isNotNull);
      }
    }

    await File(filename).delete();
  });

  test("Storage Undo", () async {
    var filename = path.join(tmp, 'storage_undo_test.scl');
    var expectedMeals = generateMeals(gen, 100);

    var storage = await Storage.open(filename);
    await addEntries(storage, expectedMeals);
    int originalMealsCount = await countOfModelType(storage, Meal.staticType);

    var removedMeals = await removeRandomEntries<Meal>(
      gen, storage, expectedMeals, deserializeMeal, checkMealToRemove,
    );
    int mealsCountAfterRemove = await countOfModelType(storage, Meal.staticType);
    
    expect(originalMealsCount, greaterThan(mealsCountAfterRemove));
    expect(originalMealsCount, equals(mealsCountAfterRemove + removedMeals.length));

    removedMeals.forEach((_) => storage.undo());
    int mealsCountAfterUndo = await countOfModelType(storage, Meal.staticType);
    
    expect(mealsCountAfterUndo, equals(originalMealsCount));
    expect(mealsCountAfterUndo, greaterThan(mealsCountAfterRemove));
    checkRandomEntry<Meal>(gen, storage, expectedMeals, checkMeal);
    
    await File(filename).delete();
  });
}

Future<int> addEntries(Storage st, List<MapEntry<String, Model>> ntrs) async {
  int total = 0;
  for (MapEntry<String, Model> e in ntrs) {
    await st.putModel(e.key, e.value);
    total += 1;
  }
  return total;
}

void checkRandomEntry<T extends Model>(
  Random gen,
  Storage storage,
  List<MapEntry<String, T>> expectedEntries,
  void checker(T expectedEntry, Deserializer deserialize),
) async {
  var indexes = List<int>.generate(expectedEntries.length, (int i) => i);
  for (int i = 0; i < 50; i++) {
    var idx = indexes[gen.nextInt(indexes.length)];
    var expectedEntry = expectedEntries[idx];
    var expectedEntryValue = expectedEntry.value;
    var deserializeEntry = await storage.deserializer(expectedEntry.key);
    checker(expectedEntryValue, deserializeEntry);
  }
}
void checkPerson(Person expectedPerson, Deserializer deserialize) {
  expect(deserialize.entryInfo, isInstanceOf<ModelInfo>());
  expect((deserialize.entryInfo as ModelInfo).modelType, equals(Person.staticType));
  var receivedPerson = Person.decode(deserialize);
  expect(expectedPerson.name.first, equals(receivedPerson.name.first));
  expect(expectedPerson.name.last, equals(receivedPerson.name.last));
  expect(expectedPerson.birthday, equals(receivedPerson.birthday));
}
void checkMeal(Meal expectedMeal, Deserializer deserialize) {
  expect(deserialize.entryInfo, isInstanceOf<ModelInfo>());
  expect((deserialize.entryInfo as ModelInfo).modelType, equals(Meal.staticType));
  var receivedMeal = Meal.decode(deserialize);
  expect(expectedMeal.staple, equals(receivedMeal.staple));
  expect(expectedMeal.vegetable, equals(receivedMeal.vegetable));
  expect(expectedMeal.meat, equals(receivedMeal.meat));
  expect(expectedMeal.spice, equals(receivedMeal.spice));
}

Future<List<MapEntry<String, T>>> removeRandomEntries<T extends Model>(
  Random gen,
  Storage storage,
  List<MapEntry<String, T>> expectedEntries,
  T deserializeFn(Deserializer deserialize),
  void checkFn(T expectedEntry, T removedEntry),
) async {
  var indexes = List<int>.generate(expectedEntries.length, (int i) => i);
  var deleteEntries = List<MapEntry<String, T>>();
  for (int i = 0; i < 50; i++) {
    var idx = indexes.removeAt(gen.nextInt(indexes.length));
    var expectedEntry = expectedEntries[idx];
    var d = await storage.deserializer(expectedEntry.key);
    T deleteEntry = deserializeFn(d);
    deleteEntries.add(MapEntry<String, T>(expectedEntry.key, deleteEntry));
  }
  for (MapEntry<String, T> entry in deleteEntries) {
    bool didRemove = await storage.remove(entry.key);
    expect(didRemove, isTrue);
  }
  return deleteEntries;
}
Meal deserializeMeal(Deserializer deserialize) {
  expect(deserialize.entryInfo, isInstanceOf<ModelInfo>());
  expect((deserialize.entryInfo as ModelInfo).modelType, equals(Meal.staticType));
  return Meal.decode(deserialize);
}
void checkMealToRemove(Meal expectedMeal, Meal removedMeal) {
  expect(expectedMeal.staple, equals(removedMeal.staple));
  expect(expectedMeal.vegetable, equals(removedMeal.vegetable));
  expect(expectedMeal.meat, equals(removedMeal.meat));
  expect(expectedMeal.spice, equals(removedMeal.spice));
}
Person deserializePerson(Deserializer deserialize) {
  expect(deserialize.entryInfo, isInstanceOf<ModelInfo>());
  expect((deserialize.entryInfo as ModelInfo).modelType, equals(Person.staticType));
  return Person.decode(deserialize);
}
void checkPersonToRemove(Person expectedPerson, Person removedPerson) {
  expect(expectedPerson.name.first, equals(removedPerson.name.first));
  expect(expectedPerson.name.last, equals(removedPerson.name.last));
  expect(expectedPerson.birthday, equals(removedPerson.birthday));
}

Future<int> checkCountOfModelType(Storage st, String type, int expectedCount) async {
  int c = await countOfModelType(st, type);
  expect(c, equals(expectedCount));
  return c;
}

Future<int> countOfModelType(Storage st, String type) async {
  int modelTypeCount = 0;

  await for (Deserializer deserialize in st.values) {
    var info = deserialize.entryInfo;
    if (info is ModelInfo && info.modelType == type) {
      modelTypeCount++;
    }
  }

  return modelTypeCount;
}
