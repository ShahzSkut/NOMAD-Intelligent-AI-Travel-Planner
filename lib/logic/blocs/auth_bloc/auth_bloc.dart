import 'package:flutter_bloc/flutter_bloc.dart';
import 'auth_event.dart';
import 'auth_state.dart';
import '../../../core/services/supabase_service.dart';

// Manages user authentication state.
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final SupabaseService service;

  AuthBloc(this.service) : super(AuthInitial()) {
    on<AuthCheckRequested>(_checkSession);
    on<AuthLoginRequested>(_login);
    on<AuthRegisterRequested>(_register);
    on<AuthLogoutRequested>(_logout);
  }

  Future<void> _checkSession(
      AuthCheckRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    final user = await service.getCurrentUser();
    if (user != null) {
      emit(AuthAuthenticated(user));
    } else {
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _login(
      AuthLoginRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final user = await service.signIn(event.email, event.password);
      emit(AuthAuthenticated(user));
    } catch (e) {
      emit(AuthFailure(e.toString()));
    }
  }

  Future<void> _register(
      AuthRegisterRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final user =
          await service.signUp(event.email, event.password, event.name);
      emit(AuthAuthenticated(user));
    } catch (e) {
      emit(AuthFailure(e.toString()));
    }
  }

  Future<void> _logout(
      AuthLogoutRequested event, Emitter<AuthState> emit) async {
    await service.signOut();
    emit(AuthUnauthenticated());
  }
}
