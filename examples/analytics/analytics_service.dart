/// Analytics abstraction layer.
///
/// Swap providers without changing feature code.
/// Disable in debug. Send to multiple providers. Test without side effects.

abstract class AnalyticsService {
  Future<void> logEvent(String name, {Map<String, dynamic>? params});
  Future<void> setUserId(String userId);
  Future<void> setUserProperty(String name, String value);
  Future<void> logScreenView(String screenName);
}

/// Production: sends to Firebase + Mixpanel (or your provider)
class AnalyticsServiceImpl implements AnalyticsService {
  @override
  Future<void> logEvent(String name, {Map<String, dynamic>? params}) async {
    // await _firebase.logEvent(name: name, parameters: params);
    // _mixpanel.track(name, properties: params);
  }

  @override
  Future<void> setUserId(String userId) async {
    // await _firebase.setUserId(id: userId);
  }

  @override
  Future<void> setUserProperty(String name, String value) async {
    // await _firebase.setUserProperty(name: name, value: value);
  }

  @override
  Future<void> logScreenView(String screenName) async {
    // await _firebase.logScreenView(screenName: screenName);
  }
}

/// Debug: prints to console, sends nothing
class DebugAnalyticsService implements AnalyticsService {
  @override
  Future<void> logEvent(String name, {Map<String, dynamic>? params}) async {
    print('[Analytics] $name: $params');
  }

  @override
  Future<void> setUserId(String userId) async {}

  @override
  Future<void> setUserProperty(String name, String value) async {}

  @override
  Future<void> logScreenView(String screenName) async {
    print('[Analytics] Screen: $screenName');
  }
}
