# Deep Linking

## What It Is

Deep links open specific screens from external sources (browser, email, push notifications).

```
https://myapp.com/product/abc-123 → App opens → ProductScreen(id: 'abc-123')
```

## Types

| Type | Example | Fallback |
|------|---------|----------|
| Custom scheme | `myapp://product/123` | App Store / Play Store |
| Universal Links (iOS) | `https://myapp.com/product/123` | Website |
| App Links (Android) | `https://myapp.com/product/123` | Website |

**Use HTTPS-based links.** They work everywhere and fall back to your website.

## With GoRouter

GoRouter handles deep links automatically:

```dart
GoRoute(
  path: '/product/:id',
  builder: (_, state) => ProductScreen(id: state.pathParameters['id']!),
)
```

When the OS delivers `https://myapp.com/product/abc-123`, GoRouter matches it.

## Platform Setup

**iOS:** Host `apple-app-site-association` on your domain, add Associated Domains entitlement.

**Android:** Host `assetlinks.json` on your domain, add intent filter with `autoVerify="true"`.

## Tips

- Every deep-linkable screen should work from an ID alone (no object passing)
- Handle missing data gracefully (product deleted, order cancelled)
- Test: `adb shell am start -a android.intent.action.VIEW -d "https://myapp.com/product/123"`
- Test: `xcrun simctl openurl booted "https://myapp.com/product/123"`
