// import 'package:flutter_storage/src/serialization.dart';
import 'package:flutter_storage/flutter_storage.dart';
// import 'package:flutter_storage/src/frontend_entries.dart';
import 'package:flutter_test/flutter_test.dart';
import 'dart:math';

// Run this example from parent directory flutter_storage like so:
// flutter test example/example.dart

void main() {
  var rand = Random.secure();

  test('Illustrate basic usage of flutter_storage', () {
    // The database is backed by one file:
    var storage = Storage('my-apps-database.scl');

    // Generate the houses in the street
    var houses = List<House>.generate(
      100, 
      (int index) => House(index + 1, rand.nextBool()),
    );

    // Create the street
    var street = Street('Cento Case Lane', houses);

    // Save the street to the database
    storage.setModel(street.name, street);

    // Retrieve the saved street
    var deserialize = storage.entry(street.name);
    var retrievedStreet = Street.decode(deserialize);
    print('retrievedStreet.name: ${retrievedStreet.name}');
    print('retrievedStreet.houses.length: ${retrievedStreet.houses.length}');

    // Iterate all the entries
    for (Deserializer deserialize in storage.values) {
      // A database can contain all kinds of entries,
      // thus a type-check is necessary:
      var info = deserialize.entryInfo as ModelInfo;
      if (info.modelType == Street.staticType) {
        var streetEntry = Street.decode(deserialize);
        print('streetEntry.name: ${streetEntry.name}');
        print('streetEntry.houses.length: ${streetEntry.houses.length}');
      }
    }
  });
}

class Street implements Model {
  // Each model needs to have static [type] field
  // to identify it's type before decoding:
  static final String staticType = 'street';
  final String type = 'street';
  final int version = 0;
  final String name;
  final List<House> houses;

  Street(this.name, this.houses);

  // Models should encode themselves, the serialization-
  // field-order must be repeated during decode.
  // In case this model is contained in another one,
  // an optional serializer should be reused:
  Serializer encode(Serializer serialize) =>
    serialize
      .string(name)
      .list<House>(houses, (House h) => h.encode(serialize));

  // Models should decode themselves.
  // The serialization-field-order must be 
  // the same like during encode.
  Street.decode(Deserializer deserialize)
    : name = deserialize.string(),
      houses = deserialize.list<House>(() => House.decode(deserialize));
}

class House implements Model {
  // Each model needs to have static [type] field
  // to identify it's type before decoding:
  final String type = 'house';
  final int version = 0;
  final bool singleStory;
  final int number;

  House(this.number, this.singleStory);

  Serializer encode(Serializer serialize) =>
    serialize
      .integer(number)
      .boolean(singleStory);

  // This model is never serialized directl,
  // so collection support is sufficient:

  // static Serializer encodeHouse(
  //   House house,
  // ) => house.encode(serialize);

  static House decode(Deserializer deserialize) =>
    House(
      deserialize.integer(),
      deserialize.boolean(),
    );
}