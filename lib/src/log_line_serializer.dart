import 'dart:io';
import 'serializer.dart';
import 'model.dart';
import 'control_chars.dart';
import 'log_range.dart';

class LogLineSerializer implements Serializer {
  final RandomAccessFile _raf;
  final _startIndex;

  LogLineSerializer(RandomAccessFile raf, String key)
    : assert(raf != null),
      this._raf = raf,
      _startIndex = raf.positionSync() {
        _raf.writeStringSync('$key');
      }

  Serializer model(Model model) {
    _raf.writeStringSync(':${model.type}:${model.version}');
    return model.encode(this);
  }

  Serializer string(String component) {
    _raf.writeStringSync(';');
    _raf.writeStringSync(_escapeString(component));
    return this;
  }

  Serializer bytes(Iterable<int> component) {
    _raf.writeStringSync(';');
    _raf.writeFromSync(_escapeBytes(component));
    return this;
  }

  Serializer boolean(bool component) {
    _raf.writeStringSync(';');
    _raf.writeStringSync(component ? 'T' : 'F');
    return this;
  }

  Serializer integer(int component) {
    _raf.writeStringSync(';');
    _raf.writeStringSync(component.toRadixString(16));
    return this;
  }

  Serializer float(double component) {
    _raf.writeStringSync(';');
    _raf.writeStringSync(_radixEncodeFloat(component));
    return this;
  }

  Serializer collection<T>(
    Iterable<T> components,
    void encodeFn(Serializer s, T item),
  ) {
    _raf.writeStringSync(';');
    integer(components.length);
    _raf.writeStringSync(';');
    for (T c in components) encodeFn(this, c);
    return this;
  }

  LogRange conclude() {
    _raf.writeStringSync('\n');
    var _endIndex = _raf.positionSync();
    return LogRange(_startIndex, _endIndex - _startIndex);
  }
}

String _escapeString(String unescaped) => unescaped
  .replaceAll(ControlChars.newlineChar, ControlChars.newlineReplacementChar)
  .replaceAll(ControlChars.returnChar, ControlChars.returnReplacementChar)
  .replaceAll(ControlChars.semicolonChar, ControlChars.semicolonReplacementChar)
  .replaceAll(ControlChars.colonChar, ControlChars.colonReplacementChar);

List<int> _escapeBytes(Iterable<int> unescaped) => unescaped
  .map((int byte) {
    if (byte == ControlChars.newlineByte) {
      return ControlChars.newlineReplacementByte;
    } else if (byte == ControlChars.returnByte) {
      return ControlChars.returnReplacementByte;
    } else if (byte == ControlChars.semicolonByte) {
      return ControlChars.semicolonReplacementByte;
    } else if (byte == ControlChars.colonByte) {
      return ControlChars.colonReplacementByte;
    }
    return byte;
  })
  .toList();

String _radixEncodeFloat(double component) {
  var decimalStr = component.toString();
    var parts = decimalStr.split('.');
    if (parts.length == 2) {
      var beforeDot = int.parse(parts[0]).toRadixString(16);
      var afterDot = int.parse(parts[1]).toRadixString(16);
      return '$beforeDot.$afterDot';
    }
    return int.parse(parts[0]).toRadixString(16);
}
