import 'control_chars.dart';

String escapeString(String unescaped) => unescaped
  .replaceAll(ControlChars.newlineChar, ControlChars.newlineReplacementChars)
  .replaceAll(ControlChars.returnChar, ControlChars.returnReplacementChars)
  .replaceAll(ControlChars.semicolonChar, ControlChars.semicolonReplacementChars)
  .replaceAll(ControlChars.colonChar, ControlChars.colonReplacementChars);

List<int> escapeBytes(Iterable<int> unescaped) {
  var acc = List<int>();
  for (int b in unescaped) {
    if (b == ControlChars.newlineBytes.first) {
      acc.addAll(ControlChars.newlineReplacementBytes);
    } else if (b == ControlChars.returnBytes.first) {
      acc.addAll(ControlChars.returnReplacementBytes);
    } else if (b == ControlChars.semicolonBytes.first) {
      acc.addAll(ControlChars.semicolonReplacementBytes);
    } else if (b == ControlChars.colonBytes.first) {
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