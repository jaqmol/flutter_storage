import 'dart:convert';

class ControlChars {
  static final indexPrefixChar = 'I';
  static final changePrefixChar = 'C';
  static final removePrefixChar = 'R';
  static final modelPrefixChar = 'M';
  static final valuePrefixChar = 'V';

  static final semicolonChar = ';';
  static final colonChar = ':';
  static final newlineChar = '\n';
  static final returnChar = '\r';

  static final indexPrefixByte = utf8.encode(indexPrefixChar).first;

  static final semicolonByte = utf8.encode(semicolonChar).first;
  static final colonByte = utf8.encode(colonChar).first;
  static final newlineByte = utf8.encode(newlineChar).first;
  static final returnByte = utf8.encode(returnChar).first;

  static final semicolonReplacementChars = '%3B';
  static final colonReplacementChars = '%3A';
  static final newlineReplacementChars = '%0A';
  static final returnReplacementChars = '%0D';
  
  static final List<int> semicolonReplacementBytes = utf8.encode(semicolonReplacementChars);
  static final List<int> colonReplacementBytes = utf8.encode(colonReplacementChars);
  static final List<int> newlineReplacementBytes = utf8.encode(newlineReplacementChars);
  static final List<int> returnReplacementBytes = utf8.encode(returnReplacementChars);
}
