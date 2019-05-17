import 'entry_info.dart';
import 'control_chars.dart';
import 'unescaping.dart';
import 'escaping.dart';
import '../index.dart';

class RemoveInfo extends EntryInfo {
  RemoveInfo(String key) {
    this.entryType = ControlChars.removePrefixChar;
    this.key = key;
  }

  static bool canParse(List<String> comps) {
    if (comps.length != 2) return false;
    var entryType = comps[0];
    return entryType == ControlChars.removePrefixChar;
  }

  factory RemoveInfo.fromComps(List<String> comps) => 
    RemoveInfo(unescapeString(comps[1]));

  String toString() =>
    '$entryType:${escapeString(key)}';
}

class IndexInfo extends EntryInfo {
  final String modelType = Index.staticType;
  final int modelVersion;

  IndexInfo(this.modelVersion) {
    this.entryType = ControlChars.indexPrefixChar;
    this.key = 'NDX';
  }

  static bool canParse(List<String> comps) {
    if (comps.length != 3) return false;
    var entryType = comps[0];
    return entryType == ControlChars.indexPrefixChar;
  }

  factory IndexInfo.fromComps(List<String> comps) => 
    IndexInfo(int.parse(comps[1]));

  String toString() => '$entryType:$modelVersion:$key';
}