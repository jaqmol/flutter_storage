import 'dart:isolate';
import 'dart:async';

abstract class IsolateController {
  ReceivePort _fromWorkerReceiver;
  SendPort _toWorkerPort;
  Isolate _isolate;
  bool _isRunning;

  Future<void> startIsolate() {
    var completer = Completer();
    _fromWorkerReceiver = ReceivePort();
    _fromWorkerReceiver.listen((dynamic message) {
      if (message is InitResponse) {
        _toWorkerPort = message.toWorkerPort;
        _completeStartIfPossible(completer);
      } else if (_isRunning == true) {
        receiveMessage(message);
      }
    });
    Isolate.spawn<InitRequest>(
      _initWorkerInIsolate,
      InitRequest(
        initIsolateWorkerFn(),
        _fromWorkerReceiver.sendPort,
      ),
    ).then((Isolate isolate) {
      _isolate = isolate;
      _completeStartIfPossible(completer);
    });
    return completer.future;
  }

  void _completeStartIfPossible(Completer startCompleter) {
    if (_toWorkerPort == null) return;
    if (_isolate == null) return;
    _isRunning = true;
    startCompleter.complete();
  }

  void stopIsolate() {
    assert(_isolate != null);
    _isRunning = false;
    _isolate.kill();
  }

  static void _initWorkerInIsolate(InitRequest request) {
    var worker = request.initWorker(request.fromWorkerPort);
    var response = InitResponse(worker.toWorkerPort);
    request.fromWorkerPort.send(response);
  }

  InitIsolateWorker initIsolateWorkerFn();

  void receiveMessage(dynamic message);

  void sendMessage(dynamic message) {
    assert(_toWorkerPort != null);
    _toWorkerPort.send(message);
  }
}

abstract class IsolateWorker {
  final ReceivePort _toWorkerReceiver;
  final SendPort _fromWorkerPort;

  IsolateWorker(this._fromWorkerPort) : _toWorkerReceiver = ReceivePort() {
    _toWorkerReceiver.listen(receiveMessage);
  }

  SendPort get toWorkerPort => _toWorkerReceiver.sendPort;

  void receiveMessage(dynamic message);
  void sendMessage(dynamic message) => _fromWorkerPort.send(message);
}

typedef IsolateWorker InitIsolateWorker(SendPort fromWorkerPort);

class InitRequest {
  final InitIsolateWorker initWorker;
  final SendPort fromWorkerPort;
  InitRequest(this.initWorker, this.fromWorkerPort);
}

class InitResponse {
  SendPort toWorkerPort;
  InitResponse(this.toWorkerPort);
}
