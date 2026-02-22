import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/app_routes.dart';
import 'config/app_theme.dart';
import 'data/services/dio_helper.dart';
import 'presentation/pages/auth/cubit/auth_cubit.dart';

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..connectionTimeout = const Duration(seconds: 15)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  HttpOverrides.global = MyHttpOverrides();

  await dotenv.load(fileName: "assets/.env");

  final supabaseUrl = dotenv.env['SUPABASE_URL'];
  final supabaseKey = dotenv.env['SUPABASE_PUBLISHABLE_KEY'];
  final serviceRoleKey = dotenv.env['SUPABASE_SERVICE_ROLE_KEY'];

  if (supabaseUrl == null || supabaseKey == null || serviceRoleKey == null) {
    throw Exception('Missing Supabase credentials in .env file');
  }

  // Initialize SDK
  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseKey,
  );

  // Initialize DioHelper for Admin Auth tasks
  DioHelper.init(
    baseUrl: supabaseUrl,
    serviceRoleKey: serviceRoleKey,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AuthCubit(),
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        routerConfig: AppRoutes.router,
      ),
    );
  }
}