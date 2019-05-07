import 'dart:io';
import 'package:meta/meta.dart';
import 'entry_info.dart';
import 'entry_info_private.dart';

class RemoveSerializer {
  final RandomAccessFile _raf;
  final EntryInfo entryInfo;
  final int _startIndex;

  RemoveSerializer({
    @required RandomAccessFile raf,
    @required String key,
  }): assert(raf != null),
      assert(key != null),
      _raf = raf,
      entryInfo = RemoveInfo(key),
      _startIndex = raf.positionSync(){
        _raf.writeStringSync(entryInfo.toString());
      }

  int concludeWithStartIndex() {
    _raf.writeStringSync('\n');
    return _startIndex;
  }
}