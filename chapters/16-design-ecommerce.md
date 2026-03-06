# Design an E-Commerce App (Interview Style)

## Requirements

**Functional:** Product catalog, search, cart, checkout, order tracking, user reviews.
**Non-functional:** Fast image loading, works on slow networks, offline product browsing.

## Architecture

```
┌──────────────────────────────────────────┐
│            Presentation Layer            │
│  HomeScreen  ProductScreen  CartScreen   │
│  HomeCubit   ProductCubit   CartCubit    │
├──────────────────────────────────────────┤
│              Domain Layer                │
│  ProductService  CartService  OrderService│
├──────────────────────────────────────────┤
│               Data Layer                 │
│  ProductRepo    CartRepo    OrderRepo    │
│  (API + Cache)  (Local)     (API)        │
├──────────────────────────────────────────┤
│              Infrastructure              │
│  ApiClient  LocalDB  ImageCache  Auth    │
└──────────────────────────────────────────┘
```

## Key Decisions

**Product catalog:** Cache-first. Store products in local DB, refresh from API in background. Users see products instantly on app open.

**Search:** Debounced input (300ms), cancel previous search on new keystroke. Show recent searches while typing.

**Cart:** Local-first. Cart lives in local storage. Sync with server on checkout (handles price changes, out-of-stock).

**Image loading:** `CachedNetworkImage` with placeholder shimmer. Request thumbnail URLs from API, not full-size images. Pre-cache product images for above-the-fold items.

**Checkout flow:** Multi-step form with state preserved across steps. Validate stock and prices server-side before payment. Show clear error if item became unavailable.

**Order tracking:** Polling or WebSocket for status updates. Cache order history in local DB.

## Trade-offs

| Decision | Why |
|----------|-----|
| SQLite for product cache | Structured queries, full-text search support |
| Cart in local storage (not server) | Works offline, instant add/remove |
| Cursor pagination for catalog | Better than offset for scrolling through 10K+ products |
| Optimistic UI for cart actions | Feels instant, sync errors are rare |
