import 'package:equatable/equatable.dart';

abstract class TripEvent extends Equatable {
  const TripEvent();

  @override
  List<Object> get props => [];
}

class LoadTrips extends TripEvent {
  final String userId;

  const LoadTrips(this.userId);

  @override
  List<Object> get props => [userId];
}

class SearchTrips extends TripEvent {
  final String userId;
  final String keyword;

  const SearchTrips(this.userId, this.keyword);

  @override
  List<Object> get props => [userId, keyword];
}

class FilterTrips extends TripEvent {
  final String userId;
  final String status;

  const FilterTrips(this.userId, this.status);

  @override
  List<Object> get props => [userId, status];
}

class DeleteTrip extends TripEvent {
  final String tripId;
  final String userId;

  const DeleteTrip(this.tripId, this.userId);

  @override
  List<Object> get props => [tripId, userId];
}

class ImportTrip extends TripEvent {
  final String code;
  final String userId;

  const ImportTrip(this.code, this.userId);

  @override
  List<Object> get props => [code, userId];
}

class ResetTripState extends TripEvent {}
