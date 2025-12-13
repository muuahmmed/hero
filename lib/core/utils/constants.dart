import 'dart:async';
import 'package:flutter/material.dart';

/// A [ChangeNotifier] that notifies listeners when the provided stream emits.
/// Used to refresh the GoRouter when auth state changes.
class GoRouterRefreshStream extends ChangeNotifier {
  /// Creates a [GoRouterRefreshStream] that listens to the provided stream.
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.listen((dynamic _) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
