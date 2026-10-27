import 'package:nomad_mobile/core/services/supabase_service.dart';
import 'package:nomad_mobile/data/models/trip.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Manages CRUD operations for trips in the database.
class TripRepository {
  final SupabaseClient _client;

  TripRepository(SupabaseService supabaseService)
    : _client = supabaseService.client;

  Future<List<Trip>> fetchTrips(String userId) async {
    final response = await _client
        .from('TRIPS')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return response.map<Trip>((e) => Trip.fromJson(e)).toList();
  }

  Future<List<Trip>> searchTrips(String userId, String keyword) async {
    final response = await _client
        .from('TRIPS')
        .select()
        .eq('user_id', userId)
        .or('destination.ilike.%$keyword%,trip_purpose.ilike.%$keyword%')
        .order('created_at', ascending: false);

    return response.map<Trip>((e) => Trip.fromJson(e)).toList();
  }

  Future<List<Trip>> filterTrips(String userId, String status) async {
    final response = await _client
        .from('TRIPS')
        .select()
        .eq('user_id', userId)
        .eq('status', status)
        .order('created_at', ascending: false);

    return response.map<Trip>((e) => Trip.fromJson(e)).toList();
  }

  Future<Trip> createTrip(Trip trip) async {
    final data = trip.toJson();
    data.remove('trip_id');
    final response = await _client.from('TRIPS').insert(data).select().single();
    return Trip.fromJson(response);
  }

  Future<void> updateTrip(Trip trip) async {
    await _client
        .from('TRIPS')
        .update(trip.toJson())
        .eq('trip_id', trip.tripId);
  }

  Future<void> deleteTrip(String tripId) async {
    await _client.from('TRIPS').delete().eq('trip_id', tripId);
  }

  Future<List<Map<String, dynamic>>> fetchTripStats(String userId) async {
    final response = await _client
        .from('ACTIVITIES')
        .select('activity_id, trip_id, status, time, day_number, name');

    return List<Map<String, dynamic>>.from(response);
  }

  Future<Map<String, String>> fetchTripBackgroundLocations(
    String userId,
  ) async {
    final response = await _client
        .from('ACTIVITIES')
        .select('trip_id, location_name, status, day_number')
        .order('day_number', ascending: true);

    Map<String, List<Map<String, dynamic>>> grouped = {};
    for (var row in response) {
      final tId = row['trip_id'].toString();
      grouped.putIfAbsent(tId, () => []).add(row);
    }

    Map<String, String> backgroundNames = {};

    grouped.forEach((tripId, activities) {
      final ongoing = activities.firstWhere(
        (a) => a['status'] == 'Ongoing',
        orElse: () => {},
      );

      if (ongoing.isNotEmpty) {
        backgroundNames[tripId] = ongoing['location_name'];
      } else {
        bool allDone = activities.every((a) => a['status'] == 'Completed');
        if (allDone && activities.isNotEmpty) {
          backgroundNames[tripId] = activities.last['location_name'];
        } else if (activities.isNotEmpty) {
          backgroundNames[tripId] = activities.first['location_name'];
        }
      }
    });

    return backgroundNames;
  }

  Future<void> updateTripImageUrl(String tripId, String imageUrl) async {
    await _client
        .from('TRIPS')
        .update({'trip_image_url': imageUrl})
        .eq('trip_id', tripId);
  }

  Future<String?> getFirstActivityLocation(String tripId) async {
    final response = await _client
        .from('ACTIVITIES')
        .select('location_name')
        .eq('trip_id', tripId)
        .order('day_number', ascending: true)
        .limit(1)
        .maybeSingle();

    return response?['location_name'] as String?;
  }

  Future<bool> isCodeUnique(String code) async {
    final response = await _client
        .from('TRIPS')
        .select('trip_id')
        .eq('code', code)
        .maybeSingle();
    return response == null;
  }

  Future<void> importTrip(String code, String userId) async {
    // 1. Find the source trip
    final sourceTripData = await _client
        .from('TRIPS')
        .select()
        .eq('code', code)
        .maybeSingle();

    if (sourceTripData == null) {
      throw Exception('Trip not found with code: $code');
    }

    final sourceTripId = sourceTripData['trip_id'];

    // 2. Create new trip copy
    final newTripData = Map<String, dynamic>.from(sourceTripData);
    newTripData.remove('trip_id');
    newTripData.remove('created_at');
    newTripData.remove('updated_at');
    newTripData.remove('code'); // Let DB generate a new unique code
    newTripData['user_id'] = userId;
    newTripData['status'] = 'Planned'; // Reset status for the new user

    final newTripResponse =
        await _client.from('TRIPS').insert(newTripData).select().single();
    final newTripId = newTripResponse['trip_id'];

    // 3. Copy Activities
    final activities =
        await _client.from('ACTIVITIES').select().eq('trip_id', sourceTripId);
    if (activities.isNotEmpty) {
      final newActivities = (activities as List).map((a) {
        final map = Map<String, dynamic>.from(a);
        map.remove('activity_id');
        map.remove('created_at');
        map['trip_id'] = newTripId;
        map['status'] = 'Planned';
        return map;
      }).toList();
      await _client.from('ACTIVITIES').insert(newActivities);
    }

    // 4. Copy Checklist
    final checklist =
        await _client.from('CHECKLIST').select().eq('trip_id', sourceTripId);
    if (checklist.isNotEmpty) {
      final newChecklist = (checklist as List).map((c) {
        final map = Map<String, dynamic>.from(c);
        map.remove('checklist_id');
        map.remove('created_at');
        map['trip_id'] = newTripId;
        map['status'] = false;
        return map;
      }).toList();
      await _client.from('CHECKLIST').insert(newChecklist);
    }

    // 5. Copy Budget
    final budget = await _client
        .from('BUDGET')
        .select()
        .eq('trip_id', sourceTripId)
        .maybeSingle();
    if (budget != null) {
      final newBudget = Map<String, dynamic>.from(budget);
      newBudget.remove('budget_id');
      newBudget.remove('created_at');
      newBudget['trip_id'] = newTripId;
      await _client.from('BUDGET').insert(newBudget);
    }
  }
}
