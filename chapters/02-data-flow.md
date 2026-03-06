# Chapter 2: Data Flow & State Management

## The Core Question

> "Where does state live, who owns it, and how does it move?"

If you can't answer this clearly for your app, you'll end up with bugs where the UI shows stale data, duplicate API calls, or state that gets out of sync between screens.

## Types of State in a Flutter App

Not all state is equal. Different types need different solutions.

```
┌──────────────────────────────────────────────────────┐
│                     App State                        │
│  Auth status, user profile, theme, locale            │
│  Scope: Entire app  │  Lifetime: App session         │
│  Solution: Global provider / Riverpod / GetIt        │
├──────────────────────────────────────────────────────┤
│                   Feature State                      │
│  Product list, cart items, chat messages              │
│  Scope: Feature / flow  │  Lifetime: While in flow   │
│  Solution: Cubit / Bloc / StateNotifier              │
├──────────────────────────────────────────────────────┤
│                    Screen State                      │
│  Form input, scroll position, selected tab           │
│  Scope: Single screen  │  Lifetime: While on screen  │
│  Solution: StatefulWidget / useState (hooks)         │
├──────────────────────────────────────────────────────┤
│                  Ephemeral State                     │
│  Animation progress, hover state, focus              │
│  Scope: Single widget  │  Lifetime: Momentary        │
│  Solution: StatefulWidget / AnimationController      │
└──────────────────────────────────────────────────────┘
```

**The mistake most developers make:** Using a global state management solution for everything. Your button's hover state doesn't need Bloc.

## Data Flow Patterns

### Pattern 1: Unidirectional Data Flow (Recommended)

Data flows in one direction: **Event → State → UI**

```
User taps "Add to Cart"
       ↓
Widget calls cubit.addToCart(product)
       ↓
Cubit calls cartService.add(product)
       ↓
Service calls repository → API/DB
       ↓
Cubit emits new CartState(items: [...])
       ↓
Widget rebuilds with new state
```

**Why this works:** The UI never modifies state directly. All changes go through the same pipeline, so you can log, debug, and test every transition.

```dart
// State
sealed class CartState {
  const CartState();
}
class CartInitial extends CartState {
  const CartInitial();
}
class CartLoaded extends CartState {
  final List<CartItem> items;
  final double total;
  const CartLoaded({required this.items, required this.total});
}
class CartError extends CartState {
  final String message;
  const CartError(this.message);
}

// Cubit — the single source of truth for cart state
class CartCubit extends Cubit<CartState> {
  final CartService _cartService;
  
  CartCubit(this._cartService) : super(const CartInitial());
  
  Future<void> loadCart() async {
    final result = await _cartService.getCart();
    result.when(
      success: (cart) => emit(CartLoaded(items: cart.items, total: cart.total)),
      failure: (msg, _) => emit(CartError(msg)),
    );
  }
  
  Future<void> addItem(Product product, int quantity) async {
    final currentState = state;
    if (currentState is! CartLoaded) return;
    
    // Optimistic update — update UI immediately
    final optimisticItems = [
      ...currentState.items,
      CartItem(product: product, quantity: quantity),
    ];
    emit(CartLoaded(
      items: optimisticItems,
      total: _calculateTotal(optimisticItems),
    ));
    
    // Then sync with server
    final result = await _cartService.addItem(product.id, quantity);
    result.when(
      success: (cart) => emit(CartLoaded(items: cart.items, total: cart.total)),
      failure: (msg, _) {
        // Revert optimistic update
        emit(currentState);
        // Show error (via a separate mechanism, not state)
      },
    );
  }
}
```

### Pattern 2: Reactive Data Streams

For real-time data (chat, live prices, notifications), use streams instead of request-response.

```
Database / WebSocket → Stream<T> → Cubit → UI

┌─────────┐    Stream<List<Message>>    ┌──────────┐    BlocBuilder    ┌────────┐
│ Database │ ──────────────────────────→ │  Cubit   │ ────────────────→ │  UI    │
│ / API    │                             │          │                   │        │
└─────────┘                             └──────────┘                   └────────┘
```

