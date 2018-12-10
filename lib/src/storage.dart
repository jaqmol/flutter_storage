/*
  Frontend that established isolate and provides messaging with the backend.
*/

import 'isolate_controller.dart';
import 'dart:isolate';
import 'control_messages.dart';
import 'storage_backend.dart';
import 'identifier.dart';
import 'dart:collection';
import 'dart:async';
import 'serialization.dart';
import 'frontend_entries.dart';

/// Flutter Storage
/// 
/// Storage frontend for commit log based database.
/// 
class Storage extends IsolateController {
  final String path;
  final HashMap<String, Completer> _pendingCompleters;
  final HashMap<String, Sink> _pendingSinks;

  Storage._init(this.path)
    : _pendingCompleters = HashMap<String, Completer>(),
      _pendingSinks = HashMap<String, Sink>();

  
  /// Create a Flutter Storage instance
  /// 
  /// Provide the [path] for the file the database should
  /// be contained in.
  /// 
  static Future<Storage> create(String path) async {
    var ctrl = Storage._init(path);
    await ctrl.startIsolate();
    await ctrl._sendFutureRequest<void>(InitBackendRequest(
      identifier(),
      path,
    ));
    return ctrl;
  }

  InitIsolateWorker initIsolateWorkerFn() => _BackendWorker.create;

  void receiveMessage(dynamic message) {
    if (message is ControlResponse) {
      _processControlResponse(message);
    }
  }

  // Frontend API

  /// Sets the given value for the given key.
  /// 
  /// Logs the change to the underlaying file.
  /// Keeps the value in the cache until [clearCache] is called.
  /// To make a batch of changes undoable, wrap them in both:
  /// [openUndoGroup] and [closeUndoGroup].
  /// 
  Future<void> setValue(String key, Model model) =>
    _sendFutureRequest<void>(SetValueRequest(
      identifier(),
      key,
      model,
    ));

  /// Adding a collection of key-value-pairs.
  /// 
  /// The key-value-pairs need to be provided as iterable
  /// of [StorageEncodeEntry]s.
  /// 
  Future<void> addEntries(Iterable<StorageEncodeEntry> entries) =>
    _sendFutureRequest<void>(AddEntriesRequest(
      identifier(),
      entries,
    ));

  /// Get a value deserializer for the given key.
  /// 
  /// Check the deserializer's meta field for the
  /// type of the model for decoding.
  /// 
  Future<Deserializer> value(String key) =>
    _sendFutureRequest<Deserializer>(ValueRequest(
      identifier(),
      key,
    ));

  /// Get a value deserializer for the given key.
  /// 
  /// Check the deserializer's meta field for the
  /// type of the model for decoding.
  /// 
  Future<Deserializer> remove(String key) =>
    _sendFutureRequest<Deserializer>(RemoveRequest(
      identifier(),
      key,
    ));

  // Undo Support

  /// Open an undo group to start grouping changes for undo.
  /// 
  /// Close the undo group with [closeUndoGroup].
  /// Call [undo] to revert the storage state.
  /// 
  /// For each call to [openUndoGroup] there must be a
  /// balancing call to [closeUndoGroup].
  /// The current undo group will be concluded only after
  /// the last balancing call to [closeUndoGroup].
  /// 
  Future<void> openUndoGroup() =>
    _sendFutureRequest<void>(OpenUndoGroupRequest(
      identifier(),
    ));

  /// Close an undo group to conclude an undoable collection of changes.
  /// 
  /// Open an undo group with [openUndoGroup].
  /// Call [undo] to revert the storage state.
  /// 
  /// For each call to [openUndoGroup] there must be a
  /// balancing call to [closeUndoGroup].
  /// The current undo group will be concluded only after
  /// the last balancing call to [closeUndoGroup].
  /// 
  Future<void> closeUndoGroup() =>
    _sendFutureRequest<void>(CloseUndoGroupRequest(
      identifier(),
    ));

