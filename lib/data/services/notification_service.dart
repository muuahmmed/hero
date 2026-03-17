import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
  FlutterLocalNotificationsPlugin();

  // ── Initialize ────────────────────────────────────────────────────────────
  Future<void> init() async {
    const androidSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        // Handle tap on notification if needed
        debugPrint('Notification tapped: ${details.payload}');
      },
    );

    // Request permissions for Android 13+
    await _plugin
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  // ── Show Order Status Notification ───────────────────────────────────────
  Future<void> showOrderStatusNotification({
    required int orderId,
    required String newStatus,
  }) async {
    final title = _getTitle(newStatus);
    final body = _getBody(orderId, newStatus);
    final color = _getColor(newStatus);

    const androidDetails = AndroidNotificationDetails(
      'order_status_channel',
      'Order Status',
      channelDescription: 'Notifications for order status updates',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      styleInformation: BigTextStyleInformation(''),
      enableLights: true,
      enableVibration: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _plugin.show(
      orderId, // use orderId as notification id
      title,
      body,
      details,
      payload: 'order_$orderId',
    );
  }

  // ── Show General Notification ─────────────────────────────────────────────
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'general_channel',
      'General',
      channelDescription: 'General app notifications',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _plugin.show(id, title, body, details, payload: payload);
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  String _getTitle(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return '✅ Order Confirmed!';
      case 'shipped':
        return '🚚 Order Shipped!';
      case 'delivered':
        return '🎉 Order Delivered!';
      case 'cancelled':
        return '❌ Order Cancelled';
      default:
        return '📦 Order Update';
    }
  }

  String _getBody(int orderId, String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return 'Your order #$orderId has been confirmed and is being prepared.';
      case 'shipped':
        return 'Your order #$orderId is on the way! Track it in My Orders.';
      case 'delivered':
        return 'Your order #$orderId has been delivered. Enjoy your supplements! 💪';
      case 'cancelled':
        return 'Your order #$orderId has been cancelled. Contact support for help.';
      default:
        return 'Your order #$orderId status has been updated to $status.';
    }
  }

  Color _getColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return const Color(0xFF3B82F6);
      case 'shipped':
        return Colors.purple;
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }
}