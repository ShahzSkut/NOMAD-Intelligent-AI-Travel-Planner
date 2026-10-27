import 'package:equatable/equatable.dart';

// Data model for a trip.
class Trip extends Equatable {
  final String tripId;
  final String userId;
  final String? name;
  final String? code;
  final String? locationFrom;
  final String destination;
  final DateTime startDate;
  final DateTime endDate;
  final int? durationDays;
  final String? tripPurpose;
  final int? numTravelers;
  final double? budgetMin;
  final double? budgetMax;
  final String? travelPace;
  final String? accommodationType;
  final String? transportType;
  final double? budgetTotal;
  final String? status;
  final String? tripImageUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Trip({
    required this.tripId,
    required this.userId,
    this.name,
    this.code,
    this.locationFrom,
    required this.destination,
    required this.startDate,
    required this.endDate,
    this.durationDays,
    this.tripPurpose,
    this.numTravelers,
    this.budgetMin,
    this.budgetMax,
    this.travelPace,
    this.accommodationType,
    this.transportType,
    this.budgetTotal,
    this.status,
    this.tripImageUrl,
    this.createdAt,
    this.updatedAt,
  });

  factory Trip.fromJson(Map<String, dynamic> json) {
    return Trip(
      tripId: _parseToInt(json['trip_id']).toString(),
      userId: _parseToInt(json['user_id']).toString(),
      name: json['name'] as String?,
      code: json['code'] as String?,
      locationFrom: json['location_from'] as String?,
      destination: json['destination'] as String,
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: DateTime.parse(json['end_date'] as String),
      durationDays: json['duration'] as int?,
      tripPurpose: json['trip_purpose'] as String?,
      numTravelers: json['num_travelers'] as int?,
      budgetMin: (json['budget_min'] as num?)?.toDouble(),
      budgetMax: (json['budget_max'] as num?)?.toDouble(),
      travelPace: json['travel_pace'] as String?,
      accommodationType: json['accommodation_type'] as String?,
      transportType: json['transport_type'] as String?,
      budgetTotal: (json['budget_total'] as num?)?.toDouble(),
      status: json['status'] as String?,
      tripImageUrl: json['trip_image_url'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  static int _parseToInt(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.parse(value);
    return 0;
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'name': name,
      'code': code,
      'location_from': locationFrom,
      'destination': destination,
      'start_date': startDate.toIso8601String().substring(0, 10),
      'end_date': endDate.toIso8601String().substring(0, 10),
      'duration': durationDays,
      'trip_purpose': tripPurpose,
      'num_travelers': numTravelers,
      'budget_min': budgetMin,
      'budget_max': budgetMax,
      'travel_pace': travelPace,
      'accommodation_type': accommodationType,
      'transport_type': transportType,
      'budget_total': budgetTotal,
      'status': status,
      'trip_image_url': tripImageUrl,
    };
  }

  Trip copyWith({
    String? tripId,
    String? userId,
    String? name,
    String? code,
    String? locationFrom,
    String? destination,
    DateTime? startDate,
    DateTime? endDate,
    int? durationDays,
    String? tripPurpose,
    int? numTravelers,
    double? budgetMin,
    double? budgetMax,
    String? travelPace,
    String? accommodationType,
    String? transportType,
    double? budgetTotal,
    String? status,
    String? tripImageUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Trip(
      tripId: tripId ?? this.tripId,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      code: code ?? this.code,
      locationFrom: locationFrom ?? this.locationFrom,
      destination: destination ?? this.destination,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      durationDays: durationDays ?? this.durationDays,
      tripPurpose: tripPurpose ?? this.tripPurpose,
      numTravelers: numTravelers ?? this.numTravelers,
      budgetMin: budgetMin ?? this.budgetMin,
      budgetMax: budgetMax ?? this.budgetMax,
      travelPace: travelPace ?? this.travelPace,
      accommodationType: accommodationType ?? this.accommodationType,
      transportType: transportType ?? this.transportType,
      budgetTotal: budgetTotal ?? this.budgetTotal,
      status: status ?? this.status,
      tripImageUrl: tripImageUrl ?? this.tripImageUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  String get calculatedStatus {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final start = DateTime(startDate.year, startDate.month, startDate.day);
    final end = DateTime(endDate.year, endDate.month, endDate.day);

    if (end.isBefore(today)) return 'Completed';
    if (start.isAfter(today)) return 'Planned';
    return 'Ongoing';
  }

  bool get needsStatusUpdate => status != calculatedStatus;

  Trip withCalculatedStatus() => copyWith(status: calculatedStatus);

  String get duration {
    if (durationDays != null) return '$durationDays Days';
    final diff = endDate.difference(startDate).inDays;
    return '${diff + 1} Days';
  }

  double get cost => budgetTotal ?? 0.0;

  @override
  List<Object?> get props => [
    tripId,
    userId,
    name,
    code,
    locationFrom,
    destination,
    startDate,
    endDate,
    durationDays,
    budgetTotal,
    status,
    tripImageUrl,
  ];
}
