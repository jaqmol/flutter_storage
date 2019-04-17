import 'byte_array_comp_buffer.dart';
import 'line_deserializer.dart';

class ByteArrayMultilineDeserializer {
  final List<int> _bytes;
  int _currentIndex;

  ByteArrayMultilineDeserializer(List<int> bytes)
    : _bytes = bytes,
      _currentIndex = 0;

  LineDeserializer get nextLine {
    if (_currentIndex == _bytes.length) return null;
    return LineDeserializer(ByteArrayCompBuffer(
      _bytes, _currentIndex, (int newlineIndex) {
        _currentIndex = newlineIndex + 1;
      }
    ));
  }
}