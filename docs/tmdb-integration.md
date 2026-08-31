# TMDB Integration

## Setup

1. Create a free account at [themoviedb.org](https://www.themoviedb.org/)
2. Generate an API key (v3) in Settings → API
3. Run the app with:

```bash
flutter run --dart-define=TMDB_API_KEY=your_key_here
```

Keys are read via `AppApiKey.configure()` in `main.dart` and passed to `DioClient`.

## Endpoints used

| Method | Path | Purpose | Cache TTL |
|--------|------|---------|-----------|
| GET | `trending/movie/day` | Home carousel | 12h |
| GET | `trending/tv/day` | Home carousel | 12h |
| GET | `movie/popular` | Discovery | 24h |
| GET | `tv/popular` | Discovery | 12h |
| GET | `search/multi` | Search screen | 2h |
| GET | `movie/{id}` | Details | 30d |
| GET | `tv/{id}` | Details | 30d |
| GET | `tv/{id}/season/{n}` | Episodes | 24h |

## Response parsing

TMDB list endpoints return:

```json
{
  "page": 1,
  "results": [ { "id": 123, "title": "...", ... } ],
  "total_pages": 1
}
```

`TmdbService` extracts the `results` array and maps items via:

- `Film.fromJson()` — movies (`title`, `poster_path`, `vote_average`)
- `TvShow.fromJson()` — TV (`name`, `poster_path`, …)
- `catalogueItemFromSearchJson()` — uses `media_type` from multi-search

## Images

Poster URLs are built with:

```dart
ApiConstants.posterUrl(item.posterPath)
// → https://image.tmdb.org/t/p/w500{path}
```

## Rate limits

Free tier: **40 requests/minute**. The app uses:

1. In-memory cache (avoid repeat calls)
2. `ApiCacheService` request counting
3. Dio retry on HTTP 429

## Error handling

- Missing API key → empty results, message on Home
- Network errors → retry button on Home; error text on Search
- Invalid JSON → skipped items in search results

## Catalogue

Items added from Home/Search are stored in `AppServices.catalogue` (in-memory only). Clearing data is available in Settings → Clear All Data.
