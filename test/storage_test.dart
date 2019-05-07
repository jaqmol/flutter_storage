import 'package:flutter_test/flutter_test.dart';
import '../lib/src/storage.dart';
import '../lib/src/serialization/deserializer.dart';
import '../lib/src/serialization/model.dart';
import '../lib/src/serialization/entry_info.dart';
import '../lib/src/operators/writer.dart';
import '../lib/src/operators/reader.dart';
import '../lib/src/operators/controller.dart';
import 'dart:math';
import 'dart:io';
import 'storage_test_utils.dart';
import 'dart:collection';

void main() {
  var gen = Random.secure();

  test("Storage Add", () async {
    var filename = './storage-test-file-add.scl';
    var expectedPeople = generatePeople(gen, 100);
    var expectedMeals = generateMeals(gen, 100);

    var strg1 = Storage(filename);
    int total = await strg1.write<int>((Writer writer) async {
      int c = addEntries(writer, expectedPeople);
      c += addEntries(writer, expectedMeals);
      return c;
    });
    expect(total, equals(expectedPeople.length + expectedMeals.length));

    total = await strg1.read<int>((Reader reader) async {
      int c = checkCountOfModelType(reader, Person.staticType, expectedPeople.length);
      c += checkCountOfModelType(reader, Meal.staticType, expectedMeals.length);
      return c;
    });
    expect(total, equals(expectedPeople.length + expectedMeals.length));

    await strg1.control((Controller c) async => c.close());
    
    var strg2 = Storage(filename);

    total = await strg2.read<int>((Reader reader) async {
      int c = checkCountOfModelType(reader, Person.staticType, expectedPeople.length);
      c += checkCountOfModelType(reader, Meal.staticType, expectedMeals.length);
      return c;
    });
    expect(total, equals(expectedPeople.length + expectedMeals.length));

    File(filename).deleteSync();
  });

  test("Storage Remove", () async {
    var filename = './storage-test-file-remove.scl';
    var expectedPeople = generatePeople(gen, 100);
    var expectedMeals = generateMeals(gen, 100);
    int totalEntryCount = expectedPeople.length + expectedMeals.length;

    var storage = Storage(filename);

    await storage.write((Writer writer) {
      addEntries(writer, expectedPeople);
      addEntries(writer, expectedMeals);
    });

    await storage.read((Reader reader) {
      checkCountOfModelType(reader, Person.staticType, expectedPeople.length);
      checkCountOfModelType(reader, Meal.staticType, expectedMeals.length);
      expect(reader.keys.length, equals(totalEntryCount));
      expect(reader.values.length, equals(totalEntryCount));
    });

    var deletedMeals = await removeRandomEntries<Meal>(gen, storage, expectedMeals, deserializeMeal, checkMealToRemove);
    int totalLeftoverCount = totalEntryCount - deletedMeals.length;
    
    await storage.read((Reader reader) {
      for (var deletedEntry in deletedMeals) {
        var deserialize = reader.getEntry(deletedEntry.key);
        expect(deserialize, isNull);
      }
    });

    await storage.control((Controller c) async => c.close());

    storage = Storage(filename);

    await storage.read((Reader reader) {
      expect(reader.keys.length, equals(totalLeftoverCount));
      expect(reader.values.length, equals(totalLeftoverCount));

      for (var deletedEntry in deletedMeals) {
        var deserialize = reader.getEntry(deletedEntry.key);
        expect(deserialize, isNull);
      }
    });

    File(filename).deleteSync();
  });

  test("Storage Compaction", () async {
    var path = './storage-test-file-compaction.scl';
    var expectedPeopleMEs = generatePeople(gen, 100);
    var expectedPeople = Map<String, Person>.fromEntries(expectedPeopleMEs);
    var expectedMealsMEs = generateMeals(gen, 100);
    var expectedMeals = Map<String, Meal>.fromEntries(expectedMealsMEs);

    var storage = Storage(path);

    await storage.write((Writer w) {
      addEntries(w, expectedPeopleMEs);
      addEntries(w, expectedMealsMEs);
    });

    await storage.control((Controller c) async => c.close());
    int uncompactedLength = File(path).lengthSync();

    storage = Storage(path);

    var removedPeopleMEs = await removeRandomEntries<Person>(gen, storage, expectedPeopleMEs, deserializePerson, checkPersonToRemove);
    var removedPeople = Map<String, Person>.fromEntries(removedPeopleMEs);
    var removedMealsMEs = await removeRandomEntries<Meal>(gen, storage, expectedMealsMEs, deserializeMeal, checkMealToRemove);
    var removedMeals = HashMap<String, Meal>.fromEntries(removedMealsMEs);

    expect(removedPeople.length, lessThan(expectedPeopleMEs.length));
    expect(removedMeals.length, lessThan(expectedMealsMEs.length));

    await storage.control((Controller controller) {
      expect(controller.needsCompaction, isTrue);
      controller.compaction();
      controller.close();
    });
    int compactedLength = File(path).lengthSync();

    expect(uncompactedLength, greaterThan(compactedLength));

    storage = Storage(path);

    await storage.read((Reader r) async {
      for (String personKey in expectedPeople.keys) {
        if (removedPeople.containsKey(personKey)) {
          expect(r.getEntry(personKey), isNull);
        } else {
          expect(r.getEntry(personKey), isNotNull);
        }
      }
      for (String mealKey in expectedMeals.keys) {
        if (removedMeals.containsKey(mealKey)) {
          expect(r.getEntry(mealKey), isNull);
        } else {
          expect(r.getEntry(mealKey), isNotNull);
        }
      }
    });

    File(path).deleteSync();
  });

  // test("Storage Undo", () async {
  //   var path = './storage-test-file-undo.scl';
  //   var expectedPeople = generatePeople(gen, 100);
  //   var expectedMeals = generateMeals(gen, 100);

  //   var storage = Storage(path);

  //   storage.write((Writer w) {
  //     addEntries(w, expectedPeople);
  //     addEntries(w, expectedMeals);
  //   });

  //   int originalMealsCount = await storage.read<int>(
  //     (Reader r) async => countOfModelType(r, Meal.staticType)
  //   );

  //   var removedEntries = await removeRandomEntries<Meal>(
  //     gen, storage, expectedMeals, deserializeMeal, checkMealToRemove,
  //   );

  //   int mealsCountAfterRemove = await storage.read<int>(
  //     (Reader r) async => countOfModelType(r, Meal.staticType)
  //   );
  //   expect(originalMealsCount, greaterThan(mealsCountAfterRemove));

  //   storage.write((Writer w) {
  //     removedEntries.forEach((_) => w.undo());
  //   });

  //   int mealsCountAfterUndo = await storage.read<int>(
  //     (Reader r) async => countOfModelType(r, Meal.staticType)
  //   );
  //   expect(mealsCountAfterUndo, equals(originalMealsCount));
  //   expect(mealsCountAfterUndo, greaterThan(mealsCountAfterRemove));

  //   await storage.read((Reader r) async =>
  //     checkRandomEntry<Meal>(gen, r, expectedMeals, checkMeal)
  //   );
    
  //   File(path).deleteSync();
  // });
}

