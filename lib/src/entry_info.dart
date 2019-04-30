import 'control_chars.dart';
import 'escaping.dart';
import 'unescaping.dart';
import 'package:meta/meta.dart';
import 'entry_info_private.dart';

class EntryInfo {
  String entryType;
  String key;

  EntryInfo({
    @required this.entryType,
    @required this.key,
  });

  factory EntryInfo.fromString(String infoString) {
    var comps = infoString.split(':');
    if (ModelInfo.canParse(comps)) {
      return ModelInfo.fromComps(comps);
    } else if (ValueInfo.canParse(comps)) {
      return ValueInfo.fromComps(comps);
    } else if (RemoveInfo.canParse(comps)) {
      return RemoveInfo.fromComps(comps);
    } else if (IndexInfo.canParse(comps)) {
      return IndexInfo.fromComps(comps);
    }
    return null;
  }
}

class ModelInfo extends EntryInfo {
  String valueType;
  String modelType;
  int modelVersion;

  ModelInfo({
    @required String modelType,
    @required int modelVersion,
    String key,
  }) {
    this.entryType = ControlChars.changePrefixChar;
    this.valueType = ControlChars.modelPrefixChar;
    this.modelType = modelType;
    this.modelVersion = modelVersion;
    this.key = key;
  }

  static bool canParse(List<String> comps) {
    if (comps.length != 4 && comps.length != 5) return false;
    var entryType = comps[0];
    var valueType = comps[1];
    return entryType == ControlChars.changePrefixChar &&
           valueType == ControlChars.modelPrefixChar;
  }

  factory ModelInfo.fromComps(List<String> comps) => ModelInfo(
    modelType: comps[2],
    modelVersion: int.parse(comps[3]),
    key: comps.length == 5 ? unescapeString(comps[4]) : null,
  );

  String toString() => key != null
      ? '$entryType:$valueType:$modelType:$modelVersion:${escapeString(key)}'
      : '$entryType:$valueType:$modelType:$modelVersion';
}

class ValueInfo extends EntryInfo {
  String valueType;

  ValueInfo(String key) {
    this.entryType = ControlChars.changePrefixChar;
    this.valueType = ControlChars.valuePrefixChar;
    this.key = key;
  }

  static bool canParse(List<String> comps) {
    if (comps.length != 3) return false;
    var entryType = comps[0];
    var valueType = comps[1];
    return entryType == ControlChars.changePrefixChar &&
           valueType == ControlChars.valuePrefixChar;
  }

  factory ValueInfo.fromComps(List<String> comps) => 
    ValueInfo(unescapeString(comps[2]));

  String toString() =>
    '$entryType:$valueType:${escapeString(key)}';
}
