# Roadmap

## Current status (~50% complete)

### Done

- [x] Project structure (`core/`, `data/`, `presentation/`)
- [x] Unified domain models with TMDB JSON parsing
- [x] `TmdbService` — trending, search, details, episodes
- [x] In-memory cache with TTL
- [x] UI wired to live TMDB data (Home, Search)
- [x] Catalogue (add/remove from Search and Home)
- [x] Persistent catalogue and watch history (Hive)
- [x] Background trending prefetch
- [x] Named routing for Search deep links

### In progress / next

- [ ] Episode watch tracking UI
- [ ] Local/push notifications for new episodes
- [ ] Image caching (`cached_network_image`)
- [ ] Tag management UI
- [ ] Offline search fallback

## Phase plan

### Phase 1 — Foundation (complete)

App shell, navigation, themes, TMDB integration, catalogue in memory.

### Phase 2 — Persistence & notifications (in progress)

- [x] Hive for catalogue and watch progress
- [ ] Background episode checks
- [ ] `flutter_local_notifications` integration

### Phase 3 — Polish & social

- Recommendations
- Statistics dashboard
- Share/watch party features

## Development workflow

1. Add models in `lib/data/models/`
2. Extend `TmdbService` for new endpoints
3. Expose data via `AppServices` if shared across screens
4. Build UI in `lib/presentation/screens/` and `widgets/`

## Testing

```bash
flutter test
flutter analyze lib
```

Run with API key for manual integration checks:

```bash
flutter run --dart-define=TMDB_API_KEY=your_key
```
