# Pagination & Infinite Scroll

## The Architecture

```
UI (ListView.builder) → PaginatedCubit → Repository → API (?page=1&limit=20)
       ↑                      ↓
  ScrollListener         emits state with:
  (near bottom)         items, isLoadingMore, hasReachedEnd
```

## State Design

```dart
class PaginatedState<T> {
  final List<T> items;
  final bool isLoading;        // Initial load
  final bool isLoadingMore;    // Loading next page
  final bool hasReachedEnd;    // No more pages
  final String? error;
  final int currentPage;
}
```

## Scroll Detection

```dart
NotificationListener<ScrollNotification>(
  onNotification: (notification) {
    final metrics = notification.metrics;
    if (metrics.pixels >= metrics.maxScrollExtent - 200) {
      context.read<ProductListCubit>().loadNextPage();
    }
    return false;
  },
  child: ListView.builder(
    itemCount: state.items.length + (state.hasReachedEnd ? 0 : 1),
    itemBuilder: (context, index) {
      if (index == state.items.length) return const LoadingIndicator();
      return ProductCard(product: state.items[index]);
    },
  ),
)
```

## Pagination Types

| Type | Format | Best For |
|------|--------|---------|
| Offset | `?page=2&limit=20` | Simple lists, total count needed |
| Cursor | `?after=item_abc&limit=20` | Real-time feeds, large datasets |
| Keyset | `?created_before=2024-01-15T00:00:00Z&limit=20` | Time-sorted data |

## Tips

- **Pre-fetch** at 200-500px from bottom, not at the very end
- **Pull-to-refresh** resets to page 1
- **Guard** against duplicate loadMore calls with `isLoadingMore` check
- **Shimmer loading** for initial load, small spinner for subsequent pages
- **Cache pages** in local DB for instant display on screen revisit
