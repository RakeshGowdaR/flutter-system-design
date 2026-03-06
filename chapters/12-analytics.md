# Analytics & Logging

## The Pattern

Abstract analytics so you can swap providers and disable in debug:

```dart
abstract class AnalyticsService {
  void logEvent(String name, {Map<String, dynamic>? params});
  void logScreenView(String screenName);
  void setUserId(String id);
}

class FirebaseAnalyticsImpl implements AnalyticsService { /* real */ }
class DebugAnalyticsImpl implements AnalyticsService { /* prints to console */ }
```

## What to Track

| Category | Examples |
|----------|---------|
| Screen views | Every screen open |
| User actions | button_tap, search, add_to_cart |
| Business events | order_placed, subscription_started |
| Errors | api_error, crash |
| Performance | screen_load_time, api_latency |

## Automatic Screen Tracking

```dart
class AnalyticsObserver extends NavigatorObserver {
  final AnalyticsService _analytics;
  AnalyticsObserver(this._analytics);

  @override
  void didPush(Route route, Route? previous) {
    if (route.settings.name != null) {
      _analytics.logScreenView(route.settings.name!);
    }
  }
}
```

## Rules

- Never block UI for analytics — fire and forget
- Consistent naming: `snake_case`, past tense for actions (`order_placed`)
- Include context: `{screen: 'checkout', button: 'place_order'}`, not just `button_tap`
- Don't over-track — every event costs storage and creates noise
