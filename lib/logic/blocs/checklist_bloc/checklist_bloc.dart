import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nomad_mobile/data/models/checklist_item.dart';
import 'package:nomad_mobile/data/repositories/checklist_repository.dart';
import 'checklist_event.dart';
import 'checklist_state.dart';

// Manages the state of checklist items for a trip.
class ChecklistBloc extends Bloc<ChecklistEvent, ChecklistState> {
  final ChecklistRepository repository;

  ChecklistBloc(this.repository) : super(ChecklistLoaded(const [])) {
    on<LoadChecklist>((event, emit) async {
      final isDraft = event.tripId.startsWith('DRAFT') || event.tripId == "0";

      if (isDraft) {
        if (state is! ChecklistLoaded) {
          emit(ChecklistLoaded(const []));
        }
        return;
      }

      emit(ChecklistLoading());
      try {
        final items = await repository.fetchChecklist(event.tripId);
        emit(ChecklistLoaded(items));
      } catch (e) {
        emit(ChecklistError(e.toString()));
      }
    });
    on<AddChecklistItem>((event, emit) {
      if (state is ChecklistLoaded) {
        final currentItems = (state as ChecklistLoaded).items;
        final newItem = ChecklistItem(
          checklistId: -(DateTime.now().millisecondsSinceEpoch),
          tripId: int.tryParse(event.tripId) ?? 0,
          item: event.item,
          status: false,
          position: currentItems.length,
          isCustom: true,
        );
        emit(ChecklistLoaded([...currentItems, newItem]));
      }
    });

    on<UpdateChecklistItem>((event, emit) async {
      if (event.saveToDb) {
        await repository.updateItemText(event.id, event.newItem);
        add(LoadChecklist(event.tripId));
      } else {
        if (state is ChecklistLoaded) {
          final currentItems = (state as ChecklistLoaded).items.map((item) {
            if (item.checklistId == event.id) {
              return ChecklistItem(
                checklistId: item.checklistId,
                tripId: item.tripId,
                item: event.newItem,
                status: item.status,
                position: item.position,
                isCustom: item.isCustom,
              );
            }
            return item;
          }).toList();
          emit(ChecklistLoaded(currentItems));
        }
      }
    });

    on<ToggleChecklistItem>((event, emit) async {
      if (event.saveToDb) {
        await repository.toggleItemStatus(event.id, event.status);
        add(LoadChecklist(event.tripId));
      } else {
        if (state is ChecklistLoaded) {
          final currentItems = (state as ChecklistLoaded).items.map((item) {
            if (item.checklistId == event.id) {
              return ChecklistItem(
                checklistId: item.checklistId,
                tripId: item.tripId,
                item: item.item,
                status: event.status,
                position: item.position,
                isCustom: item.isCustom,
              );
            }
            return item;
          }).toList();
          emit(ChecklistLoaded(currentItems));
        }
      }
    });

    on<ToggleChecklistLock>((event, emit) {
      if (state is ChecklistLoaded) {
        final currentItems = (state as ChecklistLoaded).items.map((item) {
          if (item.checklistId == event.id) {
            return ChecklistItem(
              checklistId: item.checklistId,
              tripId: item.tripId,
              item: item.item,
              status: item.status,
              position: item.position,
              isCustom: !item.isCustom,
            );
          }
          return item;
        }).toList();
        emit(ChecklistLoaded(currentItems));
      }
    });

    on<DeleteChecklistItem>((event, emit) {
      if (state is ChecklistLoaded) {
        final currentItems = List<ChecklistItem>.from(
          (state as ChecklistLoaded).items,
        );
        currentItems.removeWhere((item) => item.checklistId == event.id);
        emit(ChecklistLoaded(currentItems));
      }
    });

    on<SetLocalChecklist>((event, emit) {
      try {
        final items = event.itemsJson.map((json) {
          final map = Map<String, dynamic>.from(json);
          return ChecklistItem.fromJson(map);
        }).toList();

        emit(ChecklistLoaded(List.unmodifiable(items)));
      } catch (e) {
        print("SetLocalChecklist Error: $e");
        emit(ChecklistError("Failed to parse AI checklist: $e"));
      }
    });

    on<ReorderChecklist>((event, emit) {
      if (state is ChecklistLoaded) {
        final List<ChecklistItem> items = List.from(
          (state as ChecklistLoaded).items,
        );

        int nIdx = event.newIndex;
        if (event.oldIndex < nIdx) nIdx -= 1;

        final item = items.removeAt(event.oldIndex);
        items.insert(nIdx, item);

        emit(ChecklistLoaded(items));
      }
    });

    on<ResetChecklistState>((event, emit) {
      emit(ChecklistLoaded(const []));
    });
  }
}
