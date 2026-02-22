import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hero/presentation/pages/auth/sign_in.dart';
import 'package:hero/presentation/pages/auth/sign_up.dart';
import 'package:hero/presentation/pages/home_screens/main_home.dart';
import 'package:hero/presentation/pages/on_Borading/on_Boarding_screen.dart';
import 'package:hero/presentation/pages/splash/splash_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AppRoutes {
  static final SupabaseClient _supabase = Supabase.instance.client;

  static String? _redirectLogic(BuildContext context, GoRouterState state) {
    final currentLocation = state.matchedLocation;
    final hasActiveSession = _supabase.auth.currentSession != null;

    if (hasActiveSession &&
        (currentLocation == '/login' || currentLocation == '/register')) {
      return '/home';
    }

    if (!hasActiveSession && currentLocation == '/home') {
      return '/login';
    }

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
    ],
    redirect: (context, state) => _redirectLogic(context, state),
    refreshListenable: GoRouterRefreshStream(_supabase.auth.onAuthStateChange),
  );
}

class GoRouterRefreshStream extends ChangeNotifier {
  late final StreamSubscription<AuthState> _subscription;

  GoRouterRefreshStream(Stream<AuthState> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