  /// Undo all changes made in an undo group;
  /// 
  /// Returns a [List<UndoAction>]s containing
  /// all [UndoAction]s for the user to 
  /// further process undo actions.
  /// 
  Future<List<UndoAction>> undo() {
    var request = UndoRequest(identifier());
    return _sendFutureRequest<List<UndoAction>>(request);
  }

  // Iteration Support

  /// Iterate keys and values
  /// 
  Stream<StorageDecodeEntry> get entries {
    var request = EntriesRequest(identifier());
    return _sendStreamRequest<StorageDecodeEntry>(request);
  }

  /// Iterate keys only
  /// 
  Stream<String> get keys =>
    _sendStreamRequest<String>(KeysRequest(
      identifier(),
    ));

  /// Iterate values only
  /// 
  Stream<Deserializer> get values =>
    _sendStreamRequest<Deserializer>(ValuesRequest(
      identifier(),
    ));

  /// Perform compaction
  /// 
  /// Compaction is the process of reducing all logged
  /// key-value-pairs to the most recent state.
  /// 
  Future<void> compaction() =>
    _sendFutureRequest<void>(CompactionRequest(
      identifier(),
    ));

  /// Get the stale data ratio
  /// 
  /// Calculated by dividing the amount of changes since
  /// last compaction by the amount of actual
  /// current values.
  /// 
  /// Non-actual and -current values, stale data resp., 
  /// are changes and removals.
  /// 
  /// A [staleRatio] of 0.5 means that 50% of the
  /// storage content consists of stale data.
  /// 
  /// A [staleRatio] of 2 means that there is 2 times 
  /// more stale data stored than current.
  /// 
  /// Stale data can be used to undo changes.
  /// Compaction removes stale data.
  ///
  Future<double> get staleRatio =>
    _sendFutureRequest<double>(StaleRatioRequest(
      identifier(),
    ));

  /// Check if storage needs compaction
  /// 
  /// Returns true in case the storage needs compaction.
  /// The treshold [staleRatio] is 0.5.
  /// 
  Future<bool> get needsCompaction =>
    _sendFutureRequest<bool>(NeedsCompactionRequest(
      identifier(),
    ));

  /// Clears the in-memory-cache of storage
  /// 
  /// Removes all cached values. Does not affect indexes
  /// as indexes are always kept in memory.
  /// 
  Future<void> clearCache() =>
    _sendFutureRequest<void>(ClearCacheRequest(
      identifier(),
    ));

  /// Flush state of storage to solid state.
  /// 
  /// A flush appends all management state of
  /// a storage to the end of the log.
  /// Thus a storage can be opened fast and does not
  /// need to be replay the complete log.
  /// 
  Future<void> flushState() =>
    _sendFutureRequest<void>(FlushStateRequest(
      identifier(),
    ));

  /// Flush state of storage and close.
  /// 
  /// In case a storage is not flushed and closed
  /// the complete log needs to be replayed to
  /// restore it's management state, thus
  /// making opening it slower.
  /// 
  /// Hint: always [flushStateAndClose] a storage.
  /// 
  Future<void> flushStateAndClose() =>
    _sendFutureRequest<void>(FlushStateAndCloseRequest(
      identifier(),
    ));

  // Private Methods

  Future<T> _sendFutureRequest<T>(ControlRequest req) {
    var completer = Completer<T>();
    _pendingCompleters[req.id] = completer;
    sendMessage(req);
    return completer.future;
  }

  Stream<T> _sendStreamRequest<T>(ControlRequest req) {
    var sink = StreamController<T>();
    _pendingSinks[req.id] = sink;
    sendMessage(req);
    return sink.stream;
  }

  void _processControlResponse(ControlResponse response) {
    if (response is RequestConclusion) {
      _complete<void>(response.id, null);

    } else if (response is RemoveResponse) {
      _complete<Deserializer>(response.id, response.value);

    } else if (response is ValueResponse) {
      _complete<Deserializer>(response.id, response.value);

    } else if (response is UndoResponse) {
      _complete<List<UndoAction>>(response.id, response.actions);

    } else if (response is EntriesResponse) {
      _addToSink<StorageDecodeEntry>(response.id, response.entry);

    } else if (response is KeysResponse) {
      _addToSink<String>(response.id, response.key);

    } else if (response is ValuesResponse) {
      _addToSink<Deserializer>(response.id, response.deserialize);

    } else if (response is CloseSinkResponse) {
      _closeSink(response.id);

    } else if (response is StaleRatioResponse) {
      _complete<double>(response.id, response.staleRatio);

    } else if (response is NeedsCompactionResponse) {
      _complete<bool>(response.id, response.needsCompaction);
    }
  }

