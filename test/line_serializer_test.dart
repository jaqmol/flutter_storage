import 'package:flutter_test/flutter_test.dart';
import 'dart:io';
import 'dart:convert';
import '../lib/src/serialization/escaping.dart';
import '../lib/src/serialization/control_chars.dart';
import 'line_serializer_utils.dart';

void main() {
  test('String value serialization', () {
    var r = LineSerializerUtils.serializeStringValue();
    var written = File(r.filename).readAsStringSync();
    var infoAndContent = written.split(';');
    var info = infoAndContent[0];
    var content = infoAndContent[1];
    expect(info, equals('C:V:${r.key}'));
    expect(content, equals(escapeString(LineSerializerUtils.testText) + '\n'));
    File(r.filename).deleteSync();
  });
  test('Byte value serialization', () {
    var r = LineSerializerUtils.serializeByteValue();
    var written = File(r.filename).readAsBytesSync();
    List<int> infoBytes;
    List<int> contentBytes;
    for (int i = 0; i < written.length; i++) {
      int b = written[i];
      if (b == ControlChars.semicolonByte) {
        infoBytes = written.sublist(0, i);
        contentBytes = written.sublist(i + 1, written.length);
        break;
      }
    }
    var info = utf8.decode(infoBytes);
    expect(info, equals('C:V:${r.key}'));
    var escapedDartLogo = escapeBytes(r.bytes);
    escapedDartLogo.add(ControlChars.newlineByte);
    for (int i = 0; i < contentBytes.length; i++) {
      int writtenByte = contentBytes[i];
      int expectedByte = escapedDartLogo[i];
      expect(writtenByte, equals(expectedByte));
    }
    File(r.filename).deleteSync();
  });
  test('Boolean value serialization', () {
    var r = LineSerializerUtils.serializeBooleanValue();
    var written = File(r.filename).readAsStringSync();
    expect(written, equals('C:V:${r.key};T;F\n'));
    File(r.filename).deleteSync();
  });
  test('Integer value serialization', () {
    var r = LineSerializerUtils.serializeIntegerValue();
    var written = File(r.filename).readAsStringSync();
    expect(written, equals('C:V:${r.key};${23.toRadixString(16)};${42.toRadixString(16)}\n'));
    File(r.filename).deleteSync();
  });
  test('Float value serialization', () {
    var r = LineSerializerUtils.serializeFloatValue();
    var written = File(r.filename).readAsStringSync();
    expect(written, equals('C:V:${r.key};${radixEncodeFloat(42.15)};${radixEncodeFloat(23.13)}\n'));
    File(r.filename).deleteSync();
  });
  test('List value serialization', () {
    var r = LineSerializerUtils.serializeListValue();
    List<String> words = LineSerializerUtils.testText.split(' ');
    var serializedWords = words.map<String>(escapeString).join(';');
    var written = File(r.filename).readAsStringSync();
    var expected = 'C:V:${r.key};${words.length.toRadixString(16)};$serializedWords\n';
    expect(written, equals(expected));
    File(r.filename).deleteSync();
  });
  test('Map value serialization', () {
    var r = LineSerializerUtils.serializeMapValue();
    List<String> words = LineSerializerUtils.testText.split(' ');
    var indexForWord = Map<String, int>();
    for (int i = 0; i < words.length; i++) {
      indexForWord[words[i]] = i;
    }
    var serializedIndexForWord = indexForWord.entries.map<String>(
      (MapEntry<String, int> e) => '${escapeString(e.key)};${e.value.toRadixString(16)}',
    ).join(';');
    var written = File(r.filename).readAsStringSync();
    var expected = 'C:V:${r.key};${indexForWord.length.toRadixString(16)};$serializedIndexForWord\n';
    expect(written, equals(expected));
    File(r.filename).deleteSync();
  });
}
