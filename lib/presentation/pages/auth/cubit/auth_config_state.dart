part of 'auth_config_cubit.dart';

abstract class AuthConfigState extends Equatable {
  const AuthConfigState();

  @override
  List<Object> get props => [];
}

class AuthConfigInitial extends AuthConfigState {}

class AuthConfigLoading extends AuthConfigState {}

class AuthConfigLoaded extends AuthConfigState {
  final Map<String, dynamic> config;

  const AuthConfigLoaded(this.config);

  @override
  List<Object> get props => [config];
}

class AuthConfigUpdated extends AuthConfigState {
  final String message;

  const AuthConfigUpdated(this.message);

  @override
  List<Object> get props => [message];
}

class AuthConfigError extends AuthConfigState {
  final String message;

  const AuthConfigError(this.message);

  @override
  List<Object> get props => [message];
}