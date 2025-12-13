import 'package:bloc/bloc.dart';
import 'package:hero/data/entities/user_entity.dart';
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

        await _syncUserWithPublicTable(user as UserModel);
        emit(AuthAuthenticated(user as UserModel));
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

        await _syncUserWithPublicTable(user as UserModel);
        emit(AuthRegistered(user as UserModel));
      } else {
        emit(AuthError('Registration failed'));
      }
    } catch (e) {
      emit(AuthError(e.toString()));
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


        final userModel = UserModel(
          id: currentSession.user.id,
          email: currentSession.user.email!,
          fullName: currentSession.user.userMetadata?['full_name'],
        );


        await _syncUserWithPublicTable(userModel);

        emit(AuthAuthenticated(userModel));
      } else {

        final user = await _supabaseService.getCurrentUser();
        if (user != null) {
          emit(AuthAuthenticated(user as UserModel));
        } else {
          emit(AuthUnauthenticated());
        }
      }
    } catch (e) {
      print('⚠️ خطأ في التحقق من حالة المصادقة: $e');
      emit(AuthUnauthenticated());
    }
  }


  Future<void> _syncUserWithPublicTable(UserModel user) async {
    try {
      await _supabase.from('users').upsert({
        'auth_user_id': user.id,
        'email': user.email,
        'name': user.fullName,
        'role': 'customer',
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'auth_user_id');
      print('✅ تم مزامنة المستخدم: ${user.email}');
    } catch (e) {
      print('⚠️ خطأ في مزامنة المستخدم: $e');
    }
  }


  UserModel? getCurrentUser() {
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