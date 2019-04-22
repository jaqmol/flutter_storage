import 'dart:collection';

abstract class ComponentReader extends IterableBase<List<int>> {
  Iterable<List<int>> chunks(int bufferSize);
  int get startIndex;
}
