import 'package:flutter_test/flutter_test.dart';
import 'dart:io';
import 'dart:convert';
import '../lib/src/escaping.dart';
import '../lib/src/control_chars.dart';
import 'line_serializer_utils.dart';
import '../lib/src/line_deserializer.dart';
import '../lib/src/raf_component_reader.dart';

void main() {
  test('String value deserialization', () {
    var r = LineSerializerUtils.serializeStringValue();
    var d = LineSerializerUtils.lineDeserializer(r.filename);
    var content = d.string();
    expect(content, equals(LineSerializerUtils.testText));
    File(r.filename).deleteSync();
  });
  test('Byte value deserialization', () {
    var r = LineSerializerUtils.serializeByteValue();
    var d = LineSerializerUtils.lineDeserializer(r.filename);
    var content = d.bytes();
    expect(r.bytes.length, equals(content.length));
    for (int i = 0; i < r.bytes.length; i++) {
      int expectedByte = r.bytes[i];
      int contentByte = content[i];
      expect(contentByte, equals(expectedByte));
    }
    File(r.filename).deleteSync();
  });
  test('Boolean value deserialization', () {
    var r = LineSerializerUtils.serializeBooleanValue();
    var d = LineSerializerUtils.lineDeserializer(r.filename);
    expect(d.boolean(), isTrue);
    expect(d.boolean(), isFalse);
    File(r.filename).deleteSync();
  });
  test('Integer value deserialization', () {
    var r = LineSerializerUtils.serializeIntegerValue();
    var d = LineSerializerUtils.lineDeserializer(r.filename);
    expect(d.integer(), equals(23));
    expect(d.integer(), equals(42));
    File(r.filename).deleteSync();
  });
  test('Float value deserialization', () {
    var r = LineSerializerUtils.serializeFloatValue();
    var d = LineSerializerUtils.lineDeserializer(r.filename);
    expect(d.float(), equals(42.15));
    expect(d.float(), equals(23.13));
    File(r.filename).deleteSync();
  });
  test('List value deserialization', () {
    var r = LineSerializerUtils.serializeListValue();
    var d = LineSerializerUtils.lineDeserializer(r.filename);
    List<String> expectedWords = LineSerializerUtils.testText.split(' ');
    List<String> words = d.list<String>(() => d.string());
    expect(words, equals(expectedWords));
    File(r.filename).deleteSync();
  });
  test('Map value deserialization', () {
    var r = LineSerializerUtils.serializeMapValue();
    var d = LineSerializerUtils.lineDeserializer(r.filename);
    List<String> words = LineSerializerUtils.testText.split(' ');
    var expectedIndexForWord = Map<String, int>();
    for (int i = 0; i < words.length; i++) {
      expectedIndexForWord[words[i]] = i;
    }

    Map<String, int> indexForWord = d.map<String, int>(() =>
      MapEntry<String, int>(
        d.string(),
        d.integer(),
      )
    );
    expect(indexForWord, equals(expectedIndexForWord));
    File(r.filename).deleteSync();
  });
}
