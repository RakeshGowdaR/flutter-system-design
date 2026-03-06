# Multi-Module Architecture

## When You Need It

- 50+ screens, build times >2 minutes
- Multiple teams working on different features
- Changes in one area shouldn't break or rebuild others

## Structure

```
my_app/
├── app/                      # Thin shell: routing, DI, main.dart
├── packages/
│   ├── core/                 # Network, storage, error handling
│   ├── design_system/        # Shared widgets, theme, tokens
│   ├── feature_auth/         # Auth feature (data + domain + presentation)
│   ├── feature_orders/       # Orders feature
│   └── feature_profile/      # Profile feature
```

## Rules

1. **Features never depend on other features** — communicate through core interfaces
2. **Core knows nothing about features**
3. **App package is a thin shell** — routing + DI setup only
4. Use **Melos** (`melos bootstrap`) for managing multi-package repos
5. Each package has its own `pubspec.yaml`, tests, and CI

## Benefits

| Benefit | How |
|---------|-----|
| Faster builds | Only rebuild changed packages |
| Team ownership | Each team owns their feature package |
| Enforced boundaries | Can't accidentally access other package internals |
| Independent testing | Test each package in isolation |

## Communication Between Features

Features don't import each other. Instead:
- Define interfaces in `core` that features implement
- Use events/streams for cross-feature communication
- The `app` layer wires everything together in DI setup
