import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nomad_mobile/core/services/google_api_service.dart';
import 'package:nomad_mobile/core/utils/network_utils.dart';
import 'package:nomad_mobile/core/utils/status_helper.dart';
import 'package:nomad_mobile/data/models/activity.dart';
import 'package:nomad_mobile/data/models/trip.dart';
import 'package:nomad_mobile/data/repositories/trip_repository.dart';
import 'trip_event.dart';
import 'trip_state.dart';

// Manages the state of trips, including loading, searching, and filtering.
class TripBloc extends Bloc<TripEvent, TripState> {
  final TripRepository repository;

  TripBloc(this.repository) : super(TripInitial()) {
    on<LoadTrips>(_loadTrips);
    on<SearchTrips>(_searchTrips);
    on<FilterTrips>(_filterTrips);
    on<DeleteTrip>(_onDeleteTrip);
    on<ImportTrip>(_onImportTrip);
    on<ResetTripState>(_onResetState);
  }

  void _onResetState(ResetTripState event, Emitter<TripState> emit) {
    emit(TripInitial());
  }

  final GoogleApiService googleApi = GoogleApiService();

  Future<void> _loadTrips(LoadTrips event, Emitter<TripState> emit) async {
    emit(TripLoading());
    if (!await NetworkUtils.hasInternet()) {
      emit(
        const TripError("No internet connection. Please check your network."),
      );
      return;
    }

    try {
      final trips = await repository.fetchTrips(event.userId);
      final newState = await _processTripsWithStats(trips, event.userId);
      emit(newState);
    } catch (e) {
      print('TripBloc Error: $e');
      emit(TripError(e.toString()));
    }
  }

  Future<TripLoaded> _processTripsWithStats(
    List<Trip> originalTrips,
    String userId,
  ) async {
    final allActivitiesRaw = await repository.fetchTripStats(userId);

    List<Trip> processedTrips = [];
    Map<String, double> progressMap = {};
    Map<String, int> countMap = {};

    for (var trip in originalTrips) {
      Trip currentTrip = trip;

      final tripStatus = computeTripStatus(
        currentTrip.startDate,
        currentTrip.endDate,
      );

      final newStatus =
          tripStatus.name[0].toUpperCase() + tripStatus.name.substring(1);

      if (currentTrip.status != newStatus) {
        currentTrip = currentTrip.copyWith(status: newStatus);
        repository.updateTrip(currentTrip);
      }

      final tripActivities = allActivitiesRaw
          .where((a) => a['trip_id'].toString() == currentTrip.tripId)
          .toList();
      tripActivities.sort((a, b) {
        int dayCmp = (a['day_number'] as int).compareTo(b['day_number'] as int);
        if (dayCmp != 0) return dayCmp;
        try {
          final tA = activityDateTime(
            currentTrip.startDate,
            a['day_number'],
            a['time'] ?? "",
          );
          final tB = activityDateTime(
            currentTrip.startDate,
            b['day_number'],
            b['time'] ?? "",
          );
          return tA.compareTo(tB);
        } catch (_) {
          return (a['time']?.toString() ?? "").compareTo(
            b['time']?.toString() ?? "",
          );
        }
      });

      int total = tripActivities.length;
      int completedCount = 0;

      for (int i = 0; i < tripActivities.length; i++) {
        final currentMap = tripActivities[i];
        final nextMap = (i + 1 < tripActivities.length)
            ? tripActivities[i + 1]
            : null;

        final currentAct = Activity(
          activityId: currentMap['activity_id'],
          tripId: int.parse(currentTrip.tripId),
          name: currentMap['name'] ?? '',
          dayNumber: currentMap['day_number'],
          time: currentMap['time'],
          status: currentMap['status'] ?? 'Planned',
          isCustom: currentMap['is_custom'] ?? false,
        );

        Activity? nextAct;
        if (nextMap != null) {
          nextAct = Activity(
            activityId: nextMap['activity_id'],
            tripId: int.parse(currentTrip.tripId),
            name: nextMap['name'] ?? '',
            dayNumber: nextMap['day_number'],
            time: nextMap['time'],
            status: nextMap['status'] ?? 'Planned',
            isCustom: nextMap['is_custom'] ?? false,
          );
        }

        final realStatus = computeActivityStatus(
          current: currentAct,
          next: nextAct,
          tripStart: currentTrip.startDate,
        );

        if (realStatus == 'Completed') {
          completedCount++;
        }
      }

      countMap[currentTrip.tripId] = total;
      progressMap[currentTrip.tripId] = total > 0
          ? (completedCount / total) * 100
          : 0.0;

      if (currentTrip.tripImageUrl == null ||
          currentTrip.tripImageUrl!.isEmpty) {
        final firstLocation = await repository.getFirstActivityLocation(
          currentTrip.tripId,
        );
        final queryLocation = firstLocation ?? currentTrip.destination;
        final fetchedUrl = await googleApi.getPlacePhotoUrl(queryLocation);

        if (fetchedUrl != null) {
          repository.updateTripImageUrl(currentTrip.tripId, fetchedUrl);
          currentTrip = currentTrip.copyWith(tripImageUrl: fetchedUrl);
        }
      }

      processedTrips.add(currentTrip);
    }

    return TripLoaded(
      processedTrips,
      userId: userId,
      tripProgress: progressMap,
      tripActivityCounts: countMap,
    );
  }

  Future<void> _searchTrips(SearchTrips event, Emitter<TripState> emit) async {
    emit(TripLoading());
    if (!await NetworkUtils.hasInternet()) {
      emit(const TripError("No internet connection."));
      return;
    }

    try {
      final trips = await repository.searchTrips(event.userId, event.keyword);
      final newState = await _processTripsWithStats(trips, event.userId);
      emit(newState);
    } catch (e) {
      emit(TripError(e.toString()));
    }
  }

  Future<void> _filterTrips(FilterTrips event, Emitter<TripState> emit) async {
    emit(TripLoading());
    if (!await NetworkUtils.hasInternet()) {
      emit(const TripError("No internet connection."));
      return;
    }

    try {
      final trips = await repository.filterTrips(event.userId, event.status);
      final newState = await _processTripsWithStats(trips, event.userId);
      emit(newState);
    } catch (e) {
      emit(TripError(e.toString()));
    }
  }

  Future<void> _onDeleteTrip(DeleteTrip event, Emitter<TripState> emit) async {
    try {
      if (!await NetworkUtils.hasInternet()) {
        emit(const TripError("No internet connection. Cannot delete trip."));
        return;
      }

      await repository.deleteTrip(event.tripId);
      add(LoadTrips(event.userId));
    } catch (e) {
      emit(TripError("Failed to delete trip: ${e.toString()}"));
    }
  }

  Future<void> _onImportTrip(ImportTrip event, Emitter<TripState> emit) async {
    emit(TripLoading());
    if (!await NetworkUtils.hasInternet()) {
      emit(const TripError("No internet connection. Cannot import trip."));
      return;
    }

    try {
      await repository.importTrip(event.code, event.userId);
      add(LoadTrips(event.userId));
    } catch (e) {
      emit(TripError("Failed to import trip: ${e.toString()}"));
    }
  }
}
