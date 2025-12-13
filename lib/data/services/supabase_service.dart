import 'package:hero/data/services/shared_prefrences.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import '../models/user_model.dart';

class SupabaseService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<User?> signIn(String email, String password) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null && response.session != null) {
        await SessionManager.saveSession(
          response.session!.accessToken,
          response.user!.email!,
        );

        print('✅ Login successful, session saved');

        return User(
          id: response.user!.id,
          email: response.user!.email!,
          fullName: response.user!.userMetadata?['full_name'],
        );
      }
      return null;
    } catch (e) {
      print('❌ خطأ في تسجيل الدخول: $e');
      throw Exception('Login failed: $e');
    }
  }

  Future<User?> signUp(String email, String password, String fullName) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': fullName},
      );

      if (response.user != null && response.session != null) {
        // ✅ حفظ الجلسة في SharedPreferences
        await SessionManager.saveSession(
          response.session!.accessToken,
          response.user!.email!,
        );

        print('✅ Registration successful, session saved');

        return User(
          id: response.user!.id,
          email: response.user!.email!,
          fullName: fullName,
        );
      }
      return null;
    } catch (e) {
      print('❌ خطأ في التسجيل: $e');
      throw Exception('Signup failed: $e');
    }
  }

  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
      await SessionManager.clearSession();
      print('✅ تم تسجيل الخروج وجلسة محذوفة');
    } catch (e) {
      print('❌ خطأ في تسجيل الخروج: $e');
      throw Exception('Signout failed: $e');
    }
  }

  Future<User?> getCurrentUser() async {
    try {

      var user = _supabase.auth.currentUser;

      if (user != null) {
        print('✅ Found user in Supabase: ${user.email}');
        return User(
          id: user.id,
          email: user.email!,
          fullName: user.userMetadata?['full_name'],
        );
      }

      final savedSession = await SessionManager.getSession();
      if (savedSession != null) {
        print('🔄 Trying to restore session from saved data...');
        try {
          await _supabase.auth.recoverSession(savedSession['token']!);
          user = _supabase.auth.currentUser;

          if (user != null) {
            print('✅ Session restored successfully: ${user.email}');
            return User(
              id: user.id,
              email: user.email!,
              fullName: user.userMetadata?['full_name'],
            );
          }
        } catch (e) {
          print('⚠️ Failed to restore session: $e');
        }
      }

      print('⚠️ لا يوجد مستخدم حالي');
      return null;

    } catch (e) {
      print('❌ خطأ في جلب المستخدم الحالي: $e');
      return null;
    }
  }
}