int addEntries(Writer op, List<MapEntry<String, Model>> ntrs) {
  int total = 0;
  for (MapEntry<String, Model> e in ntrs) {
    op.putModel(e.key, e.value);
    total += 1;
  }
  return total;
}

void checkRandomEntry<T extends Model>(
  Random gen,
  Reader reader,
  List<MapEntry<String, T>> expectedEntries,
  void checker(T expectedEntry, Deserializer deserialize),
) {
  var indexes = List<int>.generate(expectedEntries.length, (int i) => i);
  for (int i = 0; i < 50; i++) {
    var idx = indexes[gen.nextInt(indexes.length)];
    var expectedEntry = expectedEntries[idx];
    var expectedEntryValue = expectedEntry.value;
    var deserializeEntry = reader.getEntry(expectedEntry.key);
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
  var deleteEntries = await storage.read<List<MapEntry<String, T>>>((Reader r) async {
    var indexes = List<int>.generate(expectedEntries.length, (int i) => i);
    var acc = List<MapEntry<String, T>>();
    for (int i = 0; i < 50; i++) {
      var idx = indexes.removeAt(gen.nextInt(indexes.length));
      var expectedEntry = expectedEntries[idx];
      T deleteEntry = deserializeFn(r.getEntry(expectedEntry.key));
      acc.add(MapEntry<String, T>(expectedEntry.key, deleteEntry));
    }
    return acc;
  });
  await storage.write((Writer w) {
    for (MapEntry<String, T> entry in deleteEntries) {
      w.remove(entry.key);
    }
  });
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

int checkCountOfModelType(Reader op, String type, int expectedCount) {
  int c = countOfModelType(op, type);
  expect(c, equals(expectedCount));
  return c;
}

int countOfModelType(Reader op, String type) {
  int count = 0;
  for (Deserializer deserialize in op.values) {
    var info = deserialize.entryInfo;
    if (info is ModelInfo && info.modelType == type) {
      count++;
    }
  }
  return count;
}



