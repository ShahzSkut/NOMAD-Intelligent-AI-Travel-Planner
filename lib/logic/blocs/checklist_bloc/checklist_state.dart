import 'package:nomad_mobile/data/models/checklist_item.dart';

// Represents the state for the ChecklistBloc.
abstract class ChecklistState {}

class ChecklistLoading extends ChecklistState {}

class ChecklistLoaded extends ChecklistState {
  final List<ChecklistItem> items;
  ChecklistLoaded(this.items);
}

class ChecklistError extends ChecklistState {
  final String message;
  ChecklistError(this.message);
}