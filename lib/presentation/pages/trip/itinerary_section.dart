import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:nomad_mobile/core/constants/app_color.dart';
import 'package:nomad_mobile/data/models/activity.dart';
import 'package:nomad_mobile/data/models/trip.dart';
import 'package:nomad_mobile/logic/blocs/activity_bloc/activity_bloc.dart';
import 'package:nomad_mobile/logic/blocs/activity_bloc/activity_event.dart';
import 'package:nomad_mobile/logic/blocs/activity_bloc/activity_state.dart';
import 'package:nomad_mobile/core/services/google_api_service.dart';

// A section for displaying and managing a trip's daily itinerary.
class ItinerarySection extends StatefulWidget {
  final Trip trip;
  final bool isEditable;
  final Color themeColor;

  const ItinerarySection({
    super.key,
    required this.trip,
    required this.isEditable,
    required this.themeColor,
  });

  @override
  State<ItinerarySection> createState() => ItinerarySectionState();
}

class ItinerarySectionState extends State<ItinerarySection> {
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    if (!widget.isEditable) {
      _startRefreshTimer();
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _startRefreshTimer() {
    _refreshTimer = Timer.periodic(const Duration(minutes: 15), (timer) {
      if (mounted) {
        context.read<ActivityBloc>().add(
          LoadActivities(widget.trip.tripId, widget.trip.startDate),
        );
      }
    });
  }

  int _parseTimeToMinutes(String? timeStr) {
    if (timeStr == null || timeStr.isEmpty) return 0;
    try {
      String cleanedTime = timeStr.trim().toUpperCase();
      final format = DateFormat.jm();
      final dateTime = format.parse(cleanedTime);
      return dateTime.hour * 60 + dateTime.minute;
    } catch (e) {
      try {
        final parts = timeStr.split(':');
        int hour = int.parse(parts[0].replaceAll(RegExp(r'[^0-9]'), ''));
        int minute = int.parse(
          parts[1].split(' ')[0].replaceAll(RegExp(r'[^0-9]'), ''),
        );
        if (timeStr.toUpperCase().contains('PM') && hour < 12) hour += 12;
        if (timeStr.toUpperCase().contains('AM') && hour == 12) hour = 0;
        return hour * 60 + minute;
      } catch (e2) {
        return 0;
      }
    }
  }

  void _showEditDialog(Activity activity) {
    final activityBloc = context.read<ActivityBloc>();
    showDialog(
      context: context,
      builder: (ctx) => BlocProvider.value(
        value: activityBloc,
        child: _AddActivityDialog(
          day: activity.dayNumber,
          trip: widget.trip,
          themeColor: widget.themeColor,
          activityToEdit: activity,
          onSave: (updatedActivity) {
            ctx.read<ActivityBloc>().add(
                  UpdateActivityEvent(updatedActivity, widget.trip.startDate),
                );
          },
        ),
      ),
    );
  }

  void _showAddDialog(int day) {
    if (int.tryParse(widget.trip.tripId) == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please save the trip first to add activities.'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final activityBloc = context.read<ActivityBloc>();
    showDialog(
      context: context,
      builder: (ctx) => BlocProvider.value(
        value: activityBloc,
        child: _AddActivityDialog(
          day: day,
          trip: widget.trip,
          themeColor: widget.themeColor,
          onSave: (newActivity) {
            ctx.read<ActivityBloc>().add(
              AddActivityEvent(newActivity, widget.trip.startDate),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final startFmt = DateFormat('dd MMM yyyy').format(widget.trip.startDate);
    final endFmt = DateFormat('dd MMM yyyy').format(widget.trip.endDate);

    return BlocBuilder<ActivityBloc, ActivityState>(
      builder: (context, state) {
        if (state.isLoading)
          return Center(
            child: CircularProgressIndicator(color: widget.themeColor),
          );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Plan $startFmt - $endFmt',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...List.generate(widget.trip.durationDays ?? 1, (index) {
              final dayNum = index + 1;
              final dayDate = widget.trip.startDate.add(Duration(days: index));
              final isDayPassed =
                  DateTime(dayDate.year, dayDate.month, dayDate.day).isBefore(
                    DateTime(
                      DateTime.now().year,
                      DateTime.now().month,
                      DateTime.now().day,
                    ),
                  );

              final dayActivities = state.activities
                  .where((a) => a.dayNumber == dayNum)
                  .toList();

              int completedCount = isDayPassed
                  ? dayActivities.length
                  : dayActivities.where((a) => a.status == 'Completed').length;

              dayActivities.sort(
                (a, b) => _parseTimeToMinutes(
                  a.time,
                ).compareTo(_parseTimeToMinutes(b.time)),
              );

              return _DayExpansionTile(
                key: ValueKey('day_$dayNum'),
                dayNumber: dayNum,
                date: dayDate,
                activities: dayActivities,
                activityProgress: '($completedCount/${dayActivities.length})',
                themeColor: widget.themeColor,
                isEditable: widget.isEditable && !isDayPassed,
                isTripSaved: int.tryParse(widget.trip.tripId) != null,
                onEdit: (activity) => _showEditDialog(activity),
                onAdd: () => _showAddDialog(dayNum),
                onToggleLock: (activity) {
                  context.read<ActivityBloc>().add(
                    UpdateActivityEvent(activity.copyWith(isCustom: !activity.isCustom),
                        widget.trip.startDate),
                  );
                },
                onDelete: (activityId) {
                  context.read<ActivityBloc>().add(
                    DeleteActivityEvent(
                      activityId,
                      widget.trip.tripId,
                      widget.trip.startDate,
                    ),
                  );
                },
              );
            }),
          ],
        );
      },
    );
  }
}

class _DayExpansionTile extends StatelessWidget {
  final int dayNumber;
  final DateTime date;
  final List<Activity> activities;
  final String activityProgress;
  final Color themeColor;
  final bool isEditable;
  final bool isTripSaved;
  final VoidCallback onAdd;
  final Function(int) onDelete;
  final Function(Activity) onEdit;
  final Function(Activity) onToggleLock;

  const _DayExpansionTile({
    super.key,
    required this.dayNumber,
    required this.date,
    required this.activities,
    required this.activityProgress,
    required this.themeColor,
    required this.isEditable,
    required this.isTripSaved,
    required this.onAdd,
    required this.onDelete,
    required this.onEdit,
    required this.onToggleLock,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        key: PageStorageKey('day_$dayNumber'),
        title: Row(
          children: [
            Text(
              'Day $dayNumber - ${DateFormat('dd MMM').format(date)}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(width: 8),
            Text(
              activityProgress,
              style: TextStyle(
                fontSize: 12,
                color: themeColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isEditable)
              IconButton(
                icon: const Icon(
                  Icons.add_circle,
                  color: AppColors.accentGreen,
                ),
                onPressed: onAdd,
              ),
            const Icon(Icons.keyboard_arrow_down),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Column(
              children: activities.map((activity) {
                final Widget itemContent = _buildItem(activity);

                if (isEditable) {
                  return Dismissible(
                    key: ValueKey('activity_${activity.activityId}'),
                    direction: DismissDirection.horizontal,
                    background: _buildOptionsBackground(),
                    secondaryBackground: _buildDeleteBackground(),
                    confirmDismiss: (direction) async {
                      if (direction == DismissDirection.startToEnd) {
                        await _showActivityOptionsDialog(context, activity);
                        return false;
                      } else {
                        return await _showDeleteConfirmation(
                          context,
                          activity.name,
                        );
                      }
                    },
                    onDismissed: (_) => onDelete(activity.activityId),
                    child: itemContent,
                  );
                } else {
                  return itemContent;
                }
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionsBackground() {
    return Container(
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.blue,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Row(
        children: [
          Icon(Icons.settings, color: Colors.white),
          SizedBox(width: 8),
          Text("Options", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildDeleteBackground() {
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.red.shade700,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.delete_outline, color: Colors.white, size: 28),
          Text("Delete", style: TextStyle(color: Colors.white, fontSize: 12)),
        ],
      ),
    );
  }

  Future<bool?> _showDeleteConfirmation(BuildContext context, String name) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text(
          "Delete Activity?",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text("Are you sure you want to remove '$name'?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              "Cancel",
              style: TextStyle(color: AppColors.secondaryText),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Delete", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _showActivityOptionsDialog(
    BuildContext context,
    Activity activity,
  ) async {
    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Wrap(
            children: [
              if (isTripSaved)
                ListTile(
                  leading: const Icon(Icons.edit, color: AppColors.primaryBlue),
                  title: const Text('Edit Activity'),
                  onTap: () {
                    Navigator.pop(ctx);
                    onEdit(activity);
                  },
                ),
              ListTile(
                leading: Icon(
                  activity.isCustom ? Icons.lock_open : Icons.lock,
                  color: activity.isCustom ? Colors.orange : AppColors.primaryBlue,
                ),
                title: Text(activity.isCustom ? 'Unlock Activity' : 'Lock Activity'),
                subtitle: Text(activity.isCustom ? 'AI can modify this activity' : 'Prevent AI from changing this', style: const TextStyle(fontSize: 12)),
                onTap: () {
                  Navigator.pop(ctx);
                  onToggleLock(activity);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildItem(Activity activity) {
    final statusColor = _getStatusColor(activity.status);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 80,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.08),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      bottomLeft: Radius.circular(16),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        (activity.time ?? "--:--").split(' ')[0],
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                      Text(
                        (activity.time ?? "").contains('PM') ? 'PM' : 'AM',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          activity.name,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              size: 12,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                activity.locationName ?? "No location",
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (activity.isCustom)
                          Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Row(
                              children: [
                                Icon(Icons.lock, size: 12, color: AppColors.primaryBlue),
                                const SizedBox(width: 4),
                                Text("Locked", style: TextStyle(fontSize: 10, color: AppColors.primaryBlue, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
    );
  }
}

class _AddActivityDialog extends StatefulWidget {
  final int day;
  final Trip trip;
  final Color themeColor;
  final Function(Activity) onSave;
  final Activity? activityToEdit;

  const _AddActivityDialog({
    required this.day,
    required this.trip,
    required this.onSave,
    required this.themeColor,
    this.activityToEdit,
  });

  @override
  State<_AddActivityDialog> createState() => _AddActivityDialogState();
}

class _AddActivityDialogState extends State<_AddActivityDialog> {
  final _nameController = TextEditingController();
  final _locController = TextEditingController();
  final GoogleApiService _googleService = GoogleApiService();
  List<String> _suggestions = [];
  TimeOfDay _selectedTime = const TimeOfDay(hour: 10, minute: 0);
  bool _isFetching = false;
  double? _destLat;
  double? _destLng;

  @override
  void initState() {
    super.initState();
    _fetchDestinationCoords();
    if (widget.activityToEdit != null) {
      _nameController.text = widget.activityToEdit!.name;
      _locController.text = widget.activityToEdit!.locationName ?? '';
      if (widget.activityToEdit!.time != null) {
        try {
          final format = DateFormat.jm(); // h:mm a
          final dt = format.parse(widget.activityToEdit!.time!);
          _selectedTime = TimeOfDay.fromDateTime(dt);
        } catch (e) {
          try {
            final dt = DateFormat('HH:mm').parse(widget.activityToEdit!.time!);
            _selectedTime = TimeOfDay.fromDateTime(dt);
          } catch (_) {}
        }
      }
    }
  }

  Future<void> _fetchDestinationCoords() async {
    final coords = await _googleService.getCoordinates(widget.trip.destination);
    if (mounted && coords != null) {
      setState(() {
        _destLat = coords['lat'];
        _destLng = coords['lng'];
      });
    }
  }

  void _onLocationChanged(String value) async {
    if (value.length < 3) {
      setState(() => _suggestions = []);
      return;
    }
    final results = await _googleService.getPlaceSuggestions(
      value,
      lat: _destLat,
      lng: _destLng,
    );
    setState(() => _suggestions = results);
  }

  String _formatTimeForSave(TimeOfDay time) {
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    return DateFormat('h:mm a').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(widget.activityToEdit == null
              ? 'Add Activity - Day ${widget.day}'
              : 'Edit Activity - Day ${widget.day}',
          style: const TextStyle(fontWeight: FontWeight.bold)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              cursorColor: AppColors.primaryBlue,
              decoration: const InputDecoration(
                labelText: 'Name',
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: AppColors.primaryBlue),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: AppColors.accentGreen,
                    width: 2,
                  ),
                ),
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: AppColors.primaryBlue),
                ),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _locController,
              onChanged: _onLocationChanged,
              cursorColor: AppColors.primaryBlue,
              decoration: const InputDecoration(
                labelText: 'Location',
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: AppColors.primaryBlue),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: AppColors.accentGreen,
                    width: 2,
                  ),
                ),
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: AppColors.primaryBlue),
                ),
              ),
            ),
            if (_suggestions.isNotEmpty)
              ..._suggestions.map(
                (s) => ListTile(
                  title: Text(s),
                  onTap: () {
                    _locController.text = s;
                    setState(() => _suggestions = []);
                  },
                ),
              ),
            ListTile(
              title: Text("Time: ${_selectedTime.format(context)}"),
              trailing: const Icon(Icons.access_time),
              onTap: () async {
                final picked = await showTimePicker(
                  context: context,
                  initialTime: _selectedTime,
                  builder: (context, child) {
                    return Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: ColorScheme.light(
                          primary: widget.themeColor,
                          onPrimary: Colors.white,
                          onSurface: Colors.black,
                        ),
                        textButtonTheme: TextButtonThemeData(
                          style: TextButton.styleFrom(
                            foregroundColor: widget.themeColor,
                          ),
                        ),
                      ),
                      child: child!,
                    );
                  },
                );
                if (picked != null) setState(() => _selectedTime = picked);
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: widget.themeColor),
          onPressed: _isFetching ? null : () async {
            if (_nameController.text.isEmpty) return;

            final activityDate = widget.trip.startDate.add(
              Duration(days: widget.day - 1),
            );
            final now = DateTime.now();
            final selectedDateTime = DateTime(
              activityDate.year,
              activityDate.month,
              activityDate.day,
              _selectedTime.hour,
              _selectedTime.minute,
            );

            if (selectedDateTime.isBefore(now)) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Cannot add activity in the past.'),
                  backgroundColor: Colors.red,
                ),
              );
              return;
            }

            setState(() => _isFetching = true);

            double? lat;
            double? lng;
            if (_locController.text.isNotEmpty) {
              final coords = await _googleService.getCoordinates(_locController.text);
              if (coords != null) {
                lat = coords['lat'];
                lng = coords['lng'];
              }
            }

            if (!mounted) return;

            final Activity resultActivity;
            if (widget.activityToEdit != null) {
              resultActivity = widget.activityToEdit!.copyWith(
                name: _nameController.text,
                locationName: _locController.text,
                time: _formatTimeForSave(_selectedTime),
                latitude: lat,
                longitude: lng,
              );
            } else {
              resultActivity = Activity(
                  activityId: -DateTime.now().microsecondsSinceEpoch,
                  tripId: int.tryParse(widget.trip.tripId) ?? 0,
                  name: _nameController.text,
                  locationName: _locController.text,
                  dayNumber: widget.day,
                  status: 'Planned',
                  time: _formatTimeForSave(_selectedTime),
                  isCustom: true,
                  latitude: lat,
                  longitude: lng);
            }

            widget.onSave(resultActivity);
            Navigator.pop(context);
          },
          child: _isFetching
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Text('Save', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}

Color _getStatusColor(String status) {
  switch (status) {
    case 'Ongoing':
      return AppColors.ongoingBlue;
    case 'Completed':
      return AppColors.completedGreen;
    default:
      return AppColors.plannedOrange;
  }
}
