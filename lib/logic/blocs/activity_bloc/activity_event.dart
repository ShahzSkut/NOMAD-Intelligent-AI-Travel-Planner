import 'package:nomad_mobile/data/models/activity.dart';

// Defines events for the ActivityBloc.
abstract class ActivityEvent {}

class LoadActivities extends ActivityEvent {
  final String tripId;
  final DateTime tripStartDate;

  LoadActivities(this.tripId, this.tripStartDate);
}

class AddActivityEvent extends ActivityEvent {
  final Activity activity;
  final DateTime tripStartDate;
  AddActivityEvent(this.activity, this.tripStartDate);
}

class UpdateActivityEvent extends ActivityEvent {
  final Activity activity;
  final DateTime tripStartDate;
  UpdateActivityEvent(this.activity, this.tripStartDate);
}

class DeleteActivityEvent extends ActivityEvent {
  final int activityId;
  final String tripId;
  final DateTime tripStartDate;
  DeleteActivityEvent(this.activityId, this.tripId, this.tripStartDate);
}

class SetLocalActivities extends ActivityEvent {
  final List<dynamic> activitiesJson;
  final DateTime tripStartDate;
  SetLocalActivities(this.activitiesJson, this.tripStartDate);
}

class ResetActivityState extends ActivityEvent {}