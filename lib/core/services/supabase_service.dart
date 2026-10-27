import 'package:nomad_mobile/data/models/user.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;

// Manages authentication and user sessions with Supabase.
class SupabaseService {
  final SupabaseClient _supabase = Supabase.instance.client;

  SupabaseClient get client => _supabase;

Future<User> signUp(String email, String password, String name) async {
  final normalizedEmail = email.trim().toLowerCase();

  final authResponse = await _supabase.auth.signUp(
    email: normalizedEmail,
    password: password,
    data: {'name': name},
  );

  final authUser = authResponse.user;
  if (authUser == null) throw Exception('Auth registration failed');

  try {
    final profile = await _supabase
        .from('USERS')
        .upsert({
          'auth_uuid': authUser.id,
          'email': normalizedEmail,
          'name': name,
          'role': 'traveler',
        }, onConflict: 'email')
        .select()
        .single();

    return User.fromJson(profile);
    
  } catch (e) {
    // If DB insert fails, sign out the auth user to prevent a stuck state.
    await _supabase.auth.signOut();
    
    print("Database Error during profile creation: $e");
    throw Exception('Account created, but profile setup failed. Please try again.');
  }
}

  Future<User> signIn(String email, String password) async {
    final normalizedEmail = email.trim().toLowerCase();

    final response = await _supabase.auth.signInWithPassword(
      email: normalizedEmail,
      password: password,
    );

    if (response.user == null) {
      throw Exception('Invalid credentials');
    }

    final profile = await _supabase
        .from('USERS')
        .select()
        .eq('email', normalizedEmail)
        .single();

    return User.fromJson(profile);
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  Future<User?> getCurrentUser() async {
    final session = _supabase.auth.currentSession;
    if (session == null || session.user.email == null) return null;

    final profile = await _supabase
        .from('USERS')
        .select()
        .eq('email', session.user.email!)
        .maybeSingle();

    if (profile == null) return null;
    return User.fromJson(profile);
  }
}
