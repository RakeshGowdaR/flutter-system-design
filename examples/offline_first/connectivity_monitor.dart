import 'dart:async';
import 'dart:io';

/// Monitors actual internet connectivity (not just WiFi/cellular status).
///
/// connectivity_plus only tells you if a network interface is available,
/// NOT if the internet is actually reachable. This class does a real check.

class ConnectivityMonitor {
  final _controller = StreamController<bool>.broadcast();
  Timer? _timer;
  bool _lastKnownStatus = true;

  Stream<bool> get onStatusChange => _controller.stream;
  bool get isOnline => _lastKnownStatus;

  void startMonitoring({Duration interval = const Duration(seconds: 10)}) {
    _checkConnectivity();
    _timer = Timer.periodic(interval, (_) => _checkConnectivity());
  }

  Future<void> _checkConnectivity() async {
    try {
      final result = await InternetAddress.lookup('example.com')
          .timeout(const Duration(seconds: 3));
      final online = result.isNotEmpty && result[0].rawAddress.isNotEmpty;

      if (online != _lastKnownStatus) {
        _lastKnownStatus = online;
        _controller.add(online);
      }
    } catch (_) {
      if (_lastKnownStatus) {
        _lastKnownStatus = false;
        _controller.add(false);
      }
    }
  }

  void dispose() {
    _timer?.cancel();
    _controller.close();
  }
}
