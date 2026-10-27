import 'package:nomad_mobile/core/services/supabase_service.dart';
import 'package:nomad_mobile/data/models/budget.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Manages CRUD operations for budgets in the database.
class BudgetRepository {
  final SupabaseClient _client;

  BudgetRepository(SupabaseService supabaseService) : _client = supabaseService.client;

  Future<Budget?> fetchBudgetByTrip(String tripId) async {
    final response = await _client
        .from('BUDGET')
        .select()
        .eq('trip_id', tripId)
        .maybeSingle();
    
    return response != null ? Budget.fromJson(response) : null;
  }

  Future<void> updateBudget(Budget budget) async {
    await _client
        .from('BUDGET')
        .update(budget.toJson())
        .eq('trip_id', budget.tripId);
  }

  Future<void> createBudget(Budget budget) async {
    final data = budget.toJson();
    await _client.from('BUDGET').insert(data);
  }

  Future<void> deleteBudgetsByTrip(String tripId) async {
    await _client.from('BUDGET').delete().eq('trip_id', tripId);
  }

  Future<void> replaceBudget(Budget budget) async {
    // Delete using the integer tripId to ensure type matching with DB (BIGINT)
    await _client.from('BUDGET').delete().eq('trip_id', budget.tripId);
    await _client.from('BUDGET').insert(budget.toJson());
  }
}