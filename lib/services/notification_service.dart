import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class NotificationService {
  static final FlutterLocalNotificationsPlugin
      _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  static bool _isInitialized = false;

  // Initialize the notification service
  static Future<void> initialize() async {
    if (_isInitialized) return;

    print('🔔 Initializing notification service...');

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
      macOS: initializationSettingsIOS,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        print('Notification tapped: ${response.payload}');
        await _handleNotificationTap(response.payload);
      },
    );

    _isInitialized = true;
    print('✅ Notification service initialized');
  }

  // Show local notification
  static Future<void> showLocalNotification({
    required String title,
    required String body,
    String? payload,
    int id = 0,
  }) async {
    await initialize();

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'product_channel',
      'Product Notifications',
      channelDescription: 'Notifications for product-related activities',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      styleInformation: DefaultStyleInformation(true, true),
    );

    const DarwinNotificationDetails iosPlatformChannelSpecifics =
        DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iosPlatformChannelSpecifics,
      macOS: iosPlatformChannelSpecifics,
    );

    await _flutterLocalNotificationsPlugin.show(
      id,
      title,
      body,
      platformChannelSpecifics,
      payload: payload,
    );

    print('📱 Local notification sent: $title - $body');
  }

  // Show product created notification
  static Future<void> showProductCreatedNotification({
    required String productName,
    required double price,
    required String category,
  }) async {
    final title = '🎉 Product Created!';
    final body = '$productName (\$$price) in $category is now available';

    final payload = json.encode({
      'type': 'product_created',
      'productName': productName,
      'price': price,
      'category': category,
      'timestamp': DateTime.now().toIso8601String(),
    });

    await showLocalNotification(
      title: title,
      body: body,
      payload: payload,
      id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
    );
  }

  // Handle notification tap
  static Future<void> _handleNotificationTap(String? payload) async {
    if (payload == null) return;

    try {
      final data = json.decode(payload);
      print('Notification tapped with data: $data');

      // Handle different notification types
      switch (data['type']) {
        case 'product_created':
          // Navigate to products page or show product details
          print('Product created notification tapped: ${data['productName']}');
          break;
        default:
          print('Unknown notification type: ${data['type']}');
      }
    } catch (e) {
      print('Error handling notification tap: $e');
    }
  }

  // Get notification history (for existing compatibility)
  static Future<List<Map<String, dynamic>>> getNotifications({
    required String sellerId,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notificationsJson = prefs.getString('notifications_$sellerId');

      if (notificationsJson == null) {
        return [];
      }

      final List<dynamic> decodedList = json.decode(notificationsJson);
      return decodedList
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    } catch (e) {
      print('Error getting notifications: $e');
      return [];
    }
  }

  // Save notification to local storage
  static Future<void> saveNotification({
    required String sellerId,
    required Map<String, dynamic> notification,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notificationsJson = prefs.getString('notifications_$sellerId');

      List<Map<String, dynamic>> notifications = [];
      if (notificationsJson != null) {
        final List<dynamic> decodedList = json.decode(notificationsJson);
        notifications =
            decodedList.map((item) => Map<String, dynamic>.from(item)).toList();
      }

      notifications.insert(0, notification); // Add to beginning

      // Keep only last 50 notifications
      if (notifications.length > 50) {
        notifications = notifications.take(50).toList();
      }

      await prefs.setString(
          'notifications_$sellerId', json.encode(notifications));
      print('✅ Notification saved to local storage');
    } catch (e) {
      print('❌ Error saving notification: $e');
    }
  }

  // Mark notification as read (for existing compatibility)
  static Future<void> markAsRead(String notificationId, String sellerId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notificationsJson = prefs.getString('notifications_$sellerId');

      if (notificationsJson == null) return;

      List<Map<String, dynamic>> notifications = [];
      final List<dynamic> decodedList = json.decode(notificationsJson);
      notifications =
          decodedList.map((item) => Map<String, dynamic>.from(item)).toList();

      // Find and mark notification as read
      final index = notifications.indexWhere((n) => n['id'] == notificationId);
      if (index != -1) {
        notifications[index]['read'] = true;
        await prefs.setString(
            'notifications_$sellerId', json.encode(notifications));
      }
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  // Request notification permissions
  static Future<bool> requestPermissions() async {
    await initialize();

    final bool? result = await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    return result ?? false;
  }

  // Add notification method (for backward compatibility)
  static Future<void> addNotification(Map<String, dynamic> notification) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sellerId = prefs.getString('user_id') ??
          prefs.getString('current_user_id') ??
          'default_user';

      await saveNotification(
        sellerId: sellerId,
        notification: notification,
      );
    } catch (e) {
      print('Error adding notification: $e');
    }
  }
}
