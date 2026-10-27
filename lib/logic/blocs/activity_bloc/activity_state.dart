import 'package:nomad_mobile/data/models/activity.dart';

// Represents the state for the ActivityBloc.
class ActivityState {
  final List<Activity> activities;
  final bool isLoading;
  final double totalCost;
  final Map<String, double> categoryCosts;

  const ActivityState({
    this.activities = const [],
    this.isLoading = false,
    this.totalCost = 0.0,
    this.categoryCosts = const {},
  });

  ActivityState copyWith({
    List<Activity>? activities,
    bool? isLoading,
    double? totalCost,
    Map<String, double>? categoryCosts,
  }) {
    return ActivityState(
      activities: activities ?? this.activities,
      isLoading: isLoading ?? this.isLoading,
      totalCost: totalCost ?? this.totalCost,
      categoryCosts: categoryCosts ?? this.categoryCosts,
    );
  }
}