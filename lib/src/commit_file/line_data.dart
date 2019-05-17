import 'dart:collection';

class LineData extends ListBase<int> {
  final int startIndex;
  List<int> _data;

  LineData(this.startIndex, [Iterable<int> data])
    : assert(startIndex != null),
      _data = data?.toList() ?? List<int>();

  @override
  int operator[] (int index) => _data[index];

  @override
  void operator[]= (int index, int byte) {
    _data[index] = byte;
  }

  @override
  int get length => _data.length;

  @override
  set length(int newLength) {
    _data.length = newLength;
  }
}