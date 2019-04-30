import 'control_chars.dart';
import 'package:meta/meta.dart';

String unescapeString(String escaped) => escaped
  .replaceAll(ControlChars.newlineReplacementChars, ControlChars.newlineChar)
  .replaceAll(ControlChars.returnReplacementChars, ControlChars.returnChar)
  .replaceAll(ControlChars.semicolonReplacementChars, ControlChars.semicolonChar)
  .replaceAll(ControlChars.colonReplacementChars, ControlChars.colonChar);

List<int> unescapeBytes(List<int> escaped) {
  assert(escaped is List<int>);
  var ranges = _rangesOfList(
    searchFor: ControlChars.newlineReplacementBytes,
    searchIn: escaped,
    replacement: ControlChars.newlineByte,
  );
  ranges.addAll(_rangesOfList(
    searchFor: ControlChars.returnReplacementBytes, 
    searchIn: escaped,
    replacement: ControlChars.returnByte,
  ));
  ranges.addAll(_rangesOfList(
    searchFor: ControlChars.semicolonReplacementBytes, 
    searchIn: escaped,
    replacement: ControlChars.semicolonByte,
  ));
  ranges.addAll(_rangesOfList(
    searchFor: ControlChars.colonReplacementBytes, 
    searchIn: escaped,
    replacement: ControlChars.colonByte,
  ));
  ranges.sort((_Range a, _Range b) => a.start.compareTo(b.start));

  var acc = List<int>();
  acc.addAll(escaped.sublist(0, ranges.first.start));
  acc.add(ranges.first.replacement);

  for (int i = 1; i < ranges.length; i++) {
    var last = ranges[i - 1];
    var current = ranges[i];
    acc.addAll(escaped.sublist(last.end, current.start));
    acc.add(current.replacement);
  }

  acc.addAll(escaped.sublist(ranges.last.end, escaped.length));
  return acc;
}

class _Range {
  final int start;
  final int end;
  final int replacement;
  _Range({this.start, this.end, this.replacement});
}

List<_Range> _rangesOfList({
  @required List<int> searchFor,
  @required List<int> searchIn, 
  @required int replacement,
}) {
  int searchForLength = searchFor.length;
  var acc = List<_Range>();
  if (searchForLength == 0) return acc;

  int i = 0, limit = searchIn.length - searchForLength;
  while (i < limit) {
    var finding = _firstRangeOfList(
      searchFor: searchFor,
      searchIn: searchIn,
      startIndex: i,
      replacement: replacement,
    );
    if (finding == null) break;
    acc.add(finding);
    i = finding.end;
  }

  return acc;
}

_Range _firstRangeOfList({
  @required List<int> searchFor,
  @required List<int> searchIn, 
  @required int startIndex,
  @required int replacement,
}) {
  int searchForLength = searchFor.length;
  if (searchForLength == 0) return null;

  int limit = searchIn.length - searchForLength;

  for (int i = startIndex; i <= limit; i++) {
    if (searchFor[0] == searchIn[i]) {
      bool found = true;

      for (int j = 1; j < searchForLength; j++) {
        if (searchFor[j] != searchIn[i+j]) {
          found = false;
          break;
        }
      }

      if (found) {
        return _Range(
          start: i, 
          end: i + searchForLength, 
          replacement: replacement,
        );
      }
    }
  }

  return null;
}

double radixDecodeFloat(String hexString) {
  var parts = hexString.split('.');
  if (parts.length == 2) {
    var beforeDot = int.parse(parts[0], radix: 16);
    var afterDot = int.parse(parts[1], radix: 16);
    var decimalStr = '$beforeDot.$afterDot';
    return double.parse(decimalStr);
  }
  var decimalInt = int.parse(parts[0], radix: 16);
  return decimalInt as double;
}