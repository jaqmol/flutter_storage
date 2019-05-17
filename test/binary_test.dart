import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:flutter_test/flutter_test.dart';
import '../lib/src/identifier.dart';
import '../lib/src/storage.dart';

void main() {
  var tmp = Directory.systemTemp.path;
  print('Temporary directory: $tmp');

  test('Binary writing and reading', () async {
    var originalBinData = await File(_binaryTestFilePath).readAsBytes();
    var filePath = path.join(tmp, 'read_write_binary_test.scl');
    var originalBinFileName = path.basename(_binaryTestFilePath);
    var key = identifier();
    var stg = await Storage.open(filePath);
    var slz = await stg.serializer(key);
    slz.string(originalBinFileName);
    slz.bytes(originalBinData);
    await slz.close();
    await stg.flush();
    stg = await Storage.open(filePath);
    var dlz = await stg.deserializer(key);
    var readBinFileName = dlz.string();
    var readBinData = dlz.bytes();
    expect(readBinFileName, equals(originalBinFileName));
    expect(readBinData.length, equals(originalBinData.length));
    for (int i = 0; i < readBinData.length; i++) {
      expect(readBinData[i], equals(originalBinData[i]));
    }
    await File(filePath).delete();
  });
}

String get _binaryTestFilePath {
  var parentDir = File(Platform.script.toFilePath()).parent.path;
  return path.join(parentDir, 'test', 'dart_logo.png');
}