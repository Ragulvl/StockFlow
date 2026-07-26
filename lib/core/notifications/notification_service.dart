import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../logger/app_logger.dart';

class NotificationService {
  NotificationService._internal();
  static final NotificationService instance = NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  /// Initialize Local Notification Plugin & Android Notification Channel
  Future<void> init() async {
    if (_isInitialized) return;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    await _notificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        AppLogger.info("Notification tapped with payload: ${response.payload}", "NotificationService");
      },
    );

    // Request Android 13+ runtime notification permissions
    final androidImplementation = _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    if (androidImplementation != null) {
      await androidImplementation.requestNotificationsPermission();
    }

    _isInitialized = true;
    AppLogger.info("NotificationService initialized successfully", "NotificationService");
  }

  /// Low Stock Alert System Notification (Mobile Status Bar)
  Future<void> showLowStockNotification({
    required String productName,
    required int currentStock,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'stockflow_low_stock_channel',
      'Low Stock Alerts',
      channelDescription: 'Mobile status bar warnings when inventory stock drops low',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      enableVibration: true,
      playSound: true,
    );

    const details = NotificationDetails(android: androidDetails);

    final notificationId = productName.hashCode;
    await _notificationsPlugin.show(
      notificationId,
      '⚠️ Low Stock Warning: $productName',
      'Current stock level is down to $currentStock pieces. Reorder recommended!',
      details,
    );
  }

  /// Daily Sales Performance Mobile Notification
  Future<void> showSalesSummaryNotification({
    required double totalSales,
    required int orderCount,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'stockflow_sales_channel',
      'Daily Sales Highlights',
      channelDescription: 'Summary notifications for daily sales targets and checkout stats',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,

      icon: '@mipmap/ic_launcher',
      enableVibration: true,
    );

    const details = NotificationDetails(android: androidDetails);

    await _notificationsPlugin.show(
      999,
      '📈 Today\'s Store Performance',
      'Total Sales: Rs. ${totalSales.toStringAsFixed(2)} across $orderCount completed orders!',
      details,
    );
  }

  /// General / Test System Notification
  Future<void> showNotification({
    required String title,
    required String body,
    int id = 0,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'stockflow_general_channel',
      'General Store Notifications',
      channelDescription: 'General app system notifications',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      enableVibration: true,
      playSound: true,
    );

    const details = NotificationDetails(android: androidDetails);

    await _notificationsPlugin.show(
      id,
      title,
      body,
      details,
    );
  }
}
