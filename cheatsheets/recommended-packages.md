# Recommended Packages

Tried-and-tested packages for common needs. Prioritizing stability, maintenance, and community adoption.

> **Rule:** Every package you add is a dependency you maintain. If the standard library or 50 lines of code can do it, skip the package.

---

## Networking

| Need | Package | Why |
|------|---------|-----|
| HTTP client | `dio` | Interceptors, retry, file upload, cancel |
| Simple HTTP | `http` | Lighter than Dio, fine for simple apps |
| WebSocket | `web_socket_channel` | Standard, works everywhere |
| Connectivity check | `connectivity_plus` | WiFi/cellular status monitoring |

## State Management

| Need | Package | Why |
|------|---------|-----|
| Cubit / Bloc | `flutter_bloc` | Battle-tested, great DevTools |
| Riverpod | `flutter_riverpod` | Compile-safe, auto-dispose |
| Simple shared state | `provider` | Built into Flutter ecosystem |

## Local Storage

| Need | Package | Why |
|------|---------|-----|
| SQLite (relational) | `drift` | Type-safe, reactive streams, migrations |
| Key-value (simple) | `shared_preferences` | Quick settings, flags |
| Secure storage | `flutter_secure_storage` | Tokens, sensitive data (Keychain/Keystore) |
| NoSQL / documents | `hive` | Fast, no native dependencies |

## Navigation

| Need | Package | Why |
|------|---------|-----|
| Declarative routing | `go_router` | Official Flutter team, deep linking |
| Code generation routing | `auto_route` | Type-safe, less boilerplate |

## Dependency Injection

| Need | Package | Why |
|------|---------|-----|
| Service locator | `get_it` | Simple, works with any state management |
| Injectable (codegen) | `injectable` | Code generation for get_it |

## UI / Design

| Need | Package | Why |
|------|---------|-----|
| Image loading + cache | `cached_network_image` | Placeholder, error, disk cache |
| SVG rendering | `flutter_svg` | Standard SVG support |
| Shimmer loading | `shimmer` | Skeleton loading screens |
| Pull to refresh | `pull_to_refresh` | Customizable refresh indicator |
| Infinite scroll | Built into `ListView.builder` | No package needed |

## Code Generation

| Need | Package | Why |
|------|---------|-----|
| JSON serialization | `json_serializable` + `json_annotation` | Type-safe fromJson/toJson |
| Immutable models | `freezed` | copyWith, sealed unions, equality |
| Build runner | `build_runner` | Required for code generation |

## Firebase / Backend

| Need | Package | Why |
|------|---------|-----|
| Push notifications | `firebase_messaging` | FCM — industry standard |
| Crash reporting | `firebase_crashlytics` | Or `sentry_flutter` |
| Analytics | `firebase_analytics` | Or `mixpanel_flutter` |
| Remote config | `firebase_remote_config` | Feature flags, A/B testing |

## Testing

| Need | Package | Why |
|------|---------|-----|
| Mocking | `mocktail` | No code generation, clean syntax |
| Bloc testing | `bloc_test` | Built-in state/event assertions |
| Network mocking | `http_mock_adapter` (for Dio) | Mock API responses |
| Golden tests | `golden_toolkit` | Visual regression testing |

---

## Packages to Avoid

| Package | Why | Alternative |
|---------|-----|-------------|
| `get` (GetX) | Does too much, encourages bad patterns | Pick focused packages |
| `dio_http_cache` | Unmaintained | Build your own with interceptor |
| Any package with <70% pub score | Likely unmaintained | Check pub.dev score first |
| Any package not null-safe | Incompatible with modern Dart | Find alternatives |

## Before Adding Any Package

Ask yourself:
1. Can I do this with the standard library? (Often yes)
2. Is this package actively maintained? (Check last commit date)
3. What's the pub.dev score? (Aim for 120+)
4. How many dependencies does it pull in? (Less is better)
5. Does my team know how to use it? (Training cost is real)
