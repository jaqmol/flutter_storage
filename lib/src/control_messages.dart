import 'serialization.dart';
import 'storage_entries.dart';

abstract class ControlRequest {
  String get id;
}
abstract class ControlResponse {
  String get id;
}

// All Requests that don't have a dedicated Response object
// must respond with a RequestConclusion!
class RequestConclusion extends ControlResponse {
  final String id;

  RequestConclusion(this.id);
}

class CloseSinkResponse extends ControlResponse {
  final String id;

  CloseSinkResponse(this.id);
}

class InitBackendRequest extends ControlRequest {
  final String id;
  final String path;

  InitBackendRequest(this.id, this.path);
}

class SetValueRequest extends ControlRequest {
  final String id;
  final String key;
  final Model value;

  SetValueRequest(this.id, this.key, this.value);
}

class AddEntriesRequest extends ControlRequest {
  final String id;
  final Iterable<StorageEncodeEntry> entries;

  AddEntriesRequest(this.id, this.entries);
}

class RemoveRequest extends ControlRequest {
  final String id;
  final String key;

  RemoveRequest(this.id, this.key);
}
class RemoveResponse extends ControlResponse {
  final String id;
  final Deserializer value;

  RemoveResponse(this.id, this.value);
}

class ValueRequest extends ControlRequest {
  final String id;
  final String key;

  ValueRequest(this.id, this.key);
}
class ValueResponse extends ControlResponse {
  final String id;
  final Deserializer value;

  ValueResponse(this.id, this.value);
}

class OpenUndoGroupRequest extends ControlRequest {
  final String id;

  OpenUndoGroupRequest(this.id);
}
class CloseUndoGroupRequest extends ControlRequest {
  final String id;

  CloseUndoGroupRequest(this.id);
}

class UndoRequest extends ControlRequest {
  final String id;
  
  UndoRequest(this.id);
}
class UndoResponse extends ControlResponse {
  final String id;
  final List<UndoAction> actions;
  
  UndoResponse(this.id, this.actions);
}


class EntriesRequest extends ControlRequest {
  final String id;

  EntriesRequest(this.id);
}
class EntriesResponse extends ControlResponse {
  final String id;
  final StorageDecodeEntry entry;

  EntriesResponse(this.id, this.entry);
}

class KeysRequest extends ControlRequest {
  final String id;

  KeysRequest(this.id);
}
class KeysResponse extends ControlResponse {
  final String id;
  final String key;

  KeysResponse(this.id, this.key);
}

class ValuesRequest extends ControlRequest {
  final String id;
  bool expectsResponse = true;

  ValuesRequest(this.id);
}
class ValuesResponse extends ControlResponse {
  final String id;
  final Deserializer deserialize;

  ValuesResponse(this.id, this.deserialize);
}

class CompactionRequest extends ControlRequest {
  final String id;

  CompactionRequest(this.id);
}

class StaleRatioRequest extends ControlRequest {
  final String id;

  StaleRatioRequest(this.id);
}
class StaleRatioResponse extends ControlResponse {
  final String id;
  final double staleRatio;

  StaleRatioResponse(this.id, this.staleRatio);
}

class NeedsCompactionRequest extends ControlRequest {
  final String id;

  NeedsCompactionRequest(this.id);
}
class NeedsCompactionResponse extends ControlResponse {
  final String id;
  final bool needsCompaction;

  NeedsCompactionResponse(this.id, this.needsCompaction);
}

class ClearCacheRequest extends ControlRequest {
  final String id;

  ClearCacheRequest(this.id);
}

class FlushStateRequest extends ControlRequest {
  final String id;

  FlushStateRequest(this.id);
}

class FlushStateAndCloseRequest extends ControlRequest {
  final String id;

  FlushStateAndCloseRequest(this.id);
}
