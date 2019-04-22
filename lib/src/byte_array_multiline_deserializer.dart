import 'byte_array_component_reader.dart';
import 'line_deserializer.dart';

class ByteArrayMultilineDeserializer {
  final List<int> _bytes;
  int _currentIndex;

  ByteArrayMultilineDeserializer(List<int> bytes)
    : _bytes = bytes,
      _currentIndex = 0;

  LineDeserializer get nextLine {
    if (_currentIndex == _bytes.length) return null;
    return LineDeserializer(ByteArrayComponentReader(
      _bytes, _currentIndex, (int newlineIndex) {
        _currentIndex = newlineIndex + 1;
      }
    ));
  }
}