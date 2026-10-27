import 'package:equatable/equatable.dart';

// Data model for a single activity within a trip.
class Activity extends Equatable {
  final int activityId;
  final int tripId;
  final String name;
  final int dayNumber;
  final String? locationName;
  final double? latitude;
  final double? longitude;
  final bool isCustom;
  final String? time;
  final String status;

  const Activity({
    required this.activityId,
    required this.tripId,
    required this.name,
    required this.dayNumber,
    this.locationName,
    this.time,
    this.latitude,
    this.longitude,
    required this.isCustom,
    required this.status,
  });

  Activity copyWith({
    int? activityId,
    int? tripId,
    String? name,
    String? locationName,
    int? dayNumber,
    String? status,
    String? time,
    bool? isCustom,
    double? latitude,
    double? longitude,
  }) {
    return Activity(
      activityId: activityId ?? this.activityId,
      tripId: tripId ?? this.tripId,
      name: name ?? this.name,
      locationName: locationName ?? this.locationName,
      dayNumber: dayNumber ?? this.dayNumber,
      status: status ?? this.status,
      time: time ?? this.time,
      isCustom: isCustom ?? this.isCustom,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }

  factory Activity.fromJson(Map<String, dynamic> json) {
    int safeParseId(dynamic value) {
      if (value is int) return value;
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    return Activity(
      activityId: json['activity_id'] != null 
          ? safeParseId(json['activity_id']) 
          : -DateTime.now().microsecondsSinceEpoch,
      tripId: safeParseId(json['trip_id']),
      dayNumber: json['day_number'] ?? 1,
      name: json['name'] ?? '',
      locationName: json['location_name'],
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      isCustom: json['is_custom'] ?? false,
      time: json['time'],
      status: json['status'] ?? 'Planned',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'trip_id': tripId,
      'name': name,
      'day_number': dayNumber,
      'location_name': locationName,
      'latitude': latitude,
      'longitude': longitude,
      'is_custom': isCustom,
      'time': time,
      'status': status,
    };
  }

  @override
  List<Object?> get props => [
        activityId,
        tripId,
        name,
        status,
        time,
        dayNumber,
        locationName,
        isCustom
      ];
}