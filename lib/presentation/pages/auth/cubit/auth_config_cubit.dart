import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:hero/data/services/auth_config_service.dart';

part 'auth_config_state.dart';

class AuthConfigCubit extends Cubit<AuthConfigState> {
  final AuthConfigService _authConfigService;

  AuthConfigCubit(this._authConfigService) : super(AuthConfigInitial());

  Future<void> fetchAuthConfig() async {
    emit(AuthConfigLoading());
    try {
      final config = await _getConfigFromDatabase();
      emit(AuthConfigLoaded(config));
    } catch (e) {
      emit(AuthConfigError(e.toString()));
    }
  }

  Future<void> updatePasswordPolicy({
    required int minLength,
    required bool requireNumbers,
    required bool requireSymbols,
  }) async {
    try {
      await _authConfigService.updatePasswordPolicy(
        minLength: minLength,
        requireNumbers: requireNumbers,
        requireSymbols: requireSymbols,
      );
      emit(AuthConfigUpdated('Password policy updated'));
    } catch (e) {
      emit(AuthConfigError(e.toString()));
    }
  }


  Future<void> addGoogleAuth(String clientId, String clientSecret) async {
    try {
      await _authConfigService.addOAuthProvider(
        provider: 'google',
        clientId: clientId,
        clientSecret: clientSecret,
      );
      emit(AuthConfigUpdated('Google OAuth added'));
    } catch (e) {
      emit(AuthConfigError(e.toString()));
    }
  }

  Future<Map<String, dynamic>> _getConfigFromDatabase() async {
    return {
      'password_policy': {
        'min_length': 8,
        'require_numbers': true,
        'require_symbols': false,
      },
      'oauth_providers': ['google', 'facebook'],
      'rate_limits': {
        'max_attempts': 5,
        'interval_minutes': 15,
      },
    };
  }
}