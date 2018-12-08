import 'package:flutter_test/flutter_test.dart';
import 'dart:isolate';
import 'dart:async';
import 'package:flutter_storage/src/isolate_controller.dart';

void main() {
  test('IsolateController and IsolateWorker', () async {
    var ctrl = await TestController.create();
    var firstMessage = 'First test message';
    var resp = await ctrl.messageRoundtrip(TestRequest(firstMessage));
    expect(resp.payload, equals(firstMessage + ' response'));
    
    await Future.delayed(Duration(seconds: 2));
    var secondMessage = 'Second test message';
    resp = await ctrl.messageRoundtrip(TestRequest(secondMessage));
    expect(resp.payload, equals(secondMessage + ' response'));
  });
}

class TestRequest {
  final String payload;

  TestRequest(this.payload);
}

class TestResponse {
  final String payload;

  TestResponse(this.payload);
}

class TestController extends IsolateController {
  Completer<TestResponse> _roundtripCompleter;

  static Future<TestController> create() async {
    var ctrl = TestController();
    await ctrl.startIsolate();
    return ctrl;
  }

  InitIsolateWorker initIsolateWorkerFn() => TestWorker.create;

  void receiveMessage(dynamic message) {
    if (message is TestResponse) {
      _roundtripCompleter.complete(message);
    }
  }

  Future<TestResponse> messageRoundtrip(TestRequest message) {
    sendMessage(message);
    _roundtripCompleter = Completer<TestResponse>();
    return _roundtripCompleter.future;
  }
}

class TestWorker extends IsolateWorker {
  TestWorker(SendPort fromWorkerPort) : super(fromWorkerPort);
  
  static TestWorker create(SendPort fromWorkerPort) =>
    TestWorker(fromWorkerPort);

  void receiveMessage(dynamic message) {
    if (message is TestRequest) {
      sendMessage(TestResponse(message.payload + ' response'));
    }
  }
}