```dart
class ChatCubit extends Cubit<ChatState> {
  final ChatRepository _chatRepo;
  StreamSubscription? _subscription;
  
  ChatCubit(this._chatRepo) : super(const ChatState.loading());
  
  void watchMessages(String chatId) {
    _subscription?.cancel();
    _subscription = _chatRepo.watchMessages(chatId).listen(
      (messages) => emit(ChatState.loaded(messages)),
      onError: (e) => emit(ChatState.error('Failed to load messages')),
    );
  }
  
  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
```

### Pattern 3: State Synchronization Across Features

When one feature's action affects another feature's state:

```
Example: User adds item to cart (Product screen)
         → Cart badge count should update (App bar)
         → Recommendations should refresh (Home screen)
```

**Option A: Shared Cubit** — Both screens listen to the same CartCubit.

```dart
// Provided at app level, both screens access it
BlocProvider<CartCubit>(
  create: (context) => getIt<CartCubit>()..loadCart(),
  child: MaterialApp(/* ... */),
)
```

**Option B: Event Bus** — Features communicate through events without knowing about each other.

```dart
// Lightweight event bus
class AppEventBus {
  static final _controller = StreamController<AppEvent>.broadcast();
  static Stream<AppEvent> get stream => _controller.stream;
  static void fire(AppEvent event) => _controller.add(event);
}

// Product screen fires event
AppEventBus.fire(CartUpdatedEvent(itemCount: cart.items.length));

// App bar listens
AppEventBus.stream
  .whereType<CartUpdatedEvent>()
  .listen((event) => updateBadge(event.itemCount));
```

**Option C: Repository as Source of Truth** — The repository emits streams, multiple cubits subscribe.

```dart
class CartRepository {
  final _cartStream = BehaviorSubject<Cart>();
  Stream<Cart> get cartStream => _cartStream.stream;
  
  Future<void> addItem(String productId, int qty) async {
    final cart = await _api.addToCart(productId, qty);
    _cartStream.add(cart);  // All listeners get updated
  }
}
```

## Choosing State Management

| Situation | Recommendation | Why |
|-----------|---------------|-----|
| Simple app, few screens | `setState` + `ChangeNotifier` | Low overhead, easy to understand |
| Medium app, team project | **Bloc / Cubit** | Predictable, great DevTools, enforces patterns |
| Complex app, many shared states | **Riverpod** | Compile-safe, auto-dispose, flexible scoping |
| Existing Provider codebase | Stay with Provider | Migration cost rarely justified |

**The honest truth:** Any of these work fine. The architecture around them (layers, repositories, services) matters far more than which state management you pick.

## Anti-Patterns

### 1. State in the Widget Tree Only

```dart
// ❌ State lost on navigation
class ProductScreen extends StatefulWidget {
  // User scrolls through 100 products, navigates to detail, presses back
  // → Scroll position lost, data refetched, user frustrated
}

// ✅ State survives navigation
// Keep the Cubit alive at the right scope (above the navigator)
```

### 2. Business Logic in BlocBuilder

```dart
// ❌ Logic in the UI
BlocBuilder<OrderCubit, OrderState>(
  builder: (context, state) {
    if (state is OrderLoaded) {
      final discountedTotal = state.total * 0.9;  // Business logic in UI!
      final canCheckout = state.items.length > 0 && state.total >= 10;
      // ...
    }
  },
)

// ✅ Logic in the Cubit or Service
// Cubit emits a state that already contains discountedTotal and canCheckout
```

### 3. Multiple Sources of Truth

```dart
// ❌ Cart data stored in 3 places
class CartScreen { List<CartItem> items; }      // Screen has its own copy
class CartCubit { List<CartItem> items; }       // Cubit has a copy
class CartRepository { List<CartItem> cached; } // Repository has a copy
// Which one is correct? Nobody knows.

// ✅ Single source of truth
// CartCubit is THE source. Screen reads from Cubit. Repository only fetches/stores.
```

---

**Next:** [Chapter 3 — Navigation Architecture](03-navigation.md)
