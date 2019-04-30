import 'dart:collection';

abstract class ComponentReader {
  bool moveNext();
  List<int> get current;
  int get startIndex;
  // Iterable<List<int>> chunks(int bufferSize);
}