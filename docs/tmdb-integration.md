# TMDB Integration

## Setup

1. Create a free account at [themoviedb.org](https://www.themoviedb.org/)
2. Generate an API Read Access Token in Settings → API
3. Copy `environment.local.example` to `environment.local` and set `TMDB_API_KEY`
4. Launch in debug (F5) or run:

```bash
flutter run --dart-define-from-file=environment.local
```

`environment.local` is gitignored. Debug launches in Cursor/VS Code pass `--dart-define-from-file=environment.local` automatically.

Override without a local file:

```bash
flutter run --dart-define=TMDB_API_KEY=your_token_here
```

The token is read via `AppApiKey.configure()` in `main.dart` and sent by `DioClient`:
- **Read Access Token (JWT, starts with `eyJ`)** → `Authorization: Bearer <token>`
- **API Key v3 (32 chars)** → `api_key` query parameter

`ApiConstants.baseUrl` must end with a trailing slash (`https://api.themoviedb.org/3/`) so Dio builds paths like `/3/trending/...` correctly.

### Flutter Web (CORS)

TMDB does not allow direct browser calls. For local web development, launch with Chrome flags that disable web security (configured in `.vscode/launch.json`):

- `--disable-web-security`
- `--user-data-dir=.dart_tool/chrome-dev`

For production web builds you need your own backend proxy.

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

1. In-memory TTL cache (avoid repeat calls; max TTL 30 days)
2. Dio retry on HTTP 429

## TMDB API Terms compliance

- **Attribution**: Settings shows the official disclaimer and logo (links to [themoviedb.org](https://www.themoviedb.org/)); header shows “powered by TMDb”.
- **Cached data**: API responses are in-memory only with TTLs well under 6 months. On every app start, if the last non-catalogue cache purge is missing or older than ~6 months (`StorageConstants.tmdbCacheMaxAge`), the app runs the same path as Settings → Clear Cache Data (memory API cache + Flutter image cache). Catalogue and watch history are never purged by this check.

## Error handling

- Missing API key → empty results, message on Home
- Network errors → retry button on Home; error text on Search
- Invalid JSON → skipped items in search results

## Catalogue

Items added from Home/Search are stored in `AppServices.catalogue` (in-memory only). Clearing data is available in Settings → Clear All Data.
