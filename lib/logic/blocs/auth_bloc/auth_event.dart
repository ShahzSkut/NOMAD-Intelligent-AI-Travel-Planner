// Defines events for the AuthBloc.
abstract class AuthEvent {}

class AuthCheckRequested extends AuthEvent {}

class AuthLoginRequested extends AuthEvent {
  final String email;
  final String password;
  AuthLoginRequested({required this.email, required this.password});
}

class AuthRegisterRequested extends AuthEvent {
  final String name;
  final String email;
  final String password;
  AuthRegisterRequested({
    required this.name,
    required this.email,
    required this.password,
  });
}

class AuthLogoutRequested extends AuthEvent {}
