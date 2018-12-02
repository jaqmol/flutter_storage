import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_storage/storage_backend.dart';
import 'package:flutter_storage/serialization.dart';
import 'package:flutter_storage/identifier.dart';
import 'dart:math';
import 'dart:io';

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
      var deserialize = storage[deletedEntry.key];
      expect(deserialize, isNull);
    }

    storage.flushStateAndClose();
    storage = StorageBackend(path);

    checkCountOfModelType(storage, Person.type, expectedPeople.length);
    checkCountOfModelType(storage, Meal.type, expectedMeals.length - deletedMeals.length);

    for (var deletedEntry in deletedMeals) {
      var deserialize = storage[deletedEntry.key];
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

    removeRandomEntries<Meal>(gen, storage, expectedMeals, checkMealToRemove);
    
    expect(storage.staleRatio, greaterThan(0.0));
    storage.compaction();

    int compactedLength = File(path).lengthSync();

    expect(uncompactedLength, greaterThan(compactedLength));
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
  List<StorageBackendEncodeEntry<T>> expectedEntries,
  void checker(T expectedEntry, Deserializer deserialize),
) {
  var indexes = List<int>.generate(expectedEntries.length, (int i) => i);
  for (int i = 0; i < 50; i++) {
    var idx = indexes[gen.nextInt(indexes.length)];
    var expectedEntry = expectedEntries[idx];
    var expectedEntryValue = expectedEntry.value;
    var deserializeEntry = storage[expectedEntry.key];
    checker(expectedEntryValue, deserializeEntry);
  }
}
void checkPerson(Person expectedPerson, Deserializer deserialize) {
  expect(deserialize.meta.type, equals(Person.type));
  var receivedPerson = Person.decode(deserialize);
  expect(expectedPerson.name.first, equals(receivedPerson.name.first));
  expect(expectedPerson.name.last, equals(receivedPerson.name.last));
  expect(expectedPerson.gender, equals(receivedPerson.gender));
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

List<StorageBackendEncodeEntry<T>> removeRandomEntries<T extends Model>(
  Random gen,
  StorageBackend storage,
  List<StorageBackendEncodeEntry<T>> expectedEntries,
  T checker(T expectedEntry, Deserializer deserialize),
) {
  var indexes = List<int>.generate(expectedEntries.length, (int i) => i);
  var deletedEntries = List<StorageBackendEncodeEntry<T>>();
  for (int i = 0; i < 50; i++) {
    var idx = indexes.removeAt(gen.nextInt(indexes.length));
    var expectedEntry = expectedEntries[idx];
    var deserialize = storage.remove(expectedEntry.key);
    T removedItem = checker(expectedEntry.value, deserialize);
    deletedEntries.add(StorageBackendEncodeEntry(expectedEntry.key, removedItem));
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

void checkCountOfModelType(StorageBackend storage, String type, int expectedCount) {
  expect(countOfModelType(storage, type), equals(expectedCount));
}

int countOfModelType(StorageBackend storage, String type) {
  int count = 0;
  for (StorageBackendDecodeEntry entry in storage.entries) {
    if (entry.value.meta.type == type) count++;
  }
  return count;
}

List<StorageBackendEncodeEntry<Person>> generatePeople(Random gen, int amount) {
  return List<StorageBackendEncodeEntry<Person>>.generate(
    amount,
    (_) => StorageBackendEncodeEntry(
      identifier(),
      Person(
        FullName(
          firstNames[gen.nextInt(firstNames.length)],
          lastNames[gen.nextInt(lastNames.length)],
        ),
        Gender.values[gen.nextInt(Gender.values.length)],
        randomDateTime(gen),
      ),
    ),
  );
}

DateTime  randomDateTime(Random gen) {
  return DateTime(
    1900 + gen.nextInt(101),
    1 + gen.nextInt(12),
    1 + gen.nextInt(30),
  );
}

class Person extends Model {
  static final String type = 'person';
  final FullName name;
  final Gender gender;
  final DateTime birthday;

  Person(this.name, this.gender, this.birthday);

  String toString() => '$name ${gender.toString()} ${birthday.toString()}';

  Person copyWith({
    FullName name,
    Gender gender,
    DateTime birthday,
    String favoritMealId,
  }) => Person(
    name ?? this.name,
    gender ?? this.gender,
    birthday ?? this.birthday,
  );

  Serializer encode([Serializer serialize]) =>
    (serialize ?? Serializer(type))
      .string(name.first)
      .string(name.last)
      .integer(gender.index)
      .string(birthday.toIso8601String());

  Person.decode(Deserializer deserialize)
    : name = FullName(
        deserialize.string(),
        deserialize.string(),
      ),
      gender = Gender.values[deserialize.integer()],
      birthday = DateTime.parse(deserialize.string());
}

class FullName {
  final String first;
  final String last;

  FullName(this.first, this.last);

  String toString() {
    return '$first $last';
  }
}

enum Gender {
  female,
  meta,
  male,
}

enum Staple {
  rice,
  potatoes,
  pasta,
  cereals,
}

enum Vegetable {
  cabbage,
  cauliflower,
  broccoli,
  savoy,
  radish,
  carrot,
  beetroot,
  beans,
  peas,
  eggplant,
  tomatoes,
  cucumber,
  pumpkin,
  spinach,
}

enum Meat {
  beef,
  goat,
  sheep,
  pork,
  fish,
  eggs,
}

enum Spice {
  garlic,
  peppers,
  onions,
}

class Meal extends Model {
  static final String type = 'meal';
  final Staple staple;
  final Vegetable vegetable;
  final Meat meat;
  final Spice spice;

  Meal(this.staple, this.vegetable, this.meat, this.spice);

  String toString() {
    return '${this.meat.toString()} with ${this.vegetable.toString()}, ${this.staple.toString()} and ${this.spice.toString()}';
  }

  Serializer encode([Serializer serialize]) =>
    (serialize ?? Serializer(type))
      .integer(staple.index)
      .integer(vegetable.index)
      .integer(meat.index)
      .integer(spice.index);

  Meal.decode(Deserializer deserialize)
    : staple = Staple.values[deserialize.integer()],
      vegetable = Vegetable.values[deserialize.integer()],
      meat = Meat.values[deserialize.integer()],
      spice = Spice.values[deserialize.integer()];
}

List<StorageBackendEncodeEntry<Meal>> generateMeals(Random gen, int amount) {
  return List<StorageBackendEncodeEntry<Meal>>.generate(amount, (_) => randomMeal(gen));
}


StorageBackendEncodeEntry<Meal> randomMeal(Random gen) {
  return StorageBackendEncodeEntry(
    identifier(),
    Meal(
      Staple.values[gen.nextInt(Staple.values.length)],
      Vegetable.values[gen.nextInt(Vegetable.values.length)],
      Meat.values[gen.nextInt(Meat.values.length)],
      Spice.values[gen.nextInt(Spice.values.length)],
    ),
  );
}

var firstNames = <String>[
  'Rylee',
  'Kadin',
  'Karson',
  'Donald',
  'Azaria',
  'Clayton',
  'Dixie',
  'Jan',
  'Valery',
  'Ashlynn',
  'Waylon',
  'Mollie',
  'Jade',
  'Liana',
  'Asa',
  'Piper',
  'Mariam',
  'Heath',
  'Marcus',
  'Davian',
  'Jayce',
  'Grayson',
  'Jaiden',
  'Rene',
  'Yair',
  'Julianne',
  'Emilee',
  'Sofia',
  'Jamarcus',
  'Ricardo',
  'Dominick',
  'Annabella',
  'Damaris',
  'Emilie',
  'Alaina',
  'Journey',
  'Sadie',
  'Izayah',
  'Samantha',
  'Ryder',
  'Sariah',
  'Kayla',
  'Mckayla',
  'Blaze',
  'Keith',
  'Holly',
  'Violet',
  'Cheyenne',
  'Johan',
  'Braxton',
  'Zane',
  'Jamir',
  'Kelvin',
  'Hana',
  'Anabella',
  'Hillary',
  'Jordyn',
  'Emerson',
  'Maddison',
  'Quentin',
  'Ann',
  'Glenn',
  'Payten',
  'Victor',
  'Gilbert',
  'Saniya',
  'Olive',
  'Elsa',
  'Trenton',
  'Cherish',
  'Ean',
  'Christopher',
  'Esmeralda',
  'Karlee',
  'Jordan',
  'Keshawn',
  'Bruno',
  'Emerson',
  'Abraham',
  'Bradyn',
  'Yaretzi',
  'Kash',
  'Nathanael',
  'Brody',
  'Braden',
  'Konner',
  'Kyan',
  'Gordon',
  'Eva',
  'Kaylin',
  'Dayana',
  'Alivia',
  'Izabella',
  'Kaydence',
  'Elaine',
  'Maggie',
  'Ansley',
  'Ryan',
  'Nathaly',
  'Jaidyn',
];

var lastNames = <String>[
  'Woodward',
  'Whitehead',
  'Alexander',
  'Leon',
  'Ochoa',
  'Gay',
  'Michael',
  'Frank',
  'Farrell',
  'Hale',
  'Valencia',
  'Mora',
  'Mcdonald',
  'Fritz',
  'Benton',
  'Nielsen',
  'Mitchell',
  'Newton',
  'Walton',
  'Davenport',
  'Munoz',
  'Pena',
  'Cameron',
  'Mccarthy',
  'Weber',
  'Holt',
  'Hobbs',
  'Bauer',
  'Tran',
  'Reilly',
  'Santiago',
  'Matthews',
  'Gomez',
  'Fletcher',
  'Francis',
  'Fernandez',
  'Rivas',
  'Summers',
  'Chen',
  'Caldwell',
  'Lyons',
  'Flynn',
  'Grimes',
  'Shields',
  'Simmons',
  'Liu',
  'Middleton',
  'Taylor',
  'Armstrong',
  'Hess',
  'Stokes',
  'Stephens',
  'Peters',
  'Rose',
  'Huang',
  'Richards',
  'Boone',
  'Bentley',
  'Strickland',
  'Welch',
  'Martin',
  'Combs',
  'Mcdaniel',
  'Williamson',
  'Wood',
  'Hanson',
  'Ewing',
  'Olsen',
  'Kline',
  'Kelley',
  'Orr',
  'Gibson',
  'Novak',
  'Boyer',
  'Downs',
  'Clay',
  'Turner',
  'Gross',
  'Wyatt',
  'Cantu',
  'Anthony',
  'Stout',
  'Logan',
  'Herrera',
  'Parker',
  'Booker',
  'Lee',
  'Duncan',
  'Love',
  'Odom',
  'Townsend',
  'Rojas',
  'Clements',
  'Garcia',
  'Kelly',
  'Herring',
  'Franco',
  'Murphy',
  'Werner',
  'Galvan',
];