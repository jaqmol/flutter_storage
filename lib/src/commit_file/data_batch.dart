import 'dart:collection';

class DataBatch extends ListBase<int> {
  final int startIndex;
  List<int> _data;

  DataBatch(this.startIndex, List<int> data)
    : assert(data != null),
      _data = data;

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