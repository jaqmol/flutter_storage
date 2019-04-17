import 'control_chars.dart';

String escapeString(String unescaped) => unescaped
  .replaceAll(ControlChars.newlineChar, ControlChars.newlineReplacementChars)
  .replaceAll(ControlChars.returnChar, ControlChars.returnReplacementChars)
  .replaceAll(ControlChars.semicolonChar, ControlChars.semicolonReplacementChars)
  .replaceAll(ControlChars.colonChar, ControlChars.colonReplacementChars);

List<int> escapeBytes(List<int> unescaped) {
  var acc = List<int>();
  for (int b in unescaped) {
    if (b == ControlChars.newlineByte) {
      acc.addAll(ControlChars.newlineReplacementBytes);
    } else if (unescaped.contains(ControlChars.returnByte)) {
      acc.addAll(ControlChars.returnReplacementBytes);
    } else if (unescaped.contains(ControlChars.semicolonByte)) {
      acc.addAll(ControlChars.semicolonReplacementBytes);
    } else if (unescaped.contains(ControlChars.colonByte)) {
      acc.addAll(ControlChars.colonReplacementBytes);
    } else {
      acc.add(b);
    }
  }
  return acc;
}

String radixEncodeFloat(double component) {
  var decimalStr = component.toString();
  var parts = decimalStr.split('.');
  if (parts.length == 2) {
    var beforeDot = int.parse(parts[0]).toRadixString(16);
    var afterDot = int.parse(parts[1]).toRadixString(16);
    return '$beforeDot.$afterDot';
  }
  return int.parse(parts[0]).toRadixString(16);
}