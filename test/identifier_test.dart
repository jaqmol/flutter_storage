import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_storage/flutter_storage.dart';

void main() {
  test('Creating one identifier', () {
    String id = identifier();
    expect(id, isNotNull);
    expect(id.length, greaterThan(0));
  });
  test('Creating many unique identifiers', () {
    int amount = 10000;
    var allIdsList = List<String>.generate(amount, (_) => identifier());
    var allIdsSet = Set.of(allIdsList);
    expect(allIdsList.length, equals(amount));
    expect(allIdsSet.length, equals(amount));
  });
}