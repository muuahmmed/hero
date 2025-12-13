import 'package:http/http.dart' as http;
import 'dart:convert';

class AuthConfigService {
  final String supabaseUrl;
  final String serviceRoleKey;

  AuthConfigService({
    required this.supabaseUrl,
    required this.serviceRoleKey,
  });

  Future<void> updatePasswordPolicy({
    required int minLength,
    required bool requireNumbers,
    required bool requireSymbols,
  }) async {
    final response = await http.post(
      Uri.parse('$supabaseUrl/auth/v1/settings'),
      headers: {
        'Authorization': 'Bearer $serviceRoleKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'security': {
          'password': {
            'min_length': minLength,
            'require_numbers': requireNumbers,
            'require_symbols': requireSymbols,
          }
        }
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update password policy');
    }
  }

  Future<void> addOAuthProvider({
    required String provider,
    required String clientId,
    required String clientSecret,
  }) async {
    final response = await http.post(
      Uri.parse('$supabaseUrl/auth/v1/admin/providers'),
      headers: {
        'Authorization': 'Bearer $serviceRoleKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'type': 'oauth',
        'provider': provider,
        'client_id': clientId,
        'client_secret': clientSecret,
      }),
    );

    if (response.statusCode != 201) {
      throw Exception('Failed to add OAuth provider');
    }
  }

  Future<void> setEmailRateLimit({
    required int maxAttempts,
    required Duration interval,
  }) async {
    final response = await http.post(
      Uri.parse('$supabaseUrl/auth/v1/settings'),
      headers: {
        'Authorization': 'Bearer $serviceRoleKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'rate_limit': {
          'email': {
            'max_attempts': maxAttempts,
            'interval': interval.inSeconds,
          }
        }
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to set rate limit');
    }
  }
}