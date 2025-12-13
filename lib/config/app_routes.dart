import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:go_router/go_router.dart';
import 'package:hero/presentation/pages/auth/sign_in.dart';
import 'package:hero/presentation/pages/auth/sign_up.dart';
import 'package:hero/presentation/pages/home_screens/main_home.dart';
import 'package:hero/presentation/pages/on_Borading/on_Boarding_screen.dart';
import 'package:hero/presentation/pages/splash/splash_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/utils/constants.dart';
import '../data/services/auth_config_service.dart';
import '../presentation/pages/admin/auth_settings_screen.dart';
import '../presentation/pages/auth/cubit/auth_config_cubit.dart';

class AppRoutes {
  static final SupabaseClient _supabase = Supabase.instance.client;

  static String? _redirectLogic(BuildContext context, GoRouterState state) {
    final publicRoutes = ['/splash', '/onboarding', '/login', '/register'];

    final currentLocation = state.matchedLocation;

    final hasActiveSession = _supabase.auth.currentSession != null;
    final currentUser = _supabase.auth.currentUser;

    print('🔄 Redirect Check:');
    print('  - Current Location: $currentLocation');
    print('  - Has Active Session: $hasActiveSession');
    print('  - Current User: ${currentUser?.email ?? "None"}');
    print('  - Is Public Route: ${publicRoutes.contains(currentLocation)}');

    if (hasActiveSession &&
        (currentLocation == '/login' || currentLocation == '/register')) {
      print('  ✅ User is authenticated, redirecting to /home');
      return '/home';
    }

    if (!hasActiveSession && currentLocation == '/home') {
      print('  ❌ User not authenticated, redirecting to /login');
      return '/login';
    }

    print('  ✓ Allowing access to $currentLocation');
    return null;
  }

  static final router = GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(
        path: '/splash',
        name: 'splash',
        pageBuilder: (context, state) =>
            MaterialPage(key: state.pageKey, child: const SplashScreen()),
      ),
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        pageBuilder: (context, state) =>
            MaterialPage(key: state.pageKey, child: const OnboardingScreen()),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        pageBuilder: (context, state) =>
            MaterialPage(key: state.pageKey, child: const SignInScreen()),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        pageBuilder: (context, state) =>
            MaterialPage(key: state.pageKey, child: const SignUpScreen()),
      ),
      GoRoute(
        path: '/home',
        name: 'home',
        pageBuilder: (context, state) =>
            MaterialPage(key: state.pageKey, child: const MainHomeScreen()),
      ),
      GoRoute(
        path: '/admin/auth-settings',
        name: 'auth-settings',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: BlocProvider(
            create: (context) => AuthConfigCubit(
              AuthConfigService(
                supabaseUrl: dotenv.env['SUPABASE_URL']!,
                serviceRoleKey: dotenv.env['SUPABASE_SERVICE_ROLE_KEY']!,
              ),
            ),
            child: const AuthSettingsScreen(),
          ),
        ),
      ),
    ],

    redirect: (context, state) {
      return _redirectLogic(context, state);
    },
    refreshListenable: GoRouterRefreshStream(_supabase.auth.onAuthStateChange),
    debugLogDiagnostics: true,
  );
}
