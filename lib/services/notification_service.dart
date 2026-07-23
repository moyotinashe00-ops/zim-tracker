import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// In-app alerting when a zone the user has opted into (via the PULSE tab's
/// "NETWORK SUBSCRIPTIONS") flips status. This uses local notifications
/// fired by the client itself when it detects a change in an active
/// Firestore listener -- it works while the app is open or backgrounded
/// (not force-quit).
///
/// NOTE: this is NOT the same as a true push notification triggered by a
/// server when the app is fully closed. That would require a Cloud
/// Function watching Firestore writes and calling FCM, which needs the
/// project on the Blaze billing plan -- deliberately out of scope for now,
/// same reasoning as the AI Logic free-tier decision earlier. This gets
/// you real alerts for actual usage (app open/backgrounded) at zero cost.
class NotificationService {
  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const settings = InitializationSettings(android: androidSettings, iOS: iosSettings);

    await _plugin.initialize(settings);

    // Android 13+ requires runtime notification permission.
    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    _initialized = true;
  }

  Future<void> showZoneStatusChange(String zoneId, String zoneName, bool isNowOn) async {
    if (!_initialized) await init();

    const androidDetails = AndroidNotificationDetails(
      'grid_status_channel',
      'Grid Status Changes',
      channelDescription: 'Alerts when a zone you follow changes power status',
      importance: Importance.high,
      priority: Priority.high,
    );
    const details = NotificationDetails(android: androidDetails, iOS: DarwinNotificationDetails());

    await _plugin.show(
      zoneId.hashCode, // Stable per-zone notification id so repeat alerts replace rather than stack.
      isNowOn ? '$zoneName: Power Restored' : '$zoneName: Power Off',
      isNowOn
          ? 'Grid status for $zoneName just flipped back ON.'
          : 'Grid status for $zoneName just flipped OFF.',
      details,
    );
  }
}
