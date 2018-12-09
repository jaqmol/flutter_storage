import 'package:flutter_storage/src/serialization.dart';
import 'package:flutter_storage/src/storage.dart';
import 'package:flutter_storage/src/storage_entries.dart';
import 'package:flutter_test/flutter_test.dart';
import 'dart:math';

// Run this example from parent directory flutter_storage like so:
// flutter test example/example.dart

void main() {
  var rand = Random.secure();

  test('Illustrate basic usage of flutter_storage', () async {
    // The database is backed by one file:
    var storage = await Storage.create('my-apps-database.scl');

    // Generate the houses in the street
    var houses = List<House>.generate(
      100, 
      (int index) => House(index + 1, rand.nextBool()),
    );

    // Create the street
    var street = Street('Cento Case Lane', houses);

    // Save the street to the database
    await storage.setValue(street.name, street);

    // Retrieve the saved street
    var deserialize = await storage.value(street.name);
    var retrievedStreet = Street.decode(deserialize);
    print('retrievedStreet.name: ${retrievedStreet.name}');
    print('retrievedStreet.houses.length: ${retrievedStreet.houses.length}');

    // Iterate all the entries
    await for (StorageDecodeEntry entry in storage.entries) {
      // A database can contain all kinds of entries,
      // thus a type-check is necessary:
      if (entry.value.meta.type == Street.type) {
        var streetEntry = Street.decode(entry.value);
        print('streetEntry.name: ${streetEntry.name}');
        print('streetEntry.houses.length: ${streetEntry.houses.length}');
      }
    }
  });
}

class Street implements Model {
  // Each model needs to have static [type] field
  // to identify it's type before decoding:
  static final String type = 'street';
  final String name;
  final List<House> houses;

  Street(this.name, this.houses);

  // Models should encode themselves, the serialization-
  // field-order must be repeated during decode.
  // In case this model is contained in another one,
  // an optional serializer should be reused:
  Serializer encode([Serializer serialize]) =>
    (serialize ?? Serializer(type))
      .string(name)
      .collection<House>(houses, House.encodeHouse);

  // Models should decode themselves.
  // The serialization-field-order must be 
  // the same like during encode.
  Street.decode(Deserializer deserialize)
    : name = deserialize.string(),
      houses = deserialize.collection<House>(House.decodeHouse);
}

class House implements Model {
  // Each model needs to have static [type] field
  // to identify it's type before decoding:
  static final String type = 'house';
  final bool singleStory;
  final int number;

  House(this.number, this.singleStory);

  Serializer encode([Serializer serialize]) => 
    (serialize ?? Serializer(type))
      .integer(number)
      .boolean(singleStory);

  // This model is never serialized directl,
  // so collection support is sufficient:

  static Serializer encodeHouse(
    Serializer serialize,
    House house,
  ) => house.encode(serialize);

  static House decodeHouse(Deserializer deserialize) =>
    House(
      deserialize.integer(),
      deserialize.boolean(),
    );
}