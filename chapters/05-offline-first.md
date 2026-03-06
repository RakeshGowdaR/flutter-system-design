# Chapter 5: Offline-First Architecture

## The Problem

Your user is on a train, enters a tunnel, loses signal. What happens?

```
❌ Most apps: Loading spinner... Error screen... Data gone.
✅ Offline-first: App keeps working. Changes sync when back online.
```

Offline-first isn't just for "offline apps." It's about **resilience**. Even in cities, mobile connections drop for seconds at a time. An offline-first app feels faster and more reliable even with good connectivity.

## The Architecture

```
┌──────────────────────────────────────────────────────────┐
│                       UI Layer                           │
│                  Always reads from local DB               │
├──────────────────────────────────────────────────────────┤
│                    Repository Layer                       │
│           Coordinates between local and remote            │
├──────────┬───────────────────────────────┬───────────────┤
│ Local DB │        Sync Manager           │  Remote API   │
│ (Drift/  │  Queues changes, syncs when   │  (REST /      │
│  Hive)   │  connectivity is restored     │  GraphQL)     │
└──────────┴───────────────────────────────┴───────────────┘
```

**Key principle:** The local database is the single source of truth for the UI. The remote API is just a sync target.

## Strategy 1: Cache-First (Simple)

Good for read-heavy apps. Show cached data immediately, refresh from API in the background.

```dart
class ProductRepository {
  final ApiClient _api;
  final LocalDatabase _db;
  
  /// Returns cached data immediately, then refreshes from API.
  Stream<List<Product>> watchProducts() async* {
    // 1. Emit cached data immediately
    final cached = await _db.getProducts();
    if (cached.isNotEmpty) {
      yield cached;
    }
    
    // 2. Fetch fresh data from API
    try {
      final remote = await _api.get('/products');
      final products = (remote.data as List)
          .map((json) => Product.fromJson(json))
          .toList();
      
      // 3. Update local DB
      await _db.saveProducts(products);
      
      // 4. Emit fresh data
      yield products;
    } catch (e) {
      // Offline or error — cached data is already showing
      if (cached.isEmpty) {
        throw AppException('No cached data and no internet connection');
      }
    }
  }
}
```

### In the Cubit

```dart
class ProductListCubit extends Cubit<ProductListState> {
  final ProductRepository _repo;
  
  ProductListCubit(this._repo) : super(const ProductListState.loading());
  
  Future<void> loadProducts() async {
    await for (final products in _repo.watchProducts()) {
      emit(ProductListState.loaded(
        products: products,
        isRefreshing: false,
      ));
    }
  }
}
```

The user sees cached products instantly. Fresh data replaces it silently when available.

## Strategy 2: Sync Queue (Full Offline-First)

For apps where users create/edit data offline and sync later (field apps, note-taking, task management).

```
User creates a task offline
       ↓
Task saved to local DB (immediately visible)
       ↓
Change added to sync queue
       ↓
When online → sync queue processes changes
       ↓
Server confirms → mark as synced
Server rejects → show conflict
```

### The Sync Queue

```dart
/// Represents a pending change that needs to sync to the server.
class SyncOperation {
  final String id;
  final String type;         // 'create', 'update', 'delete'
  final String entity;       // 'task', 'note', 'comment'
  final String entityId;
  final Map<String, dynamic> data;
  final DateTime createdAt;
  final int retryCount;
  final SyncStatus status;   // pending, syncing, failed, synced
  
  SyncOperation({
    required this.id,
    required this.type,
    required this.entity,
    required this.entityId,
    required this.data,
    required this.createdAt,
    this.retryCount = 0,
    this.status = SyncStatus.pending,
  });
}

enum SyncStatus { pending, syncing, failed, synced }
```

### The Sync Manager

