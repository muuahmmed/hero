import '../../../../data/models/user_model.dart' as models;

sealed class AuthState {}

final class AuthInitial extends AuthState {}

final class AuthLoading extends AuthState {}

final class AuthAuthenticated extends AuthState {
  final models.AppUser user;

  AuthAuthenticated(this.user);
}

final class AuthRegistered extends AuthState {
  final models.AppUser user;

  AuthRegistered(this.user);
}

final class AuthUnauthenticated extends AuthState {}

final class AuthError extends AuthState {
  final String message;

  AuthError(this.message);
}