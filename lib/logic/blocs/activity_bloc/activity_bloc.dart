import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nomad_mobile/core/utils/status_helper.dart';
import 'package:nomad_mobile/data/models/activity.dart';
import 'package:nomad_mobile/data/repositories/activity_repository.dart';
import 'package:nomad_mobile/logic/blocs/activity_bloc/activity_event.dart';
import 'package:nomad_mobile/logic/blocs/activity_bloc/activity_state.dart';

// Manages the state of activities for a trip.
class ActivityBloc extends Bloc<ActivityEvent, ActivityState> {
  final ActivityRepository repository;

  ActivityBloc(this.repository) : super(const ActivityState()) {
    on<LoadActivities>((event, emit) async {
      if (state.activities.isEmpty) {
        emit(state.copyWith(isLoading: true));
      }

      try {
        List<Activity> activities;
        if (int.tryParse(event.tripId) != null) {
          activities = await repository.fetchActivitiesByTrip(event.tripId);
        } else {
          activities = state.activities;
        }
        _calculateAndEmit(activities, emit, event.tripStartDate);
      } catch (e) {
        emit(state.copyWith(isLoading: false));
      }
    });

    on<AddActivityEvent>((event, emit) {
      final updatedList = List<Activity>.from(state.activities)
        ..add(event.activity);
      _calculateAndEmit(updatedList, emit, event.tripStartDate);
    });

    on<UpdateActivityEvent>((event, emit) {
      final updatedList = state.activities.map((a) {
        return a.activityId == event.activity.activityId ? event.activity : a;
      }).toList();
      _calculateAndEmit(updatedList, emit, event.tripStartDate);
    });

    on<DeleteActivityEvent>((event, emit) {
      final updatedList = state.activities
          .where((a) => a.activityId != event.activityId)
          .toList();

      _calculateAndEmit(updatedList, emit, event.tripStartDate);
    });

    on<SetLocalActivities>((event, emit) {
      final list = event.activitiesJson
          .map((json) => Activity.fromJson(Map<String, dynamic>.from(json)))
          .toList();

      _calculateAndEmit(list, emit, event.tripStartDate);
    });

    on<ResetActivityState>((event, emit) {
      emit(const ActivityState()); // Reset to default/initial state
    });
  }

  void _calculateAndEmit(
    List<Activity> list,
    Emitter<ActivityState> emit,
    DateTime tripStartDate,
  ) {
    final sortedList = List<Activity>.from(list);
    sortedList.sort((a, b) {
      if (a.dayNumber != b.dayNumber) {
        return a.dayNumber.compareTo(b.dayNumber);
      }
      try {
        final tA = activityDateTime(tripStartDate, a.dayNumber, a.time ?? "");
        final tB = activityDateTime(tripStartDate, b.dayNumber, b.time ?? "");
        return tA.compareTo(tB);
      } catch (_) {
        return 0;
      }
    });

    // Apply auto-start logic to ensure the first activity of the day is Ongoing if needed
    List<Activity> processedActivities = List.from(sortedList);
    final autoStarted = checkAutoStart(processedActivities, tripStartDate);
    if (autoStarted != null) {
      processedActivities = autoStarted;
    }

    emit(
      ActivityState(
        activities: processedActivities,
        isLoading: false,
        totalCost: 0,
        categoryCosts: const {},
      ),
    );
  }
}
