import 'package:equatable/equatable.dart';
import 'package:nomad_mobile/data/models/trip.dart';

abstract class TripState extends Equatable {
  const TripState();

  @override
  List<Object> get props => [];
}

class TripInitial extends TripState {}

class TripLoading extends TripState {}

class TripLoaded extends TripState {
  final List<Trip> trips;
  final String userId;

  final Map<String, double> tripProgress;
  final Map<String, int> tripActivityCounts;

  const TripLoaded(
    this.trips, {
    required this.userId,
    this.tripProgress = const {},
    this.tripActivityCounts = const {},
  });

  @override
  List<Object> get props => [trips, userId, tripProgress, tripActivityCounts];
}

class TripError extends TripState {
  final String message;

  const TripError(this.message);

  @override
  List<Object> get props => [message];
}
