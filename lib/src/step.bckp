import 'operators/writer.dart';
import 'operators/reader.dart';
import 'operators/controller.dart';
import 'dart:async';

typedef Future<T> WriterCallback<T>(Writer writer);
typedef Future<T> ReaderCallback<T>(Reader reader);
typedef Future<T> ControlCallback<T>(Controller controller);

abstract class Step<T> {
  Completer<T> get completer;
}

class WriteStep<T> extends Step<T> {
  final WriterCallback<T> callback;
  final Completer<T> completer;

  WriteStep(this.callback) : completer = Completer<T>();
}

class ReadStep<T> extends Step<T> {
  final ReaderCallback<T> callback;
  final Completer<T> completer;

  ReadStep(this.callback) : completer = Completer<T>();
}

class ControlStep<T> extends Step<T> {
  final ControlCallback callback;
  final Completer<T> completer;

  ControlStep(this.callback) : completer = Completer<T>();
}