import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_storage/src/serialization.dart';
import 'dart:math';

void main() {
  test('Serializing a model', () {
    Employee david = Employee('David', 6.0);
    String encodedDavid = david.encode()();
    
    var des = Deserializer(encodedDavid);
    expect(des.meta.type, equals(Employee.type));

    Employee decoded = Employee.decode(des);
    expect(decoded.height, equals(david.height));
    expect(decoded.name, equals(david.name));
  });

  test('Serializing many models', () {
    Employee employee = Employee('David', 6.5);
    String encodedDavid = employee.encode()();

    House house = House(17, true);
    String encodedHouse = house.encode()();

    Bolt bolt = Bolt(BoltHead.flat, 21);
    String encodedBolt = bolt.encode()();
    
    Deserializer employeeDes = Deserializer(encodedDavid);
    expect(employeeDes.meta.type, equals(Employee.type));
    Employee decodedEmployee = Employee.decode(employeeDes);
    expect(decodedEmployee.height, equals(employee.height));
    expect(decodedEmployee.name, equals(employee.name));

    Deserializer houseDes = Deserializer(encodedHouse);
    expect(houseDes.meta.type, equals(House.type));
    House decodedHouse = House.decodeHouse(houseDes);
    expect(decodedHouse.singleStory, equals(house.singleStory));
    expect(decodedHouse.number, equals(house.number));

    Deserializer boltDes = Deserializer(encodedBolt);
    expect(boltDes.meta.type, equals(Bolt.type));
    Bolt decodedBolt = Bolt.decode(boltDes);
    expect(decodedBolt.diameter, equals(bolt.diameter));
    expect(decodedBolt.head, equals(bolt.head));
  });

  test('Serializing nested models', () {
    // Nesting pattern A
    OldCar car1 = OldCar(Engine(8), 6);
    String encodedCar1 = car1.encode()();
    print(encodedCar1);
    OldCar decodedCar1 = OldCar.decode(Deserializer(encodedCar1));
    expect(decodedCar1.engine.cylinders, equals(car1.engine.cylinders));
    expect(decodedCar1.seats, equals(car1.seats));

    // Nesting pattern B
    NewCar car2 = NewCar(Engine(16), 4);
    String encodedCar2 = car2.encode()();
    print(encodedCar2);
    NewCar decodedCar2 = NewCar.decode(Deserializer(encodedCar2));
    expect(decodedCar2.engine.cylinders, equals(car2.engine.cylinders));
    expect(decodedCar2.seats, equals(car2.seats));
  });

  test('Serializing collections', () {
    var rand = Random.secure();
    var street = Street(List<House>.generate(
      100, 
      (int index) => House(index + 1, rand.nextBool()),
    ));
    var encodedStreet = street.encode()();
    print(encodedStreet);
    var deserialize = Deserializer(encodedStreet);
    var decodedStree = Street.decode(deserialize);
    expect(decodedStree.houses.length, equals(street.houses.length));
    for (int i = 0; i < street.houses.length; i++) {
      var decodedHouse = decodedStree.houses[i];
      var house = street.houses[i];
      expect(decodedHouse.singleStory, equals(house.singleStory));
      expect(decodedHouse.number, equals(house.number));
    }
  });
}

class Employee implements Model {
  static final String type = 'employee';
  final double height;
  final String name;

  Employee(this.name, this.height) : super();

  Serializer encode([Serializer serialize]) =>
    (serialize ?? Serializer(type))
      .float(height)
      .string(name);

  Employee.decode(Deserializer deserialize)
    : height = deserialize.float(),
      name = deserialize.string();
}

class House extends Model {
  static final String type = 'house';
  final bool singleStory;
  final int number;

  House(this.number, this.singleStory);

  Serializer encode([Serializer serialize]) => 
    (serialize ?? Serializer(type))
      .integer(number)
      .boolean(singleStory);

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

class Street extends Model {
  static final String type = 'street';
  final List<House> houses;

  Street(this.houses);

  Serializer encode([Serializer serialize, Street street]) =>
    (serialize ?? Serializer(type))
      .collection<House>(houses, House.encodeHouse);

  Street.decode(Deserializer deserialize)
    : houses = deserialize.collection<House>(House.decodeHouse);
}

class Bolt extends Model {
  static final String type = 'bolt';
  final int diameter;
  final String head;

  Bolt(this.head, this.diameter);

  Serializer encode([Serializer serialize]) => 
    (serialize ?? Serializer(type))
      .string(head)
      .integer(diameter);

  Bolt.decode(Deserializer deserialize)
    : head = deserialize.string(),
      diameter = deserialize.integer();
}

abstract class BoltHead {
  static final String flat = 'flat';
  static final String oval = 'oval';
  static final String pan = 'pan';
  static final String truss = 'truss';
}

// Demonstrates nesting pattern A
class OldCar extends Model {
  static final String type = 'old-car';
  final Engine engine;
  final int seats;
  
  OldCar(this.engine, this.seats);

  Serializer encode([Serializer serialize]) =>
    (serialize ?? Serializer(type))
      .model(engine)
      .integer(seats);

  OldCar.decode(Deserializer deserialize)
    : engine = Engine.decode(deserialize),
      seats = deserialize.integer();
}

// Demonstrates nesting pattern B
// tighter packing, but loss of submodel type and version
// use only when type of submodel is under control
class NewCar extends Model {
  static final String type = 'car';
  final Engine engine;
  final int seats;
  
  NewCar(this.engine, this.seats);

  Serializer encode([Serializer serialize]) {
    serialize = serialize ?? Serializer(type);
    return engine.encode(serialize.integer(seats));
  }

  NewCar.decode(Deserializer deserialize)
    : seats = deserialize.integer(),
      engine = Engine.decode(deserialize);
}

class Engine extends Model {
  static final String type = 'engine';
  final int cylinders;

  Engine(this.cylinders);

  Serializer encode([Serializer serialize]) =>
    (serialize ?? Serializer(type))
      .integer(cylinders);

  Engine.decode(Deserializer deserialize)
    : cylinders = deserialize.integer();
}

