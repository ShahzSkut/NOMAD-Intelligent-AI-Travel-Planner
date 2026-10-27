import 'dart:async';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:nomad_mobile/data/models/trip.dart';
import 'package:nomad_mobile/data/models/activity.dart';
import 'package:nomad_mobile/core/utils/status_helper.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  static final StreamController<String> _tripNavigationStream =
      StreamController<String>.broadcast();
  Stream<String> get tripNavigationStream => _tripNavigationStream.stream;

  Future<void> initialize() async {
    await AwesomeNotifications().initialize('resource://mipmap/launcher_icon', [
      NotificationChannel(
        channelGroupKey: 'basic_channel_group',
        channelKey: 'trip_reminders',
        channelName: 'Trip Reminders',
        channelDescription: 'Reminders for trips and activities',
        defaultColor: const Color(0xFF2196F3),
        ledColor: Colors.white,
        importance: NotificationImportance.Max,
        channelShowBadge: true,
      ),
    ], debug: true);

    // 1. Missing Action Listeners: Required for callbacks to work
    await AwesomeNotifications().setListeners(
      onActionReceivedMethod: onActionReceivedMethod,
      onNotificationCreatedMethod: onNotificationCreatedMethod,
      onNotificationDisplayedMethod: onNotificationDisplayedMethod,
      onDismissActionReceivedMethod: onDismissActionReceivedMethod,
    );
  }

  /// Use this method to detect when a new notification or a schedule is created
  @pragma("vm:entry-point")
  static Future<void> onNotificationCreatedMethod(
    ReceivedNotification receivedNotification,
  ) async {}

  /// Use this method to detect every time that a new notification is displayed
  @pragma("vm:entry-point")
  static Future<void> onNotificationDisplayedMethod(
    ReceivedNotification receivedNotification,
  ) async {}

  /// Use this method to detect if the user dismissed a notification
  @pragma("vm:entry-point")
  static Future<void> onDismissActionReceivedMethod(
    ReceivedAction receivedAction,
  ) async {}

  /// Use this method to detect when the user taps on a notification or action button
  @pragma("vm:entry-point")
  static Future<void> onActionReceivedMethod(
    ReceivedAction receivedAction,
  ) async {
    final tripId = receivedAction.payload?['tripId'];
    if (tripId != null) {
      _tripNavigationStream.add(tripId);
    }
  }

  Future<void> requestPermissions() async {
    // 2. Precise Alarms Permission: Explicitly request PreciseAlarms for Android 12+
    await AwesomeNotifications().requestPermissionToSendNotifications(
      permissions: [
        NotificationPermission.Alert,
        NotificationPermission.Sound,
        NotificationPermission.Badge,
        NotificationPermission.Vibration,
        NotificationPermission.Light,
        NotificationPermission.PreciseAlarms,
      ],
    );
  }

  Future<void> scheduleTripReminders(Trip trip) async {
    final tripId = int.tryParse(trip.tripId) ?? trip.tripId.hashCode;
    final startDate = trip.startDate;
    final now = DateTime.now();

    // 1 week before
    final weekBefore = startDate.subtract(const Duration(days: 7));
    if (weekBefore.isAfter(now)) {
      await _schedule(
        id: _generateId(tripId, 1),
        title: 'Trip Reminder: ${trip.destination}',
        body: 'Your trip to ${trip.destination} is in 1 week!',
        scheduledDate: weekBefore,
        payload: {'tripId': trip.tripId},
      );
    }

    // 2 days before
    final twoDaysBefore = startDate.subtract(const Duration(days: 2));
    if (twoDaysBefore.isAfter(now)) {
      await _schedule(
        id: _generateId(tripId, 2),
        title: 'Trip Reminder: ${trip.destination}',
        body: 'Get ready! Your trip to ${trip.destination} starts in 2 days.',
        scheduledDate: twoDaysBefore,
        payload: {'tripId': trip.tripId},
      );
    }

    // On the day (9 AM)
    final dayOf = DateTime(startDate.year, startDate.month, startDate.day, 9);
    if (dayOf.isAfter(now)) {
      await _schedule(
        id: _generateId(tripId, 3),
        title: 'Trip Day: ${trip.destination}',
        body: 'Your trip to ${trip.destination} starts today! Have fun!',
        scheduledDate: dayOf,
        payload: {'tripId': trip.tripId},
      );
    }
  }

  Future<void> scheduleActivityReminders(
    Activity activity,
    DateTime tripStartDate,
    String tripName,
  ) async {
    final activityId = activity.activityId;
    if (activity.time == null) return;

    try {
      final actDateTime = activityDateTime(
        tripStartDate,
        activity.dayNumber,
        activity.time!,
      );
      final now = DateTime.now();

      // 30 mins before
      final thirtyBefore = actDateTime.subtract(const Duration(minutes: 30));
      if (thirtyBefore.isAfter(now)) {
        await _schedule(
          id: _generateId(activityId, 4),
          title: tripName,
          body:
              '${activity.name} starts in 30 mins at ${activity.locationName ?? "designated location"}.',
          scheduledDate: thirtyBefore,
          payload: {'tripId': activity.tripId.toString()},
        );
      }

      // At start time
      if (actDateTime.isAfter(now)) {
        await _schedule(
          id: _generateId(activityId, 5),
          title: tripName,
          body: 'It\'s time for ${activity.name}!',
          scheduledDate: actDateTime,
          payload: {'tripId': activity.tripId.toString()},
        );
      }
    } catch (e) {
      print("Error scheduling activity reminder: $e");
    }
  }

  int _generateId(int baseId, int suffix) {
    // 3. Verification of _generateId: Ensure it fits in a positive 32-bit integer
    // & 0x7FFFFFFF masks the sign bit to ensure it's always positive and within range
    return '${baseId}_$suffix'.hashCode & 0x7FFFFFFF;
  }

  Future<void> _schedule({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    Map<String, String>? payload,
  }) async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: id,
        channelKey: 'trip_reminders',
        title: title,
        body: body,
        payload: payload,
        largeIcon: 'asset://assets/images/Nomad_Logo.png',
        notificationLayout: NotificationLayout.Default,
        wakeUpScreen: true,
      ),
      schedule: NotificationCalendar.fromDate(
        date: scheduledDate,
        preciseAlarm: true, // Critical for exact timing
        allowWhileIdle: true, // Allows notification even in Doze mode
      ),
    );
  }
}
