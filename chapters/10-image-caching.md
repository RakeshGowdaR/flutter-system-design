# Image Loading & Caching

## The Architecture

```
Request image URL
    ↓
Memory cache (instant) → Hit? → Display
    ↓ Miss
Disk cache (fast) → Hit? → Display + add to memory cache
    ↓ Miss
Network download → Display + add to both caches
```

## Implementation

```dart
CachedNetworkImage(
  imageUrl: product.imageUrl,
  placeholder: (_, __) => const ShimmerPlaceholder(),
  errorWidget: (_, __, ___) => const Icon(Icons.broken_image),
  maxHeightDiskCache: 500,  // Resize on disk
)
```

## Performance Tips

| Tip | Why |
|-----|-----|
| Request correct size from API | Don't download 4K for 100px thumbnail |
| Use `cacheHeight`/`cacheWidth` on `Image` widget | Decode at display size, save memory |
| Use `ListView.builder` | Only builds visible items, disposes offscreen images |
| Pre-cache critical images | `precacheImage()` for above-the-fold images |
| Clear cache periodically | `DefaultCacheManager().emptyCache()` |

## Memory Management

`ListView.builder` handles image lifecycle — images offscreen are disposed. Don't manually hold references to all images in state.

Avoid `Image.network` in performance-critical lists — use `CachedNetworkImage` for proper caching and placeholder support.
