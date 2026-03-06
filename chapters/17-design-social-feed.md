# Design a Social Media Feed (Interview Style)

## Requirements

**Functional:** Scrollable feed of posts from followed users, like/comment, create posts with text and images, pull-to-refresh.
**Non-functional:** Feed loads in <1s, smooth 60fps scrolling, offline viewing of cached feed.

## Architecture

```
Presentation: FeedScreen → FeedCubit
Domain: FeedService (merges, ranks, filters)
Data: FeedRepository
  ├── RemoteDataSource (REST API, paginated)
  ├── LocalDataSource (SQLite, cached feed)
  └── WebSocketSource (real-time new posts)
```

## Key Decisions

**Feed loading:** Cache-first with background refresh. Open app → show cached feed instantly → fetch new posts from API → prepend to feed.

**Pagination:** Cursor-based (`?before=post_abc&limit=20`). Never use offset — new posts shift everything.

**Real-time updates:** WebSocket for new posts while feed is open. Append to top, show "New posts available" banner (don't auto-scroll — disorienting).

**Image handling:**
- Upload: compress client-side, upload to pre-signed S3 URL
- Display: request thumbnails from CDN, lazy-load full images on tap
- Aspect ratio: server provides dimensions so `ListView` can calculate layout without loading images

**Likes (optimistic):**
```
User taps like → UI updates immediately → API call in background
  Success → done
  Failure → revert UI, show error
```

**Feed ranking:** Server-side. Factors: recency, engagement (likes/comments), user affinity (how often you interact with this person).

## Performance

- `ListView.builder` with `AutomaticKeepAliveClientMixin` for visible posts
- Image caching with `CachedNetworkImage`
- Pre-fetch next page when 5 posts from bottom
- Dispose video players when posts scroll offscreen

## Trade-offs

| Approach | Pros | Cons |
|----------|------|------|
| Pre-computed feed (fan-out on write) | Fast reads | Expensive for users with many followers |
| Compute on read (fan-out on read) | Cheap writes | Slow feed generation |
| Hybrid (recommended) | Best of both | More complex server |
