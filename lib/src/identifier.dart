import 'dart:math';

var _rnd = Random.secure();

/// Create unique identifiers to be used as 
/// database keys or parts of keys.
/// 
String identifier() {
  var time = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
  var rand = _rnd.nextInt(10000).toRadixString(36);
  var id = '$time-$rand';
  return id;
}