```dart
class SyncManager {
  final LocalDatabase _db;
  final ApiClient _api;
  final ConnectivityMonitor _connectivity;
  
  StreamSubscription? _connectivitySub;
  
  /// Start listening for connectivity changes.
  void initialize() {
    _connectivitySub = _connectivity.onStatusChange.listen((isOnline) {
      if (isOnline) {
        syncPendingChanges();
      }
    });
  }
  
  /// Queue a change for syncing.
  Future<void> queueChange({
    required String type,
    required String entity,
    required String entityId,
    required Map<String, dynamic> data,
  }) async {
    final operation = SyncOperation(
      id: uuid.v4(),
      type: type,
      entity: entity,
      entityId: entityId,
      data: data,
      createdAt: DateTime.now(),
    );
    
    await _db.insertSyncOperation(operation);
    
    // Try to sync immediately if online
    if (await _connectivity.isOnline) {
      syncPendingChanges();
    }
  }
  
  /// Process all pending sync operations.
  Future<void> syncPendingChanges() async {
    final pending = await _db.getPendingSyncOperations();
    
    for (final op in pending) {
      try {
        await _db.updateSyncStatus(op.id, SyncStatus.syncing);
        
        switch (op.type) {
          case 'create':
            await _api.post('/${op.entity}s', data: op.data);
            break;
          case 'update':
            await _api.put('/${op.entity}s/${op.entityId}', data: op.data);
            break;
          case 'delete':
            await _api.delete('/${op.entity}s/${op.entityId}');
            break;
        }
        
        await _db.updateSyncStatus(op.id, SyncStatus.synced);
        
      } catch (e) {
        final newRetryCount = op.retryCount + 1;
        
        if (newRetryCount >= 5) {
          await _db.updateSyncStatus(op.id, SyncStatus.failed);
        } else {
          await _db.updateRetryCount(op.id, newRetryCount);
          await _db.updateSyncStatus(op.id, SyncStatus.pending);
        }
      }
    }
  }
  
  void dispose() {
    _connectivitySub?.cancel();
  }
}
```

### Using It in a Repository

```dart
class TaskRepository {
  final LocalDatabase _db;
  final SyncManager _syncManager;
  
  /// Create a task — works offline.
  Future<Task> createTask(String title, String description) async {
    final task = Task(
      id: uuid.v4(),          // Generate ID locally
      title: title,
      description: description,
      createdAt: DateTime.now(),
      syncStatus: SyncStatus.pending,
    );
    
    // Save locally (immediately available in UI)
    await _db.insertTask(task);
    
    // Queue for server sync
    await _syncManager.queueChange(
      type: 'create',
      entity: 'task',
      entityId: task.id,
      data: task.toJson(),
    );
    
    return task;
  }
  
  /// Watch tasks — always reads from local DB.
  Stream<List<Task>> watchTasks() {
    return _db.watchAllTasks();  // Reactive stream from Drift/Floor
  }
}
```

## Showing Sync Status in the UI

Users should know what's synced and what's pending:

```dart
class TaskListItem extends StatelessWidget {
  final Task task;
  
  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(task.title),
      trailing: _syncIndicator(task.syncStatus),
    );
  }
  
  Widget _syncIndicator(SyncStatus status) {
    return switch (status) {
      SyncStatus.synced  => const Icon(Icons.cloud_done, color: Colors.green, size: 16),
      SyncStatus.pending => const Icon(Icons.cloud_upload, color: Colors.orange, size: 16),
      SyncStatus.syncing => const SizedBox(
        width: 16, height: 16,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
      SyncStatus.failed  => const Icon(Icons.cloud_off, color: Colors.red, size: 16),
    };
  }
}
```

## Conflict Resolution

What happens when two users edit the same item offline?

```
Alice (offline): Changes task title to "Buy groceries"
Bob (offline):   Changes task title to "Buy food"
Both go online → which one wins?
```

### Strategies

| Strategy | How It Works | Good For |
|----------|-------------|----------|
| **Last write wins** | Most recent timestamp wins | Simple apps, low-conflict data |
| **Server wins** | Server version always takes precedence | When server is authoritative |
| **Client wins** | Local version always takes precedence | Personal data (notes, drafts) |
| **Manual merge** | Show both versions, user decides | Collaborative editing |
| **Field-level merge** | Merge non-conflicting fields automatically | Complex documents |

For most apps, **last write wins** is sufficient. Don't over-engineer conflict resolution until you actually have conflicts.

## Connectivity Monitoring

```dart
class ConnectivityMonitor {
  final Connectivity _connectivity = Connectivity();
  
  Stream<bool> get onStatusChange {
    return _connectivity.onConnectivityChanged.map((result) {
      return result != ConnectivityResult.none;
    });
  }
  
  Future<bool> get isOnline async {
    // Don't just check connectivity — verify actual internet access
    try {
      final result = await InternetAddress.lookup('example.com')
          .timeout(const Duration(seconds: 3));
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }
}
```

**Important:** `connectivity_plus` tells you if WiFi/cellular is connected, not if the internet actually works. Always verify with a real lookup for critical operations.

## Trade-offs

| Approach | Pros | Cons |
|----------|------|------|
| Cache-first | Simple, covers 90% of cases | No offline writes |
| Sync queue | Full offline support | Complex, conflict handling needed |
| Local-first (CRDTs) | Automatic conflict resolution | Very complex, overkill for most apps |

**Recommendation:** Start with cache-first. Add a sync queue only for features that truly need offline writes. Don't go full CRDT unless you're building a collaborative editor.

---

**Next:** [Chapter 6 — Pagination & Infinite Scroll](06-pagination.md)
