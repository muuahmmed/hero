import 'dio_helper.dart';

class AuthConfigService {
  AuthConfigService();

  Future<void> updatePasswordPolicy({
    required int minLength,
    required bool requireNumbers,
    required bool requireSymbols,
  }) async {
    try {
      final response = await DioHelper.postData(
        url: '/auth/v1/settings',
        data: {
          'security': {
            'password': {
              'min_length': minLength,
              'require_numbers': requireNumbers,
              'require_symbols': requireSymbols,
            }
          }
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to update password policy');
      }
    } catch (e) {
      throw Exception('Update failed: $e');
    }
  }

  Future<void> addOAuthProvider({
    required String provider,
    required String clientId,
    required String clientSecret,
  }) async {
    try {
      final response = await DioHelper.postData(
        url: '/auth/v1/admin/providers',
        data: {
          'type': 'oauth',
          'provider': provider,
          'client_id': clientId,
          'client_secret': clientSecret,
        },
      );

      if (response.statusCode != 201) {
        throw Exception('Failed to add OAuth provider');
      }
    } catch (e) {
      throw Exception('Provider setup failed: $e');
    }
  }
}