import 'package:equatable/equatable.dart';

// Data model for a single checklist item.
class ChecklistItem extends Equatable {
final int checklistId;
  final int tripId;
  final String item;
  final bool status;
  final int position;
  final bool isCustom;

  const ChecklistItem({
    required this.checklistId,
    required this.tripId,
    required this.item,
    required this.status,
    this.position = 0,
    required this.isCustom,
  });

  factory ChecklistItem.fromJson(Map<String, dynamic> json) {
    return ChecklistItem(
      checklistId: _parseToInt(json['checklist_id']) ?? 
          (DateTime.now().millisecondsSinceEpoch % 2147483647),
      tripId: _parseToInt(json['trip_id']) ?? 0,
      item: json['item'] ?? '',
      status: json['status'] as bool? ?? false,
      position: _parseToInt(json['position']) ?? 0,
      isCustom: json['is_custom'] as bool? ?? false,
    );
  }

static int? _parseToInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is String) return int.tryParse(value);
  return null;
}

  Map<String, dynamic> toJson() {
    return {
      'trip_id': tripId,
      'item': item,
      'status': status,
      'position': position,
      'is_custom': isCustom,
    };
  }

  @override
  List<Object?> get props => [checklistId, tripId, item, status, position, isCustom];
}