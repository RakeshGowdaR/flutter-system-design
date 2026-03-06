# Chapter 1: App Architecture Overview

## The Problem With No Architecture

Every Flutter app starts small. One screen, one API call, everything in `main.dart`. Then it grows:

```
Week 1:  main.dart (200 lines) → "This is fine"
Month 2: main.dart (2,000 lines) → "I should refactor soon"
Month 6: 50 files, all importing each other → "I'm afraid to change anything"
```

Architecture isn't about being fancy. It's about **being able to change your app without breaking it**.

## The Layered Architecture

The most battle-tested approach for Flutter apps. Four layers, each with clear rules about what it can and cannot do.

```
┌──────────────────────────────────────────────────────────────┐
│  PRESENTATION LAYER                                          │
│  Screens, Widgets, State Management (Cubit/Bloc/Riverpod)   │
│  Rule: No business logic. No API calls. Only UI.             │
├──────────────────────────────────────────────────────────────┤
│  DOMAIN LAYER                                                │
│  Services, Use Cases, Business Rules                         │
│  Rule: No Flutter imports. No HTTP. Pure Dart logic.         │
├──────────────────────────────────────────────────────────────┤
│  DATA LAYER                                                  │
│  Repositories, Data Sources (API, DB, Cache)                 │
│  Rule: No UI. Returns domain models, not JSON.               │
├──────────────────────────────────────────────────────────────┤
│  CORE / INFRASTRUCTURE                                       │
│  Network client, Storage, DI, Error handling, Constants      │
│  Rule: Shared utilities. No feature-specific code.           │
└──────────────────────────────────────────────────────────────┘
```

### The Dependency Rule

**Dependencies point downward. Never upward.**

```
Presentation → depends on → Domain → depends on → Data → depends on → Core
Presentation ✗ never depends on ✗ Data (directly)
Data ✗ never depends on ✗ Presentation
```

This means:
- A widget never calls an API directly
- A repository never shows a snackbar
- A service never knows about Cubit or Bloc

### Folder Structure

```
lib/
├── app/
│   ├── app.dart                    # MaterialApp, theme, global providers
│   ├── router.dart                 # Route definitions
│   └── di.dart                     # Dependency injection setup
│
├── core/
│   ├── network/
│   │   ├── api_client.dart         # Dio configuration
│   │   ├── api_endpoints.dart      # All URLs in one place
│   │   └── interceptors/
│   │       ├── auth_interceptor.dart
│   │       └── retry_interceptor.dart
│   ├── storage/
│   │   ├── local_storage.dart      # SharedPreferences wrapper
│   │   └── secure_storage.dart     # FlutterSecureStorage wrapper
│   ├── error/
│   │   ├── app_exception.dart      # Typed exception hierarchy
│   │   ├── error_handler.dart      # Global error handling
│   │   └── result.dart             # Result<T> type
│   └── constants/
│       ├── app_constants.dart
│       └── api_constants.dart
│
├── features/
│   ├── auth/
│   │   ├── data/
│   │   │   ├── auth_repository.dart
│   │   │   ├── auth_repository_impl.dart
│   │   │   └── models/
│   │   │       ├── user_model.dart
│   │   │       └── token_model.dart
│   │   ├── domain/
│   │   │   ├── auth_service.dart
│   │   │   └── entities/
│   │   │       └── user.dart
│   │   └── presentation/
│   │       ├── screens/
│   │       │   ├── login_screen.dart
│   │       │   └── register_screen.dart
│   │       ├── cubits/
│   │       │   ├── auth_cubit.dart
│   │       │   └── auth_state.dart
│   │       └── widgets/
│   │           ├── login_form.dart
│   │           └── social_login_buttons.dart
│   │
│   ├── home/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   │
│   └── settings/
│       ├── data/
│       ├── domain/
│       └── presentation/
│
├── shared/
│   ├── widgets/
│   │   ├── app_button.dart
│   │   ├── loading_indicator.dart
│   │   └── error_view.dart
│   ├── extensions/
│   │   ├── context_extensions.dart
│   │   └── string_extensions.dart
│   └── utils/
│       ├── validators.dart
│       └── formatters.dart
│
└── main.dart
```

## How Data Flows Through the Layers

Let's trace a "load user profile" request:

```
1. ProfileScreen
   └── calls profileCubit.loadProfile("user-123")

2. ProfileCubit (Presentation Layer)
   └── emits Loading state
   └── calls profileService.getProfile("user-123")

3. ProfileService (Domain Layer)
   └── applies business rules (can this user view this profile?)
   └── calls userRepository.getUser("user-123")

4. UserRepositoryImpl (Data Layer)
   └── checks local cache → miss
   └── calls apiClient.get("/users/user-123")
   └── maps JSON → UserModel → User (domain entity)
   └── stores in cache
   └── returns User

5. Back up the chain:
   ProfileService → returns Result<User>
   ProfileCubit → emits Loaded(user) state
   ProfileScreen → rebuilds with user data
```

### The Model Separation

Many developers use one model everywhere. That's a mistake at scale.

```
API Response (JSON)          →  UserModel (data layer)
                                  - Has fromJson / toJson
                                  - Mirrors API structure exactly
                                  - Lives in features/auth/data/models/

UserModel.toDomain()         →  User (domain entity)
                                  - Clean Dart class
                                  - Only fields the app needs
                                  - No serialization logic
                                  - Lives in features/auth/domain/entities/

User                         →  Used by services, cubits, widgets
                                  - Everyone depends on the domain entity
                                  - API changes only affect UserModel
```

Why bother? When the API changes field names, you only update `UserModel.fromJson()`. The rest of the app doesn't change.

## Architecture Mistakes to Avoid

### 1. God Widget

```dart
// ❌ Everything in one widget
class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  User? user;
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _loadProfile();  // API call in widget
  }

  Future<void> _loadProfile() async {
    final response = await http.get(/*...*/);  // HTTP in widget
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      setState(() {
        user = User.fromJson(json);  // Parsing in widget
        isLoading = false;
      });
    }
    // No error handling, no caching, untestable
  }
}
```

### 2. Circular Dependencies

```
auth/ imports home/ imports settings/ imports auth/ → 💥

Fix: Extract shared logic into core/ or shared/
```

### 3. Feature Coupling

```dart
// ❌ Cart feature directly accesses Product feature's repository
class CartService {
  final ProductRepository productRepo;  // Tight coupling

  Future<void> addToCart(String productId) async {
    final product = await productRepo.getProduct(productId);
    // ...
  }
}

// ✅ Cart feature receives what it needs via its own interface
class CartService {
  final CartRepository cartRepo;

  Future<void> addToCart(CartItem item) async {
    await cartRepo.addItem(item);
  }
}
// The screen/cubit that orchestrates this gets the product data 
// and creates the CartItem before passing it to CartService
```

## When to Keep It Simple

Not every app needs four layers and dependency injection. Here's a rough guide:

| App Size | Recommended Architecture |
|----------|-------------------------|
| 1-5 screens, solo developer | StatefulWidget + services. Don't over-engineer. |
| 5-15 screens, small team | Feature folders + Cubit + Repository. The sweet spot. |
| 15-50 screens, multiple teams | Full layered architecture with DI. Worth the upfront cost. |
| 50+ screens, large org | Multi-module with separate packages per feature. |

Start simple. Refactor when the pain is real, not theoretical.

---

**Next:** [Chapter 2 — Data Flow & State Management](02-data-flow.md)
