import 'package:hero/data/services/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import '../models/user_model.dart' as models;

class SupabaseService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<models.AppUser?> signIn(String email, String password) async {
    try {
      print('try to login $email');

      final response = await _supabase.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );

      if (response.user != null && response.session != null) {
        print('login is successful ${response.user!.email}');

        await SessionManager.saveSession(
          response.session!.accessToken,
          response.user!.email!,
        );

        return models.AppUser(
          id: response.user!.id,
          email: response.user!.email!,
          fullName: response.user!.userMetadata?['full_name'] ?? 'User',
        );
      }
      return null;
    } catch (e) {
      print('login is failed $e');
      throw Exception('Login failed: ${e.toString()}');
    }
  }

  Future<models.AppUser?> signUp(String email, String password, String fullName) async {
    try {
      print('📝signing up $email');

      final response = await _supabase.auth.signUp(
        email: email.trim(),
        password: password,
        data: {'full_name': fullName.trim()},
      );

      print('📊sign up successful ${response.user != null}');

      if (response.user != null) {
        print('Authentication successful for ${response.user!.email}');

        if (response.session != null) {
          await SessionManager.saveSession(
            response.session!.accessToken,
            response.user!.email!,
          );
          print('✅ Session saved for new user: ${response.user!.email}');
        }

        return models.AppUser(
          id: response.user!.id,
          email: response.user!.email!,
          fullName: fullName,
        );
      }

      print('⚠️ Sign up completed but no user returned');
      return null;
    } catch (e) {
      print('Signing up is not completed $e');
      throw Exception('Signup failed: ${e.toString()}');
    }
  }

  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
      await SessionManager.clearSession();
      print('sign out is successful');
    } catch (e) {
      print('sign out is not completed $e');
      throw Exception('Sign out failed: $e');
    }
  }

  Future<models.AppUser?> getCurrentUser() async {
    try {
      var user = _supabase.auth.currentUser;

      if (user != null) {
        print(' Supabase user is found ${user.email}');
        return models.AppUser(
          id: user.id,
          email: user.email!,
          fullName: user.userMetadata?['full_name'] ?? 'User',
        );
      }

      final savedSession = await SessionManager.getSession();
      if (savedSession != null) {
        print(' Found saved session for ${savedSession['email']}');
        try {
          await _supabase.auth.recoverSession(savedSession['token']!);
          user = _supabase.auth.currentUser;

          if (user != null) {
            print(' Supabase user is found ${user.email}');
            return models.AppUser(
              id: user.id,
              email: user.email!,
              fullName: user.userMetadata?['full_name'] ?? 'User',
            );
          }
        } catch (e) {
          print('Error recovering session: $e');
        }
      }

      print('No user is currently authenticated');
      return null;

    } catch (e) {
      print('Error getting current user: $e');
      return null;
    }
  }
}