import 'package:bloc/bloc.dart';
import 'package:hero/data/models/user_model.dart' as models;
import 'package:hero/data/services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;

import 'auth_states.dart';

class AuthCubit extends Cubit<AuthState> {
  final SupabaseService _supabaseService = SupabaseService();
  final SupabaseClient _supabase = Supabase.instance.client;

  AuthCubit() : super(AuthInitial()) {
    checkAuthStatus();
  }

  Future<void> login(String email, String password) async {
    emit(AuthLoading());
    try {
      final user = await _supabaseService.signIn(email, password);
      if (user != null) {
        await _syncUserWithPublicTable(user);
        emit(AuthAuthenticated(user));
      } else {
        emit(AuthError('Invalid credentials'));
      }
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> register(String email, String password, String fullName) async {
    emit(AuthLoading());
    try {
      final user = await _supabaseService.signUp(email, password, fullName);
      if (user != null) {
        // انتظر قليلاً قبل المزامنة
        await Future.delayed(const Duration(seconds: 1));
        await _syncUserWithPublicTable(user);
        emit(AuthRegistered(user));
      } else {
        emit(AuthError('Registration failed'));
      }
    } catch (e) {
      print('❌ Registration error in cubit: $e');
      emit(AuthError('Registration error: ${e.toString()}'));
    }
  }

  Future<void> logout() async {
    emit(AuthLoading());
    try {
      await _supabaseService.signOut();
      emit(AuthUnauthenticated());
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> checkAuthStatus() async {
    emit(AuthLoading());

    try {
      final currentSession = _supabase.auth.currentSession;

      if (currentSession != null) {
        print('✅ تم العثور على جلسة نشطة: ${currentSession.user.email}');

        final user = models.AppUser(
          id: currentSession.user.id,
          email: currentSession.user.email!,
          fullName: currentSession.user.userMetadata?['full_name'] ?? 'User',
        );

        // حاول مزامنة المستخدم إذا لم يكن موجوداً
        await _syncUserWithPublicTable(user, forceCreate: true);
        emit(AuthAuthenticated(user));
      } else {
        final user = await _supabaseService.getCurrentUser();
        if (user != null) {
          emit(AuthAuthenticated(user));
        } else {
          emit(AuthUnauthenticated());
        }
      }
    } catch (e) {
      print('⚠️ خطأ في التحقق من حالة المصادقة: $e');
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _syncUserWithPublicTable(
      models.AppUser user, {
        bool forceCreate = false,
      }) async {
    try {
      // أولاً: تحقق إذا كان المستخدم موجوداً بالفعل
      final existingUser = await _supabase
          .from('users')
          .select('*')
          .eq('auth_user_id', user.id)
          .maybeSingle()
          .catchError((_) => null);

      if (existingUser == null || forceCreate) {
        // أنشئ المستخدم الجديد بدون `updated_at` إذا كان مشكلة
        await _supabase.from('users').insert({
          'auth_user_id': user.id,
          'email': user.email,
          'name': user.fullName,
          'role': 'customer',
          'created_at': DateTime.now().toIso8601String(),
          // لا تضف updated_at إذا كان يسبب مشكلة
        });
        print('✅ تم إنشاء مستخدم جديد: ${user.email}');
      } else {
        // تحديث المستخدم الحالي بدون updated_at
        await _supabase.from('users').update({
          'email': user.email,
          'name': user.fullName,
          // لا تضف updated_at إذا كان يسبب مشكلة
        }).eq('auth_user_id', user.id);
        print('✅ تم تحديث المستخدم: ${user.email}');
      }
    } catch (e) {
      print('⚠️ خطأ في مزامنة المستخدم: $e');

      // محاولة بديلة باستخدام upsert بدون updated_at
      try {
        await _supabase.from('users').upsert({
          'auth_user_id': user.id,
          'email': user.email,
          'name': user.fullName,
          'role': 'customer',
          'created_at': DateTime.now().toIso8601String(),
        }, onConflict: 'auth_user_id');
        print('✅ تم مزامنة المستخدم بالطريقة البديلة: ${user.email}');
      } catch (e2) {
        print('❌ فشل في المزامنة البديلة أيضاً: $e2');
      }
    }
  }

  models.AppUser? getCurrentUser() {
    final state = this.state;
    if (state is AuthAuthenticated) {
      return state.user;
    } else if (state is AuthRegistered) {
      return state.user;
    }
    return null;
  }

  bool get isAuthenticated => state is AuthAuthenticated || state is AuthRegistered;
}