  void _complete<T>(String id, T value) {
    Completer<T> completer = _pendingCompleters[id];
    completer.complete(value);
    _pendingCompleters.remove(id);
  }

  void _addToSink<T>(String id, T value) {
    Sink<T> sink = _pendingSinks[id];
    sink.add(value);
  }

  void _closeSink(String id) {
    Sink sink = _pendingSinks[id];
    sink.close();
    _pendingCompleters.remove(id);
  }
}

class _BackendWorker extends IsolateWorker {
  StorageBackend _backend;

  _BackendWorker(SendPort fromWorkerPort) : super(fromWorkerPort);
  
  static _BackendWorker create(SendPort fromWorkerPort) =>
    _BackendWorker(fromWorkerPort);

  void receiveMessage(dynamic message) {
    if (message is ControlRequest) {
      _processControlRequest(message);
    }
  }

  void _processControlRequest(ControlRequest request) {
    if (_backend == null && request is InitBackendRequest) {
      _backend = StorageBackend(request.path);
      _sendRequestConclusion(request);
      return;
    }
    assert(_backend != null);

    if (request is SetValueRequest) {
      _backend.setValue(request.key, request.value);
      _sendRequestConclusion(request);

    } else if (request is AddEntriesRequest) {
      _backend.addEntries(request.entries);
      _sendRequestConclusion(request);

    } else if (request is ValueRequest) {
      sendMessage(ValueResponse(
        request.id,
        _backend.value(request.key),
      ));

    } else if (request is RemoveRequest) {
      sendMessage(RemoveResponse(
        request.id,
        _backend.remove(request.key),
      ));

    } else if (request is OpenUndoGroupRequest) {
      _backend.openUndoGroup();
      _sendRequestConclusion(request);

    } else if (request is CloseUndoGroupRequest) {
      _backend.closeUndoGroup();
      _sendRequestConclusion(request);

    } else if (request is UndoRequest) {
      var response = UndoResponse(
        request.id, 
        _backend.undo(),
      );
      sendMessage(response);

    } else if (request is EntriesRequest) {
      for (StorageDecodeEntry entry in _backend.entries) {
        sendMessage(EntriesResponse(request.id, entry));
      }
      sendMessage(CloseSinkResponse(request.id));

    } else if (request is KeysRequest) {
      for (String key in _backend.keys) {
        sendMessage(KeysResponse(request.id, key));
      }
      sendMessage(CloseSinkResponse(request.id));

    } else if (request is ValuesRequest) {
      for (Deserializer deserialize in _backend.values) {
        sendMessage(ValuesResponse(request.id, deserialize));
      }
      sendMessage(CloseSinkResponse(request.id));

    } else if (request is CompactionRequest) {
      _backend.compaction();
      _sendRequestConclusion(request);

    } else if (request is StaleRatioRequest) {
      sendMessage(StaleRatioResponse(
        request.id, 
        _backend.staleRatio,
      ));

    } else if (request is NeedsCompactionRequest) {
      sendMessage(NeedsCompactionResponse(
        request.id, 
        _backend.needsCompaction,
      ));

    } else if (request is ClearCacheRequest) {
      _backend.clearCache();
      _sendRequestConclusion(request);

    } else if (request is FlushStateRequest) {
      _backend.flushState();
      _sendRequestConclusion(request);

    } else if (request is FlushStateAndCloseRequest) {
      _backend.flushStateAndClose();
      _sendRequestConclusion(request);
    }
  }

  void _sendRequestConclusion(ControlRequest req) {
    sendMessage(RequestConclusion(req.id));
  }
}



