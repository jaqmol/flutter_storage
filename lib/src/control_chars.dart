import 'dart:convert';

class ControlChars {
  static final semicolonChar = ';';
  static final colonChar = ':';
  static final newlineChar = '\n';
  static final returnChar = '\r';

  static final semicolonByte = utf8.encode(semicolonChar).first;
  static final colonByte = utf8.encode(colonChar).first;
  static final newlineByte = utf8.encode(newlineChar).first;
  static final returnByte = utf8.encode(returnChar).first;

  static final semicolonReplacementChar = '%3B';
  static final colonReplacementChar = '%3A';
  static final newlineReplacementChar = '%0A';
  static final returnReplacementChar = '%0D';
  
  static final semicolonReplacementByte = utf8.encode(semicolonReplacementChar).first;
  static final colonReplacementByte = utf8.encode(colonReplacementChar).first;
  static final newlineReplacementByte = utf8.encode(newlineReplacementChar).first;
  static final returnReplacementByte = utf8.encode(returnReplacementChar).first;
}
