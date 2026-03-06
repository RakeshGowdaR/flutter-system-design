# Background Processing

## The Challenge

Mobile OSes aggressively kill background processes. You can't run code whenever you want.

## Options

| Package | Use Case | Reliability |
|---------|----------|------------|
| `workmanager` | Periodic tasks (sync, cleanup) | OS-scheduled, may be delayed |
| `flutter_background_service` | Long-running (music, GPS) | Foreground service |
| `flutter_local_notifications` | Scheduled notifications | Reliable with exact alarms |
| `compute()` / Isolates | Heavy computation | In-app only |

## workmanager Example

```dart
// Register periodic task
Workmanager().registerPeriodicTask(
  'sync-task', 'syncData',
  frequency: Duration(hours: 1),
  constraints: Constraints(networkType: NetworkType.connected),
);

// Handle task
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task == 'syncData') {
      await SyncManager().syncPendingChanges();
      return true;
    }
    return false;
  });
}
```

## Isolates for Heavy Computation

```dart
// Don't block UI thread
final products = await compute(parseProducts, rawJsonString);

List<Product> parseProducts(String json) {
  return (jsonDecode(json) as List).map((e) => Product.fromJson(e)).toList();
}
```

## Rules

1. Background execution is not guaranteed — the OS decides when
2. Keep background tasks under 30 seconds
3. Use foreground services for user-visible tasks (music, GPS)
4. Test on real devices — emulators don't enforce restrictions
