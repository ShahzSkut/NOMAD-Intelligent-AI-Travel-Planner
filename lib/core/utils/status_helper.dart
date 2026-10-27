import 'package:intl/intl.dart';
import 'package:nomad_mobile/data/models/activity.dart';

// Helper functions to compute trip and activity statuses based on time.
enum TripStatus { planned, ongoing, completed }

TripStatus computeTripStatus(DateTime start, DateTime end) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final startDate = DateTime(start.year, start.month, start.day);
  final endDate = DateTime(end.year, end.month, end.day);

  if (endDate.isBefore(today)) return TripStatus.completed;
  if (startDate.isAfter(today)) return TripStatus.planned;
  return TripStatus.ongoing;
}

String computeActivityStatus({
  required Activity current,
  required Activity? next,
  required DateTime tripStart,
}) {
  final now = DateTime.now();
  try {
    final currentDt = activityDateTime(
      tripStart,
      current.dayNumber,
      current.time ?? "00:00 AM",
    );

    if (now.isBefore(currentDt)) {
      return 'Planned';
    }

    if (next != null) {
      final nextDt = activityDateTime(
        tripStart,
        next.dayNumber,
        next.time ?? "00:00 AM",
      );
      if (now.isAfter(nextDt) || now.isAtSameMomentAs(nextDt)) {
        return 'Completed';
      }
    } else {
      // For the last activity, we can keep it as Ongoing until the day ends
      final endOfDay = DateTime(
        currentDt.year,
        currentDt.month,
        currentDt.day,
        23,
        59,
        59,
      );
      if (now.isAfter(endOfDay)) return 'Completed';
    }

    return 'Ongoing';
  } catch (e) {
    return 'Planned';
  }
}

List<Activity>? checkAutoStart(
  List<Activity> activities,
  DateTime tripStartDate,
) {
  if (activities.isEmpty) return null;

  final updated = List<Activity>.from(activities);
  bool changed = false;

  for (int i = 0; i < updated.length; i++) {
    final current = updated[i];
    final next = (i + 1 < updated.length) ? updated[i + 1] : null;

    final newStatus = computeActivityStatus(
      current: current,
      next: next,
      tripStart: tripStartDate,
    );

    if (current.status != newStatus) {
      updated[i] = current.copyWith(status: newStatus);
      changed = true;
    }
  }

  return changed ? updated : null;
}

DateTime activityDateTime(DateTime tripStart, int dayNumber, String time) {
  DateTime parsedTime;
  try {
    parsedTime = DateFormat('h:mm a').parse(time);
  } catch (_) {
    // Fallback for 24-hour format (e.g. "14:00")
    parsedTime = DateFormat('HH:mm').parse(time);
  }

  final activityDate = tripStart.add(Duration(days: dayNumber - 1));

  return DateTime(
    activityDate.year,
    activityDate.month,
    activityDate.day,
    parsedTime.hour,
    parsedTime.minute,
  );
}
