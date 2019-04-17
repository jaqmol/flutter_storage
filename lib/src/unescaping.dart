import 'control_chars.dart';

String unescapeString(String escaped) => escaped
  .replaceAll(ControlChars.newlineReplacementChars, ControlChars.newlineChar)
  .replaceAll(ControlChars.returnReplacementChars, ControlChars.returnChar)
  .replaceAll(ControlChars.semicolonReplacementChars, ControlChars.semicolonChar)
  .replaceAll(ControlChars.colonReplacementChars, ControlChars.colonChar);

List<int> unescapeBytes(List<int> escaped) {
  var buffer = _replaceBytes(escaped, ControlChars.newlineReplacementBytes, ControlChars.newlineByte);
  buffer = _replaceBytes(buffer, ControlChars.returnReplacementBytes, ControlChars.returnByte);
  buffer = _replaceBytes(buffer, ControlChars.semicolonReplacementBytes, ControlChars.semicolonByte);
  return _replaceBytes(buffer, ControlChars.colonReplacementBytes, ControlChars.colonByte);
}

List<int> _replaceBytes(List<int> searchIn, List<int> searchFor, int replacement) {
  var acc = List<int>();
  var indexes = _listIndexesOf(searchIn, searchFor);
  int i = 0, m = searchIn.length, n = searchFor.length;
  while (i < m) {
    if (indexes.contains(i)) {
      acc.add(replacement);
      i += n;
    } else {
      acc.add(searchIn[i]);
      i++;
    }
  }
  return acc;
}

List<int> _listIndexesOf(List<int> searchIn, List<int> searchFor) {
  var acc = List<int>();
  int i = 0, j = 0, m = searchIn.length, n = searchFor.length;
  while (i < m && j < n) {
    if (searchIn[i] == searchFor[j]) {
      i++;
      j++;
      if (j == n) {
        acc.add(i - n);
      }
    } else {
      i++;
      j = 0;
    }
  }
  return acc;
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