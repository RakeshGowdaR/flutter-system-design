# Dependency Injection in Flutter

## Why DI Matters

Without DI, classes create their own dependencies — impossible to test or swap implementations.

## get_it (Service Locator)

```dart
final getIt = GetIt.instance;

void setupDI() {
  // Core — singletons
  getIt.registerLazySingleton<Dio>(() => Dio(BaseOptions(baseUrl: Environment.apiUrl)));
  getIt.registerLazySingleton<ApiClient>(() => ApiClient(getIt<Dio>()));

  // Repositories — lazy singletons
  getIt.registerLazySingleton<UserRepository>(() => UserRepositoryImpl(getIt<ApiClient>()));

  // Services
  getIt.registerLazySingleton<AuthService>(() => AuthService(getIt<UserRepository>()));

  // Cubits — factory (new instance each time)
  getIt.registerFactory<LoginCubit>(() => LoginCubit(getIt<AuthService>()));
}
```

## Registration Types

| Type | Lifecycle | Use For |
|------|-----------|---------|
| `registerSingleton` | Created immediately, lives forever | Analytics, ErrorHandler |
| `registerLazySingleton` | Created on first access, lives forever | ApiClient, Repositories |
| `registerFactory` | New instance every time | Cubits, ViewModels |

## For Testing

```dart
// Replace real implementations with mocks
getIt.registerLazySingleton<UserRepository>(() => MockUserRepository());
```

Dependencies point inward: Presentation → Domain → Data → Core. Never the reverse.
