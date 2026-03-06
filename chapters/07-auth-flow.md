# Chapter 7: Authentication Flow

## The Problem

Auth seems simple until it isn't:

- Where do you store tokens?
- How do you refresh expired tokens transparently?
- What happens when the refresh token itself expires?
- How do you protect routes from unauthenticated users?
- How does the app know the user is logged in on cold start?

## The Architecture

```
┌─────────────────────────────────────────────────────┐
│                    App Router                       │
│      Redirects based on AuthCubit state             │
├─────────────────────────────────────────────────────┤
│                    AuthCubit                        │
│    Single source of truth for auth state            │
├─────────────────────────────────────────────────────┤
│                   AuthService                       │
│     Login, logout, register, token management       │
├─────────────┬───────────────────────┬───────────────┤
│ AuthRepo    │   TokenStorage        │  ApiClient    │
│ (API calls) │   (Secure Storage)    │  (Interceptor)│
└─────────────┴───────────────────────┴───────────────┘
```

## Token Storage

**Never store tokens in SharedPreferences.** Use FlutterSecureStorage (Keychain on iOS, EncryptedSharedPreferences on Android).

```dart
class TokenStorage {
  final FlutterSecureStorage _storage;
  
  TokenStorage(this._storage);
  
  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';
  
  Future<String?> getAccessToken() => _storage.read(key: _accessTokenKey);
  Future<String?> getRefreshToken() => _storage.read(key: _refreshTokenKey);
  
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _storage.write(key: _accessTokenKey, value: accessToken);
    await _storage.write(key: _refreshTokenKey, value: refreshToken);
  }
  
  Future<void> clearTokens() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
  }
  
  Future<bool> hasTokens() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }
}
```

## Auth State

```dart
sealed class AuthState {
  const AuthState();
}

/// Initial state — checking if user has saved session
class AuthLoading extends AuthState {
  const AuthLoading();
}

/// User is authenticated
class Authenticated extends AuthState {
  final User user;
  const Authenticated(this.user);
}

/// User is not authenticated
class Unauthenticated extends AuthState {
  final String? message;  // Optional: "Session expired", "Please log in"
  const Unauthenticated({this.message});
}
```

## Auth Cubit

```dart
class AuthCubit extends Cubit<AuthState> {
  final AuthService _authService;
  final TokenStorage _tokenStorage;
  
  AuthCubit(this._authService, this._tokenStorage)
      : super(const AuthLoading());
  
  /// Called on app start — check if user has a valid session.
  Future<void> checkAuthStatus() async {
    final hasTokens = await _tokenStorage.hasTokens();
    
    if (!hasTokens) {
      emit(const Unauthenticated());
      return;
    }
    
    // Validate token by fetching current user
    final result = await _authService.getCurrentUser();
    result.when(
      success: (user) => emit(Authenticated(user)),
      failure: (msg, _) {
        // Token invalid or expired — clear and redirect to login
        _tokenStorage.clearTokens();
        emit(const Unauthenticated(message: 'Session expired'));
      },
    );
  }
  
  Future<void> login(String email, String password) async {
    emit(const AuthLoading());
    
    final result = await _authService.login(email, password);
    result.when(
      success: (user) => emit(Authenticated(user)),
      failure: (msg, _) => emit(Unauthenticated(message: msg)),
    );
  }
  
  Future<void> logout() async {
    await _authService.logout();
    emit(const Unauthenticated());
  }
  
  /// Called when a 401 is received and refresh fails.
  void onSessionExpired() {
    emit(const Unauthenticated(message: 'Your session has expired'));
  }
}
```

## Route Protection

Using GoRouter, redirect based on auth state:

```dart
final router = GoRouter(
  refreshListenable: authCubit.stream.toListenable(),
  redirect: (context, state) {
    final authState = authCubit.state;
    final isOnAuthPage = state.matchedLocation.startsWith('/auth');
    
    // Still checking auth — show splash
    if (authState is AuthLoading) return null;
    
    // Not authenticated — redirect to login (unless already there)
    if (authState is Unauthenticated && !isOnAuthPage) {
      return '/auth/login';
    }
    
    // Authenticated but on auth page — redirect to home
    if (authState is Authenticated && isOnAuthPage) {
      return '/home';
    }
    
    return null;  // No redirect needed
  },
  routes: [
    GoRoute(path: '/auth/login', builder: (_, __) => const LoginScreen()),
    GoRoute(path: '/auth/register', builder: (_, __) => const RegisterScreen()),
    GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
    GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
  ],
);
```

## Token Refresh Flow

The auth interceptor handles this transparently:

```
API call → 401 Unauthorized
    ↓
Auth Interceptor catches it
    ↓
Has refresh token? ──No──→ Emit Unauthenticated, redirect to login
    ↓ Yes
Call /auth/refresh with refresh token
    ↓
Success? ──No──→ Clear tokens, emit Unauthenticated
    ↓ Yes
Save new tokens
    ↓
Retry original request with new access token
    ↓
Return response to caller (caller never knew token expired)
```

See the [Networking Layer pattern](../flutter-production-patterns/patterns/networking-layer.md) for the interceptor implementation.

## The Complete Flow

```
App launches
    ↓
AuthCubit.checkAuthStatus()
    ↓
Has stored tokens? ──No──→ Unauthenticated → Login Screen
    ↓ Yes
Fetch /users/me with stored token
    ↓
Valid? ──No──→ Try refresh → Still fails? → Clear tokens → Login Screen
    ↓ Yes
Authenticated(user) → Home Screen

User taps "Logout"
    ↓
AuthCubit.logout()
    ↓
Call /auth/logout (server invalidates refresh token)
Clear local tokens
Clear cached user data
    ↓
Unauthenticated → Login Screen
```

## Common Mistakes

### 1. Checking Token Expiry Locally

```dart
// ❌ Don't decode JWT and check expiry yourself
final isExpired = JwtDecoder.isExpired(token);

// Why: server might revoke the token before it expires.
// Always let the server be the authority on token validity.
```

### 2. Storing Auth State in Multiple Places

```dart
// ❌ Auth state in SharedPreferences AND Cubit AND some global variable
bool isLoggedIn = prefs.getBool('is_logged_in');

// ✅ Single source: AuthCubit
// Token existence in SecureStorage is for persistence across app restarts.
// AuthCubit state is what the app actually reads.
```

### 3. Not Clearing Data on Logout

```dart
// ❌ Only clearing tokens
Future<void> logout() async {
  await tokenStorage.clearTokens();
}

// ✅ Clear everything user-specific
Future<void> logout() async {
  await tokenStorage.clearTokens();
  await localDatabase.clearUserData();
  await cache.clear();
  await analytics.reset();
  // Reset any user-scoped cubits/providers
}
```

---

**Next:** [Chapter 8 — Push Notifications](08-push-notifications.md)
