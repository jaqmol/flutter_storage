import 'package:flutter_storage/src/serialization.dart';
import 'package:flutter_storage/src/storage_entries.dart';
import 'package:flutter_storage/src/identifier.dart';
import 'dart:math';

List<StorageEncodeEntry<Person>> generatePeople(Random gen, int amount) {
  return List<StorageEncodeEntry<Person>>.generate(amount, (_) => randomPerson(gen));
}

StorageEncodeEntry<Person> randomPerson(Random gen) {
  return StorageEncodeEntry(
    identifier(),
    Person(
      FullName(
        firstNames[gen.nextInt(firstNames.length)],
        lastNames[gen.nextInt(lastNames.length)],
      ),
      randomDateTime(gen),
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



List<StorageEncodeEntry<Meal>> generateMeals(Random gen, int amount) {
  return List<StorageEncodeEntry<Meal>>.generate(amount, (_) => randomMeal(gen));
}


StorageEncodeEntry<Meal> randomMeal(Random gen) {
  return StorageEncodeEntry(
    identifier(),
    Meal(
      Staple.values[gen.nextInt(Staple.values.length)],
      Vegetable.values[gen.nextInt(Vegetable.values.length)],
      Meat.values[gen.nextInt(Meat.values.length)],
      Spice.values[gen.nextInt(Spice.values.length)],
    ),
  );
}

class Person implements Model {
  static final String type = 'person';
  final FullName name;
  final DateTime birthday;

  Person(this.name, this.birthday);

  String toString() => '$name ${birthday.toString()}';

  Person copyWith({
    FullName name,
    DateTime birthday,
    String favoritMealId,
  }) => Person(
    name ?? this.name,
    birthday ?? this.birthday,
  );

  Serializer encode([Serializer serialize]) =>
    (serialize ?? Serializer(type))
      .string(name.first)
      .string(name.last)
      .string(birthday.toIso8601String());

  Person.decode(Deserializer deserialize)
    : name = FullName(
        deserialize.string(),
        deserialize.string(),
      ),
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