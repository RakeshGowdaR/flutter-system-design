# App Performance

## Build Performance

- Use `const` constructors — prevents unnecessary rebuilds
- Use `ListView.builder` — only builds visible items
- Extract widgets into classes, not methods — enables framework optimization
- Avoid `Opacity` widget — use color opacity or `AnimatedOpacity`
- Use `BlocSelector` for granular rebuilds instead of full `BlocBuilder`

## Profiling

```bash
flutter run --profile    # Profile mode (real performance, debug tools)
```

DevTools Performance tab: look for frames >16ms (below 60fps). Wide bars in flame chart = slow functions.

## Memory

DevTools Memory tab: watch for growing memory that never decreases (leak).

Common leaks:
- `StreamSubscription` not cancelled in `dispose()`
- `AnimationController` not disposed
- `ScrollController` not disposed
- Global caches without eviction

## App Size

```bash
flutter build apk --analyze-size    # See what's taking space
```

Fixes: remove unused packages/assets, `--split-per-abi` for Android, compress images, deferred imports for large features.

## Common Anti-Patterns

| Problem | Fix |
|---------|-----|
| Rebuilding entire tree on state change | `BlocSelector` / `context.select` |
| Building widgets in methods | Extract to `const` StatelessWidget classes |
| Large images at full resolution | Resize server-side or use `cacheHeight` |
| Parsing large JSON on main thread | Use `compute()` for isolate processing |
| Deep widget nesting with clips | Simplify tree, reduce `ClipRRect` layers |
