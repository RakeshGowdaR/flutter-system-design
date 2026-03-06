# Push Notifications Architecture

## The Flow

```
Backend event → Backend sends to FCM/APNs → Device receives
    ├── App foreground → Show in-app banner, update state
    ├── App background → Show system notification
    └── App terminated → Show system notification
         ↓ user taps
    App opens → deep link to relevant screen
```

## Setup (Firebase Cloud Messaging)

```dart
class NotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  Future<void> initialize() async {
    await _fcm.requestPermission();

    // Get and register device token
    final token = await _fcm.getToken();
    await _api.registerDeviceToken(token!);
    _fcm.onTokenRefresh.listen((t) => _api.registerDeviceToken(t));

    // Foreground: show in-app banner (NOT system notification)
    FirebaseMessaging.onMessage.listen(_handleForeground);

    // Background tap: navigate to relevant screen
    FirebaseMessaging.onMessageOpenedApp.listen(_handleTap);

    // Terminated tap: check for initial message
    final initial = await _fcm.getInitialMessage();
    if (initial != null) _handleTap(initial);
  }

  void _handleTap(RemoteMessage message) {
    final route = message.data['route'];  // '/orders/ORD-123'
    if (route != null) router.go(route);
  }
}
```

## Key Decisions

- **Token management:** Send to backend on every app launch (tokens can change)
- **Foreground:** Always use in-app UI, never system notification
- **Navigation on tap:** Deep link from notification payload data
- **Silent notifications:** Use for background data sync
- **Topics:** Subscribe users to relevant topics (promotions, order_updates)
