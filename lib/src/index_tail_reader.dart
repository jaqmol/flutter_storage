import 'dart:io';
import 'control_chars.dart';
import 'dart:collection';
import 'component_reader.dart';
import 'line_deserializer.dart';

class IndexTailReader {
  final RandomAccessFile _raf;
  final int _rafLength;
  final List<int> _buffer;

  IndexTailReader(RandomAccessFile raf)
    : _raf = raf,
      _rafLength = raf.lengthSync(),
      _buffer = List<int>() {
        int initialIndex = _raf.positionSync();
        _reverseReadUntilLastIndex();
        _raf.setPositionSync(initialIndex);
      }

  void _reverseReadUntilLastIndex() {
    int index = _rafLength - 1;
    _raf.setPositionSync(index);
    int b = _raf.readByteSync();

    while (index > -1) {
      _buffer.add(b);

      if (b == ControlChars.indexPrefixByte) {
        break;
      }
      
      index--;
      _raf.setPositionSync(index);
      b = _raf.readByteSync();
    }
  }

  Iterable<LineDeserializer> get tailLines => 
    IndexTailIterable(_buffer.reversed);
}

class IndexTailIterable extends IterableBase<LineDeserializer> {
  final Iterable<int> _tailIterable;
  IndexTailIterable(Iterable<int> tailIterable) 
    : this._tailIterable = tailIterable;
  IndexTailIterator get iterator => 
    IndexTailIterator(_tailIterable);
}

class IndexTailIterator extends Iterator<LineDeserializer> {
  final Iterator<int> _tailIterator;
  final List<int> _lineBuffer;
  int _index = 0;

  IndexTailIterator(Iterable<int> tailBuffer)
    : _tailIterator = tailBuffer.iterator,
      _lineBuffer = List<int>();

  bool moveNext() {
    _lineBuffer.clear();
    while(_tailIterator.moveNext()) {
      int b = _tailIterator.current;
      if (b == ControlChars.newlineByte) {
        break;
      }
      _lineBuffer.add(b);
    }
    return _lineBuffer.length > 0;
  }

  LineDeserializer get current {
    var ld = LineDeserializer(_ByteArrayCompsReader(
      _lineBuffer.iterator,
      _index,
    ));
    _index += _lineBuffer.length;
    return ld;
  }
}

class _ByteArrayCompsReader implements ComponentReader {
  final Iterator<int> _charIterator;
  final List<int> _compBuffer;
  final int startIndex;
  
  _ByteArrayCompsReader(Iterator<int> charIterator, this.startIndex)
    : _charIterator = charIterator,
      _compBuffer = List<int>();

  bool moveNext() {
    _compBuffer.clear();
    while(_charIterator.moveNext()) {
      int b = _charIterator.current;
      if (b == ControlChars.semicolonByte) {
        break;
      }
      _compBuffer.add(b);
    }
    return _compBuffer.length > 0;
  }

  List<int> get current => _compBuffer;
}


