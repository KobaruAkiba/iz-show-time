# 🎬 Caching System Documentation

## Overview

The TMDB API's free tier allows only **40 requests per minute** (2,400 per hour). Without proper caching, the app would hit rate limits within minutes. This caching system solves that problem through a multi-layer approach.

---

## 🏗️ Architecture: 3-Layer Cache

```
┌─────────────────────────────────────────────────────────────┐
│                    L1: In-Memory Cache                       │
│  - HashMap with TTL tracking                                │
│  - Fastest access (O(1))                                    │
│  - TTL by data type:                                        │
│    • Movies/TV Shows: 24 hours                              │
│    • TV Episodes: 24 hours                                  │
│    • Search results: 2 hours                                │
│    • Details: 30 days                                       │
└─────────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────────┐
│                    L2: Persistent Cache                      │
│  - Hive database (JSON files)                               │
│  - Never auto-expires (manual refresh on demand)            │
│  - Files stored in app directory                            │
│    • movies.hive      - All cached movie data               │
│    • episodes.hive    - All episode data                    │
│    • search.hive      - Search query results                │
└─────────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────────┐
│                    L3: Remote API                            │
│  - TMDB API (only called when cache miss)                   │
│  - Rate limit guard prevents bans                           │
│  - Automatic retry with backoff                             │
└─────────────────────────────────────────────────────────────┘
```

---

## 🔄 How It Works

### **Request Flow:**

1. **Check Memory Cache** (Fastest)
   - Look for data in `_memoryCache` HashMap
   - If found and not expired → Return immediately ✓
   
2. **Check Persistent Cache** (Hive boxes)
   - If memory miss, check Hive boxes on disk
   - Found → Update memory cache, return ✓

3. **Make API Call** (Slowest)
   - No cache hit → Make network request
   - Store in both memory + persistent cache
   - Return to caller

4. **Request Deduplication** (Bonus!)
   - If same request made within 2 seconds → Return cached result
   - Prevents duplicate API calls for rapid-fire requests

---

## 🎯 Cache TTL by Data Type

| Data Type          | TTL      | Why?                                  | File Location      |
|--------------------|----------|---------------------------------------|-------------------|
| **Popular Movies** | 24h      | Can change daily                     | movies.hive       |
| **Movie Details**  | 30 days  | Rarely changes                       | movies.hive       |
| **TV Shows**       | 12h      | Trending changes frequently          | movies.hive       |
| **TV Details**     | 30 days  | Static info                          | movies.hive       |
| **Search Results** | 2 hours  | Trends change hourly                 | search.hive       |
| **Episodes**       | 24h      | New episodes daily                   | episodes.hive     |
| **Airing Schedule**| Daily    | For new episode detection            | episodes.hive     |

---

## 📊 Rate Limiting Strategy

### **Per-Minute Window:**
```dart
// Every minute, reset the counter
if (now.difference(windowStart).inMinutes >= 60) {
  windowStart = now;
  requestsThisWindow = 0;
}

// Allow up to 40 requests per window
if (requestsThisWindow < 40) {
  makeRequest(); // ✅ Allowed
  requestsThisWindow++;
} else {
  await _handleRateLimit(); // ⏸️ Wait for window reset
}
```

### **Automatic Backoff:**
When rate limit (429) hit:
1. Check how many seconds into the window we are
2. Wait until window resets
3. Retry automatically (exponential backoff)
4. Never show user a "ban" message

---

## 🚀 Background Tasks

### **Notification Cycle (Every 4 Hours):**
```
┌─────────────────────────────────────────┐
│ Every 4 hours, app runs:                │
│                                         │
│ 1. Check trending movies                │
│    - Fetch if cache older than 12h      │
│    - Store in Hive                      │
│                                         │
│ 2. Check trending TV shows              │
│    - Same logic                         │
│    - Updates user's collection          │
│                                         │
│ 3. Check new episodes                   │
│    - Compare airing schedule            │
│    - Notify user of new content         │
└─────────────────────────────────────────┘
```

### **Initial Startup (Every App Launch):**
1. Fetch trending movies → Cache for 24h
2. Fetch trending TV shows → Cache for 12h
3. Start background timer

---

## 💾 Data Persistence

### **Hive File Structure:**
```
/app/documents/
├── cache/
│   ├── movies.hive       # Movie data (JSON)
│   ├── episodes.hive     # Episode data (JSON)
│   └── search.hive       # Search results (JSON)
└── user/                 # User preferences, catalogue, tags
```

### **File Format (example):**
```json
{
  "12345": {
    "id": 12345,
    "title": "Example Movie",
    "poster_path": "/path/to/poster.jpg",
    "vote_average": 7.8,
    "cached_at": "2024-01-15T10:30:00Z"
  }
}
```

