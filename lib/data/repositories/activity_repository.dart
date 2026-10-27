import 'package:nomad_mobile/core/services/supabase_service.dart';
import 'package:nomad_mobile/data/models/activity.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Manages CRUD operations for activities in the database.
class ActivityRepository {
  final SupabaseClient _client;

  ActivityRepository(SupabaseService supabaseService)
    : _client = supabaseService.client;

  Future<List<Activity>> fetchActivitiesByTrip(String tripId) async {
    final response = await _client
        .from('ACTIVITIES')
        .select()
        .eq('trip_id', tripId)
        .order('day_number', ascending: true);
    return response.map<Activity>((e) => Activity.fromJson(e)).toList();
  }

  Future<void> addActivity(Activity activity) async {
    await _client.from('ACTIVITIES').insert(activity.toJson());
  }

  Future<void> updateActivityStatus(int activityId, String status) async {
    await _client
        .from('ACTIVITIES')
        .update({'status': status})
        .eq('activity_id', activityId);
  }

  Future<void> deleteActivity(int activityId) async {
    await _client.from('ACTIVITIES').delete().eq('activity_id', activityId);
  }

  Future<void> deleteAllActivitiesByTrip(String tripId) async {
    await _client.from('ACTIVITIES').delete().eq('trip_id', tripId);
  }

  Future<void> addActivities(List<Activity> activities) async {
    final data = activities.map((a) {
      final json = a.toJson();
      json.remove('activity_id');
      return json;
    }).toList();
    await _client.from('ACTIVITIES').insert(data);
  }
}
