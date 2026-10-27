// Defines events for the ChecklistBloc.
abstract class ChecklistEvent {}

class LoadChecklist extends ChecklistEvent {
  final String tripId;
  LoadChecklist(this.tripId);
}

class AddChecklistItem extends ChecklistEvent {
  final String item;
  final String tripId;
  AddChecklistItem(this.item, this.tripId);
}

class UpdateChecklistItem extends ChecklistEvent {
  final int id;
  final String newItem;
  final String tripId;
  final bool saveToDb;
  UpdateChecklistItem(
    this.id,
    this.newItem,
    this.tripId, {
    this.saveToDb = true,
  });
}

class ToggleChecklistItem extends ChecklistEvent {
  final int id;
  final bool status;
  final String tripId;
  final bool saveToDb;
  ToggleChecklistItem(
    this.id,
    this.status,
    this.tripId, {
    this.saveToDb = true,
  });
}

class ToggleChecklistLock extends ChecklistEvent {
  final int id;
  final String tripId;
  ToggleChecklistLock(this.id, this.tripId);
}

class ReorderChecklist extends ChecklistEvent {
  final int oldIndex;
  final int newIndex;
  final String tripId;
  ReorderChecklist(this.oldIndex, this.newIndex, this.tripId);
}

class DeleteChecklistItem extends ChecklistEvent {
  final int id;
  final String tripId;
  DeleteChecklistItem(this.id, this.tripId);
}

class SetLocalChecklist extends ChecklistEvent {
  final List<dynamic> itemsJson;
  SetLocalChecklist(this.itemsJson);
}

class ResetChecklistState extends ChecklistEvent {}
