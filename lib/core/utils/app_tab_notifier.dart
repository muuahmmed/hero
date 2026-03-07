import 'package:flutter/material.dart';

/// A single global ValueNotifier that carries the desired tab index.
///
/// Any file can import this to switch tabs:
///   appTabIndex.value = 2;  // → Cart
///   appTabIndex.value = 3;  // → Profile
///   appTabIndex.value = 0;  // → Home
///
/// main_home.dart listens with ValueListenableBuilder and calls setState.
/// No circular imports — this file imports nothing from the app.
final ValueNotifier<int> appTabIndex = ValueNotifier<int>(0);
