# IzShowTime

Cross-platform Flutter app to discover films and TV shows, build a personal catalogue, track what you watch, and get alerts when new episodes air.

Metadata, posters, cast, seasons, and watch-provider info come from [The Movie Database (TMDb)](https://www.themoviedb.org/).

## Features

- **Home** — Daily trending films and shows from TMDb, plus a **Continue Watching** section for titles in your catalogue
- **Search** — Multi-search across movies and series, with filters, sorting, and pagination
- **Media details** — Poster, overview, cast, seasons/episodes, similar titles, and watch providers in a detail sheet
- **Personal catalogue** — Add titles from Home or Search; filter by favorites, in-progress, film/TV; sort and view watch-time stats
- **Watch history** — Mark films and episodes as watched; history and runtime stay on device
- **Favorites & followed shows** — Star titles in the catalogue; follow series to receive new-episode alerts
- **Local notifications** — Background checks (WorkManager) notify you when followed shows get new episodes
- **Theme** — Material 3 light/dark mode following the system setting
- **Caching** — In-memory TTL cache for TMDb responses to reduce calls and respect rate limits

## Technologies

| Area | Choice |
|------|--------|
| Framework | Flutter 3 / Dart 3 |
| UI | Material Design 3, Google Fonts |
| Networking | [Dio](https://pub.dev/packages/dio) → [TMDb API v3](https://developer.themoviedb.org/docs) |
| Local persistence | [Hive](https://pub.dev/packages/hive) / hive_flutter (catalogue, watch history) |
| Notifications | [flutter_local_notifications](https://pub.dev/packages/flutter_local_notifications) |
| Background work | [WorkManager](https://pub.dev/packages/workmanager) (episode checks) |
| i18n | `flutter_localizations` + generated l10n (English) |
| Architecture | Layered: `presentation/` → `AppServices` → `TmdbService` / Hive store |

See [docs/architecture.md](docs/architecture.md) and [docs/tmdb-integration.md](docs/tmdb-integration.md) for more detail.

## Sources & attribution

This product uses TMDb and the TMDb APIs but is not endorsed, certified, or otherwise approved by TMDb.

Film and TV metadata and images are provided by **[The Movie Database (TMDb)](https://www.themoviedb.org/)**. IzShowTime is an independent project and has no official affiliation with TMDb.

- Website: [https://www.themoviedb.org](https://www.themoviedb.org/)
- API docs: [https://developer.themoviedb.org](https://developer.themoviedb.org/)
- Logos & attribution guidelines: [https://www.themoviedb.org/about/logos-attribution](https://www.themoviedb.org/about/logos-attribution)
- API terms of use: [https://www.themoviedb.org/api-terms-of-use](https://www.themoviedb.org/api-terms-of-use)

In the app, TMDb attribution appears in the page header (“powered by TMDb”) and in **Settings**, alongside the official disclaimer and logo assets under `assets/images/` and `assets/icons/`.

## Prerequisites

- Flutter SDK 3.0+
- A TMDb API Read Access Token (free at [themoviedb.org/settings/api](https://www.themoviedb.org/settings/api))

## Getting started

```bash
git clone <repository-url>
cd iz-show-time
flutter pub get
cp environment.local.example environment.local
```

Edit `environment.local` and set `TMDB_API_KEY` to your TMDb API Read Access Token. The file is gitignored.

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
│   ├── background/      # Background scheduling (trending refresh, WorkManager)
│   ├── cache/           # In-memory TTL cache
│   ├── config/          # API key resolution
│   ├── constants/       # API URLs, TTLs, app settings
│   ├── network/         # DioClient
│   ├── notifications/   # New-episode policy and checks
│   ├── routing/         # AppRouter
│   ├── services/        # AppServices singleton
│   └── theme/
├── data/
│   ├── models/          # Film, TvShow, Episode, catalogue items, media details
│   ├── repositories/    # Hive user data store
│   └── services/        # TmdbService
└── presentation/
    ├── navigation/      # MainNavigator (Home, Search, Catalogue, Settings)
    ├── screens/         # Home, Search, Catalogue, Settings
    └── widgets/         # MediaCard, detail sheet, filters, stats

docs/
├── architecture.md
├── roadmap.md
└── tmdb-integration.md

site/                    # Support + privacy pages (GitHub Pages)
├── index.html
├── privacy.html
├── styles.css
└── assets/
```

## Documentation

- [Architecture](docs/architecture.md)
- [Roadmap](docs/roadmap.md)
- [TMDb integration](docs/tmdb-integration.md)

## Support & privacy (App Store)

Static pages live in [`site/`](site/) and publish to GitHub Pages:

- Support: https://kobaruakiba.github.io/iz-show-time/
- Privacy policy: https://kobaruakiba.github.io/iz-show-time/privacy.html

Use these URLs in App Store Connect (*Support URL* and *Privacy Policy URL*). After the first merge to `main`, set the repo **Settings → Pages** source to **GitHub Actions** if it is not already enabled.

## Testing

```bash
flutter analyze lib
flutter test
```

## Known limitations

- TMDb API cache is in-memory only (not persisted across restarts); non-catalogue caches are also purged at least every ~6 months for [API Terms](https://www.themoviedb.org/api-terms-of-use) compliance
- On Flutter Web debug, catalogue persistence requires a fixed port (`--web-port=5555`, already set in `.vscode/launch.json`)
- Production Flutter Web needs a backend proxy (TMDb does not allow direct browser CORS)

## License

MIT — see [LICENSE](LICENSE).

**Author and copyright holder:** Mirko Corba  
Copyright (c) 2026 Mirko Corba. All rights in this project’s original source code and documentation are held by Mirko Corba. The MIT license grants others permission to use, modify, and redistribute the Software subject to that license; it does not transfer ownership. This notice asserts authorship and copyright ownership of the work as expressed in this repository; it does not claim inventive originality beyond copyright in that expression. Third-party libraries and services (e.g. Flutter packages, TMDb) remain under their own terms.
