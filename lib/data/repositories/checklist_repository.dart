import 'package:nomad_mobile/core/services/supabase_service.dart';
import 'package:nomad_mobile/data/models/checklist_item.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Manages CRUD operations for checklist items in the database.
class ChecklistRepository {
  final SupabaseClient _client;

  ChecklistRepository(SupabaseService supabaseService)
    : _client = supabaseService.client;

  Future<List<ChecklistItem>> fetchChecklist(String tripId) async {
    final response = await _client
        .from('CHECKLIST')
        .select()
        .eq('trip_id', tripId)
        .order('position', ascending: true);
    return response
        .map<ChecklistItem>((e) => ChecklistItem.fromJson(e))
        .toList();
  }

  Future<void> updateItemOrder(List<ChecklistItem> items) async {
    final updates = items.asMap().entries.map((entry) {
      int idx = entry.key;
      ChecklistItem item = entry.value;
      return {
        'checklist_id': item.checklistId,
        'trip_id': item.tripId,
        'item': item.item,
        'status': item.status,
        'position': idx,
        'is_custom': item.isCustom,
      };
    }).toList();

    await _client.from('CHECKLIST').upsert(updates);
  }

  Future<void> toggleItemStatus(int checklistId, bool isDone) async {
    await _client
        .from('CHECKLIST')
        .update({'status': isDone})
        .eq('checklist_id', checklistId);
  }

  Future<void> updateItemText(int checklistId, String newItem) async {
    await _client
        .from('CHECKLIST')
        .update({'item': newItem})
        .eq('checklist_id', checklistId);
  }

  Future<void> addItem(ChecklistItem item) async {
    await _client.from('CHECKLIST').insert(item.toJson());
  }

  Future<void> deleteItem(int checklistId) async {
    await _client.from('CHECKLIST').delete().eq('checklist_id', checklistId);
  }

  Future<void> deleteAllChecklistByTrip(String tripId) async {
    await _client.from('CHECKLIST').delete().eq('trip_id', tripId);
  }

  Future<void> addChecklistItems(List<ChecklistItem> items, int tripId) async {
    final data = items.asMap().entries.map((entry) {
      final index = entry.key;
      final item = entry.value;
      final json = item.toJson();
      json['trip_id'] = tripId;
      json.remove('checklist_id');
      json['position'] = index;
      return json;
    }).toList();
    await _client.from('CHECKLIST').insert(data);
  }
}
