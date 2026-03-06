# Navigation Architecture

## The Problem

Simple apps use `Navigator.push` everywhere. At scale: deep linking doesn't work, routes aren't guarded, and navigation logic is scattered across widgets.

## GoRouter (Recommended)

```dart
final router = GoRouter(
  initialLocation: '/home',
  redirect: (context, state) {
    final isLoggedIn = authCubit.state is Authenticated;
    final isOnLogin = state.matchedLocation == '/login';
    if (!isLoggedIn && !isOnLogin) return '/login';
    if (isLoggedIn && isOnLogin) return '/home';
    return null;
  },
  routes: [
    GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
    ShellRoute(
      builder: (_, __, child) => MainShell(child: child),  // Bottom nav persists
      routes: [
        GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
        GoRoute(path: '/search', builder: (_, __) => const SearchScreen()),
        GoRoute(
          path: '/profile/:userId',
          builder: (_, state) => ProfileScreen(
            userId: state.pathParameters['userId']!,
          ),
        ),
      ],
    ),
    GoRoute(
      path: '/product/:id',
      builder: (_, state) => ProductScreen(id: state.pathParameters['id']!),
    ),
  ],
);
```

## Key Patterns

**Nested Navigation:** `ShellRoute` for bottom navigation that persists while content changes.

**Auth Guard:** `redirect` checks auth state. `refreshListenable` re-evaluates on auth changes.

**Deep Linking:** GoRouter matches URLs to routes automatically. `/product/abc-123` opens ProductScreen.

**Data Passing:** Use path/query params (`/product/123`), NOT objects. Screens fetch data from IDs. This makes deep linking and bookmarking work.

## Rules

- Define all routes in one file (`app/router.dart`)
- Path params for required IDs: `/users/:id`
- Query params for optional filters: `/products?sort=price`
- Never pass complex objects — pass IDs and let the screen fetch

---

**Next:** [Chapter 4 — Dependency Injection](04-dependency-injection.md)
