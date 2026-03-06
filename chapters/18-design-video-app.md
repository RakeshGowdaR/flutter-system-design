# Design a Video Streaming App (Interview Style)

## Requirements

**Functional:** Browse catalog, play videos, quality selection, resume playback, offline downloads.
**Non-functional:** Start playing in <2s, smooth adaptive quality, battery efficient.

## Architecture

```
Presentation: VideoPlayerScreen → VideoPlayerCubit
Domain: VideoService, DownloadService
Data: VideoRepository
  ├── StreamingSource (HLS/DASH URLs from API)
  ├── DownloadSource (local file management)
  └── ProgressSource (watch history in local DB)
```

## Key Decisions

**Video player:** Use `video_player` or `chewie` (wrapper with controls). For production quality, consider `better_player` which supports HLS adaptive streaming out of the box.

**Adaptive streaming (HLS):**
```
Server provides: master.m3u8
  ├── 360p.m3u8  (500 Kbps)
  ├── 720p.m3u8  (2 Mbps)
  └── 1080p.m3u8 (5 Mbps)

Player monitors bandwidth → automatically switches quality
```

**Resume playback:**
```dart
// Save progress periodically
class PlaybackTracker {
  void saveProgress(String videoId, Duration position) {
    // Debounce — save every 10 seconds, not every frame
    _db.upsert('playback', {
      'video_id': videoId,
      'position_ms': position.inMilliseconds,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  Future<Duration?> getResumePosition(String videoId) async {
    final record = await _db.query('playback', where: 'video_id = ?', args: [videoId]);
    return record != null ? Duration(milliseconds: record['position_ms']) : null;
  }
}
```

**Offline downloads:**
- Download video segments to local storage
- Track download progress in local DB
- Use `workmanager` for background downloads
- Manage storage: show size per download, allow deletion

**Thumbnail loading:** Pre-generate sprite sheets on server. Load one image with all thumbnails for scrubbing preview.

## Performance

| Concern | Solution |
|---------|---------|
| Fast start | Begin playing lowest quality immediately, switch up |
| Battery | Pause player when app backgrounded, stop downloads on low battery |
| Storage | Show download size before download, auto-delete watched content |
| Memory | Dispose player on navigation away, don't keep multiple players alive |

## Trade-offs

| Decision | Why |
|----------|-----|
| HLS over DASH | Better iOS support, industry standard for mobile |
| SQLite for watch history | Need structured queries (continue watching, recommendations) |
| Background downloads via workmanager | OS-managed, handles interruptions |
| Client-side quality selection | User control + automatic adaptation |