---

## 🛠️ Usage Examples

### **Fetch Trending Movies:**
```dart
import 'data/services/movie_service.dart';
import 'core/services_wrapper/app_services.dart';

final movieService = AppServices().movieService;

try {
  final movies = await movieService.getTrendingMovies();
  
  if (movies.isEmpty) {
    print('No trending movies available');
  } else {
    // Use first 10 for display
    final featuredMovies = movies.take(10).toList();
  }
} catch (e) {
  // Handle network error
  print('Failed to fetch: $e');
}
```

### **Search with Automatic Caching:**
```dart
final searchResults = await appServices.movieService.searchMovies('Avatar', page: 1);

// If "Avatar" searched within last 2 hours → Uses cache!
// Otherwise → Makes API call, then caches for 2 hours
```

### **Check Cache Statistics:**
```dart
final stats = AppServices().backgroundTaskRunner.getStatistics();
print('Active requests: ${stats['active_requests']}');
print('Requests this window: ${stats['requests_this_window']}');
```

---

## 📈 Performance Metrics

### **Expected Request Reduction:**

| Scenario                    | Without Cache | With Cache | Improvement |
|-----------------------------|---------------|------------|-------------|
| App open (trending load)    | 2 requests    | 1 request  | 50%         |
| User search                  | N requests    | 1 request* | Up to 99%   |
| Same screen navigation       | N requests    | 0 requests | 100%        |
| Daily episode checks (7 days)| 28 requests  | 2 requests | 93%         |

_*First search only, subsequent searches in 2h use cache_

### **Network Savings:**
- Typical day with caching: ~5-10 API calls
- Typical day without caching: ~100+ API calls (would hit rate limits!)

---

## 🔧 Advanced Features

### **Manual Cache Clear:**
```dart
await AppServices().clearAllData();
// Clears memory cache only (Hive data persists)
```

### **Force Refresh:**
```dart
// Clear specific item from cache, force new API call
cacheManager.remove('movie:${movieId}');
final movie = await movieService.getMovieDetails(movieId); // Fresh fetch
```

### **Offline Mode Support:**
- App works even without internet (shows cached data)
- Background tasks only run when network available
- User can browse catalogue offline

---

## 🐛 Troubleshooting

### **"Cache not working"** → Check logs:
```
💾 Cache HIT: /movie/popular    ← Good!
❌ API request failed           ← Problem - check network
```

### **Rate limit error (429):**
- System automatically waits and retries
- No user action needed
- Logs will show: "⏱️ Rate limit: waiting XXs..."

### **Cache size too large:**
- Hive data persists forever for offline access
- Manual cleanup available if needed
- Recommended to keep (improves performance)

---

## 🔒 Security & Privacy

- **All cache files are local** - Not uploaded to any server
- **Hive encrypted storage** - Optional configuration
- **No API keys in logs** - Rate limit errors show generic messages
- **User data separated** - Cache only stores public TMDB content

---

## 📝 Implementation Notes

### **Why Hive over SharedPreferences?**
- **Performance**: Faster reads/writes for large datasets
- **Type safety**: Compile-time type checking
- **JSON support**: Native serialization/deserialization
- **Scalability**: Handles 10,000+ entries without issues

### **Why not SQLite?**
- Overkill for this use case (mostly read-heavy)
- Hive's JSON format simpler for TMDB data
- Lower memory footprint
- Sufficient for <1GB of cached content

---

## 🎯 Future Improvements

### **Potential Enhancements:**
1. **Smart prefetching** - Load next trending movies before user navigates
2. **Preloading on idle** - Cache trending when app not active
3. **Selective cache invalidation** - Force refresh specific categories
4. **Cache compression** - Reduce disk footprint by 70%+
5. **Remote backup sync** - Export cache to cloud storage

### **Not Implemented (On Purpose):**
- ❌ Remote caching (CDN) - Not worth the complexity
- ❌ Peer-to-peer sync - Privacy concern + unnecessary
- ❌ Adaptive bitrate streaming for cached content - Overengineering

---

## 📞 Support

For cache-related issues, check:
1. `lib/core/cache/cache_manager.dart` - Cache logic
2. `lib/core/cache/api_cache_service.dart` - API wrapper with rate limiting
3. Background logs showing cache hits/misses
4. Network tab for actual API calls made

**Expected behavior**: Most requests should show "💾 Cache HIT" in logs. If not, check network connection or try again later.

---

**Last Updated**: Today  
**Version**: 1.0.0  
**Author**: Development Team  
