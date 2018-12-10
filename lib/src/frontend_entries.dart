
import 'serialization.dart';
import 'backend_entries.dart';

/// StorageDecodeEntry
/// 
/// Iteration entry.
/// The [key] identifies the key-value-pair.
/// The [value] is the deserializer of the gicen value.
/// [Deserializer.meta.type] helps with identifying the encoded data's type.
/// 
class StorageDecodeEntry {
  final Deserializer value;
  final String key;

  StorageDecodeEntry(this.key, this.value);
}

/// StorageEncodeEntry
/// 
/// Add a collection entry.
/// The [key] identifies the key-value-pair.
/// The [value] is the model to be added.
/// 
class StorageEncodeEntry<T extends Model> {
  final String key;
  final T value;

  StorageEncodeEntry(this.key, this.value);
}



/// UndoAction
/// 
/// Represents an action that was undone.
/// Process this action according to it's [type].
/// The static fields [typeChange] and [typeRemove] 
/// can be used for identification.
/// 
class UndoAction {
  static final int typeChange = UndoRangeItem.typeChange;
  static final int typeRemove = UndoRangeItem.typeRemove;
  final Deserializer value;
  final String key;
  final int type;

  UndoAction(this.type, this.key, this.value);
}