import 'package:hero/data/services/shared_prefrences.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import '../models/user_model.dart' as models;

class SupabaseService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<models.AppUser?> signIn(String email, String password) async {
    try {
      print('🔐 محاولة تسجيل الدخول: $email');

      final response = await _supabase.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );

      if (response.user != null && response.session != null) {
        print('✅ نجح تسجيل الدخول: ${response.user!.email}');

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
      print('❌ خطأ في تسجيل الدخول: $e');
      throw Exception('Login failed: ${e.toString()}');
    }
  }

  Future<models.AppUser?> signUp(String email, String password, String fullName) async {
    try {
      print('📝 محاولة التسجيل: $email');

      final response = await _supabase.auth.signUp(
        email: email.trim(),
        password: password,
        data: {'full_name': fullName.trim()},
      );

      print('📊 استجابة التسجيل: ${response.user != null}');

      if (response.user != null) {
        print('✅ نجح التسجيل في Authentication');

        // احفظ الجلسة إذا كانت موجودة
        if (response.session != null) {
          await SessionManager.saveSession(
            response.session!.accessToken,
            response.user!.email!,
          );
          print('✅ تم حفظ الجلسة');
        }

        return models.AppUser(
          id: response.user!.id,
          email: response.user!.email!,
          fullName: fullName,
        );
      }

      print('⚠️ لم يتم إنشاء مستخدم في Authentication');
      return null;
    } catch (e) {
      print('❌ خطأ في التسجيل: $e');
      throw Exception('Signup failed: ${e.toString()}');
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

  Future<models.AppUser?> getCurrentUser() async {
    try {
      var user = _supabase.auth.currentUser;

      if (user != null) {
        print('✅ وجد مستخدم في Supabase: ${user.email}');
        return models.AppUser(
          id: user.id,
          email: user.email!,
          fullName: user.userMetadata?['full_name'] ?? 'User',
        );
      }

      final savedSession = await SessionManager.getSession();
      if (savedSession != null) {
        print('🔄 محاولة استعادة الجلسة من البيانات المحفوظة...');
        try {
          await _supabase.auth.recoverSession(savedSession['token']!);
          user = _supabase.auth.currentUser;

          if (user != null) {
            print('✅ تمت استعادة الجلسة بنجاح: ${user.email}');
            return models.AppUser(
              id: user.id,
              email: user.email!,
              fullName: user.userMetadata?['full_name'] ?? 'User',
            );
          }
        } catch (e) {
          print('⚠️ فشل في استعادة الجلسة: $e');
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