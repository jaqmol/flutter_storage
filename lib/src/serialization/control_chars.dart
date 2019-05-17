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

  static final indexPrefixBytes = utf8.encode(indexPrefixChar);

  static final semicolonBytes = utf8.encode(semicolonChar);
  static final colonBytes = utf8.encode(colonChar);
  static final newlineBytes = utf8.encode(newlineChar);
  static final returnBytes = utf8.encode(returnChar);

  static final semicolonReplacementChars = '%3B';
  static final colonReplacementChars = '%3A';
  static final newlineReplacementChars = '%0A';
  static final returnReplacementChars = '%0D';
  
  static final semicolonReplacementBytes = utf8.encode(semicolonReplacementChars);
  static final colonReplacementBytes = utf8.encode(colonReplacementChars);
  static final newlineReplacementBytes = utf8.encode(newlineReplacementChars);
  static final returnReplacementBytes = utf8.encode(returnReplacementChars);
}
