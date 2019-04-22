import 'control_chars.dart';
import 'escaping.dart';
import 'unescaping.dart';
import 'package:meta/meta.dart';

class EntryInfo {
  String entryType;
  String key;

  EntryInfo({
    @required this.entryType,
    @required this.key,
  });

  factory EntryInfo.fromString(String infoString) {
    var comps = infoString.split(':');
    if (ModelInfo._canParse(comps)) {
      return ModelInfo._fromComps(comps);
    } else if (ValueInfo._canParse(comps)) {
      return ValueInfo._fromComps(comps);
    } else if (RemoveInfo._canParse(comps)) {
      return RemoveInfo._fromComps(comps);
    } else if (IndexInfo._canParse(comps)) {
      return IndexInfo._fromComps(comps);
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

  static bool _canParse(List<String> comps) {
    if (comps.length != 4 || comps.length != 5) return false;
    var entryType = comps[0];
    var valueType = comps[1];
    return entryType == ControlChars.changePrefixChar &&
           valueType == ControlChars.modelPrefixChar;
  }

  factory ModelInfo._fromComps(List<String> comps) => ModelInfo(
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

  static bool _canParse(List<String> comps) {
    if (comps.length != 3) return false;
    var entryType = comps[0];
    var valueType = comps[1];
    return entryType == ControlChars.changePrefixChar &&
           valueType == ControlChars.valuePrefixChar;
  }

  factory ValueInfo._fromComps(List<String> comps) => 
    ValueInfo(unescapeString(comps[2]));

  String toString() =>
    '$entryType:$valueType:${escapeString(key)}';
}

class RemoveInfo extends EntryInfo {
  RemoveInfo(String key) {
    this.entryType = ControlChars.removePrefixChar;
    this.key = key;
  }

  static bool _canParse(List<String> comps) {
    if (comps.length != 2) return false;
    var entryType = comps[0];
    return entryType == ControlChars.removePrefixChar;
  }

  factory RemoveInfo._fromComps(List<String> comps) => 
    RemoveInfo(unescapeString(comps[2]));

  String toString() =>
    '$entryType:${escapeString(key)}';
}

class IndexInfo extends EntryInfo {
  final int modelVersion;

  IndexInfo(this.modelVersion) {
    this.entryType = ControlChars.indexPrefixChar;
    this.key = 'NDEX';
  }

  static bool _canParse(List<String> comps) {
    if (comps.length != 3) return false;
    var entryType = comps[0];
    return entryType == ControlChars.indexPrefixChar;
  }

  factory IndexInfo._fromComps(List<String> comps) => 
    IndexInfo(int.parse(comps[1]));

  String toString() => '$entryType:$modelVersion:$key}';
}