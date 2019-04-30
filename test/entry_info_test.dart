import 'package:flutter_test/flutter_test.dart';
import '../lib/src/entry_info.dart';
import '../lib/src/entry_info_private.dart';

void main() {
  test("Index info", () {
    var i1 = IndexInfo(0);
    var st = i1.toString();
    var en = EntryInfo.fromString(st);
    expect(en, isInstanceOf<IndexInfo>());
    var i2 = en as IndexInfo;
    expect(i2.modelVersion, equals(0));
  });
  test("Value info", () {
    var ke = 'test-key';
    var v1 = ValueInfo(ke);
    var st = v1.toString();
    var en = EntryInfo.fromString(st);
    expect(en, isInstanceOf<ValueInfo>());
    var v2 = en as ValueInfo;
    expect(v2.key, equals(ke));
  });
  test("Model info", () {
    var mt = 'test-type';
    var mv = 0;
    var ke = 'test-key';
    var m1 = ModelInfo(modelType: mt, modelVersion: mv, key: ke);
    var st = m1.toString();
    var en = EntryInfo.fromString(st);
    expect(en, isInstanceOf<ModelInfo>());
    var m2 = en as ModelInfo;
    expect(m2.modelType, equals(mt));
    expect(m2.modelVersion, equals(mv));
    expect(m2.key, equals(ke));
  });
  test("Remove info", () {
    var ke = 'test-key';
    var r1 = RemoveInfo(ke);
    var st = r1.toString();
    var en = EntryInfo.fromString(st);
    expect(en, isInstanceOf<RemoveInfo>());
    var r2 = en as RemoveInfo;
    expect(r2.key, equals(ke));
  });
}