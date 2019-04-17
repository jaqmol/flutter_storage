import 'comp_buffer.dart';
import 'bitwise_line_reader.dart';
import 'control_chars.dart';

class BitwiseLineReaderCompBuffer extends CompBuffer {
  final BitwiseLineReader _reader;
  final int _startPosition;

  final List<int> _bytes;
  CompBufferEndType _compEnd;

  BitwiseLineReaderCompBuffer(
    BitwiseLineReader reader,
    int startPosition,
  ) : _reader = reader,
      _startPosition = startPosition,
      _bytes = List<int>();

  fill() {
    _bytes.clear();
    if (
      _compEnd == CompBufferEndType.EOF ||
      _compEnd == CompBufferEndType.EOF
    ) return;
    int b = _reader.nextByte;
    while (true) {
      if (b == -1) {
        _compEnd = CompBufferEndType.EOF;
        break;
      } else if (b == ControlChars.semicolonByte) {
        _compEnd = CompBufferEndType.Semicolon;
        break;
      } else if (b == ControlChars.newlineByte) {
        _compEnd = CompBufferEndType.EOL;
        break;
      }
      _bytes.add(b);
      b = _reader.nextByte;
    }
  }

  List<int> get bytes => _bytes;

  List<int> readAllBytes() {
    int currentIndex = _reader.readPosition();
    _reader.setReadPosition(_startPosition);
    var acc = List<int>();
    int b = _reader.nextByte;
    while (true) {
      if (b == -1) {
        _compEnd = CompBufferEndType.EOF;
        break;
      } else if (b == ControlChars.newlineByte) {
        _compEnd = CompBufferEndType.EOL;
        break;
      }
      acc.add(b);
      b = _reader.nextByte;
    }
    _reader.setReadPosition(currentIndex);
    return acc;
  }

  int fixReadPosition() => _reader.fixReadPosition();
}
