# Film/TV Show Tracker

A cross-platform Flutter app to track films and TV shows, discover trending content via TMDB, and manage a personal catalogue.

## Features

- **Trending content** — Movies and TV shows from TMDB on the Home screen
- **Debounced search** — Multi-search across films and series (500ms debounce)
- **Personal catalogue** — Add/remove items persisted on device (bookmark from Home or Search)
- **Watch history** — Films and episodes tracked with watch time, persisted locally
- **Dark mode** — Follows system theme
- **Caching** — In-memory TTL cache to respect TMDB rate limits

## Tech stack

- Flutter 3 / Dart 3
- [TMDB API v3](https://developer.themoviedb.org/docs)
- Dio for HTTP
- Hive for local catalogue and watch history persistence
- Material Design 3 + Google Fonts

## Prerequisites

- Flutter SDK 3.0+
- TMDB API Read Access Token (free at [themoviedb.org/settings/api](https://www.themoviedb.org/settings/api))

## Getting started

```bash
git clone <repository-url>
cd iz-show-time
flutter pub get
cp environment.local.example environment.local
```

Edit `environment.local` and set `TMDB_API_KEY` to your TMDB API Read Access Token. The file is gitignored.

Then launch in debug from the IDE (F5), or:

```bash
flutter run --dart-define-from-file=environment.local
```

Override without a local file:

```bash
flutter run --dart-define=TMDB_API_KEY=your_token_here
```

## Project structure

```
lib/
├── core/
│   ├── cache/           # In-memory cache + API cache wrapper
│   ├── constants/       # API URLs, TTLs, app settings
│   ├── network/         # DioClient
│   ├── routing/         # AppRouter
│   ├── services/        # AppServices singleton
│   ├── background/      # Periodic trending refresh
│   └── theme/
├── data/
│   ├── models/          # Film, TvShow, Episode, Tag
│   ├── repositories/    # Hive user data store
│   └── services/        # TmdbService
└── presentation/
    ├── navigation/      # MainNavigator
    ├── screens/         # Home, Search, Catalogue, Tracking, Settings
    └── widgets/         # MediaCard, DebounceSearchWidget

docs/
├── architecture.md
├── roadmap.md
└── tmdb-integration.md
```

## Documentation

- [Architecture](docs/architecture.md)
- [Roadmap](docs/roadmap.md)
- [TMDB integration](docs/tmdb-integration.md)

## Testing

```bash
flutter analyze lib
flutter test
```

## Known limitations

- Notifications not yet implemented
- TMDB API cache is in-memory only (not persisted across restarts)
- On Flutter Web debug, catalogue persistence requires a fixed port (`--web-port=5555`, already set in `.vscode/launch.json`)

## License

MIT — see [LICENSE](LICENSE).
