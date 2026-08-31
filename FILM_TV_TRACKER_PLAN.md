# 🎬 Film/TV Show Tracker Mobile App - Development Plan

## Executive Summary

A cross-platform mobile application that allows users to track films and TV shows, receive notifications for new episodes/seasons, and maintain a personal catalogue with tagging capabilities.

---

## Table of Contents

1. [Technology Stack](#technology-stack)
2. [Architecture Overview](#architecture-overview)
3. [Core Features](#core-features)
4. [Data Models](#data-models)
5. [API Integration](#api-integration)
6. [Notification System](#notification-system)
7. [UI/UX Design](#uiux-design)
8. [Development Phases](#development-phases)
9. [Code Structure](#code-structure)
10. [Security & Privacy](#security--privacy)

---

## Technology Stack

### Cross-Platform Framework Options

| Option | Pros | Cons | Recommendation |
|--------|------|------|----------------|
| **Flutter** | Single codebase, great UI controls, good performance | Larger APK size | ⭐ **RECOMMENDED** |
| **React Native** | JavaScript ecosystem, large community | Native modules needed for advanced features | Good alternative |
| **Kotlin Multiplatform** | Native performance, better Android support | More complex setup | Alternative option |

### Recommended Stack (Flutter)

```yaml
Backend/API:
  - Database: Supabase / Firebase / SQLite (local-first approach)
  
Mobile App:
  - Framework: Flutter 3.0+
  - State Management: Riverpod or Bloc
  - API Client: Dio or Retrofit
  - Local Storage: Hive / Isar / SharedPreferences
  
Features:
  - Notifications: flutter_local_notifications + pushy (for Apple)
  - Search: elastic_search / custom debounce implementation
  - Image Loading: cached_network_image
  - HTTP: dio with retry logic
```

---

## Architecture Overview

### App Structure (Clean Architecture Approach)

```
lib/
├── core/
│   ├── constants/
│   │   ├── app_constants.dart
│   │   └── api_endpoints.dart
│   ├── network/
│   │   ├── dio_client.dart
│   │   └── interceptors/
│   ├── utils/
│   │   ├── debounce_helper.dart
│   │   └── notification_helper.dart
│   └── theme/
│       └── app_theme.dart
├── data/
│   ├── datasources/
│   │   ├── remote/
│   │   │   └── tmdb_datasource.dart
│   │   └── local/
│   │       └── storage_datasource.dart
│   ├── models/
│   │   ├── film_model.dart
│   │   ├── tvshow_model.dart
│   │   ├── user_tracking.dart
│   │   └── tag_model.dart
│   └── repositories/
│       ├── film_repository.dart
│       ├── tvshow_repository.dart
│       └── catalogue_repository.dart
├── domain/
│   ├── entities/
│   ├── usecases/
│   │   ├── get_films.dart
│   │   ├── get_tvshows.dart
│   │   ├── add_to_catalogue.dart
│   │   └── check_new_episodes.dart
│   └── repositories/
├── presentation/
│   ├── screens/
│   │   ├── home/
│   │   ├── catalogue/
│   │   ├── search/
│   │   ├── tracking/
│   │   └── settings/
│   ├── widgets/
│   │   ├── film_card.dart
│   │   ├── tvshow_card.dart
│   │   ├── tag_chip.dart
│   │   └── search_debounce_input.dart
│   ├── providers/
│   │   ├── films_provider.dart
│   │   ├── catalogue_provider.dart
│   │   └── notifications_provider.dart
│   └── pages/
└── main.dart
```

---

## Core Features

### 1. User Catalogue System

#### Functionality
- ✅ Add films to personal catalogue with single button
- ✅ Add TV shows with season tracking
- ✅ Mark episodes as watched
- ✅ Tag items for organization
- ✅ Search within own catalogue

#### Implementation Details
```dart
class CatalogueItem {
  final int id; // User-generated ID
  final String title;
  final MediaType type; // Film or TV Show
  final DateTime addedDate;
  final List<String> tags; // User-defined tags
  bool isWatchingNow;
  final List<EpisodeProgress> episodes; // For TV shows only
}

class EpisodeProgress {
  final int seasonNumber;
  final int episodeNumber;
  final DateTime watchedDate;
  final String? notes;
  final double progressPercentage;
}
```

### 2. Search System

#### Features
- ✅ Debounced search (waits for user to stop typing)
- ✅ Search across: films, TV shows, tags
- ✅ Full-text search support
- ✅ Filter by type (film/TV show)
- ✅ Recent searches history

#### Search Implementation
```dart
// Debounce mechanism example
class DebounceSearchInput extends StatelessWidget {
  final Function(String) onSearch;
  
  @override
  Widget build(BuildContext context) {
    return TextField(
      onChanged: debounce(onSearch, milliseconds: 500),
    );
  }
}

void debounce(Function callback, {int delay}) {
  Timer? timer;
  void execute(String query) {
    if (timer?.isActive == true) return;
    timer = Timer(Duration(seconds: 1), () => callback(query)); // 500ms recommended
  }
}
```

### 3. Notification System

#### Features
- ✅ Check for new episodes every N hours (configurable, default: 4h)
- ✅ Push notifications for new seasons/episodes
- ✅ In-app notification center
- ✅ Smart notifications (not spammy)

#### Implementation
```dart
class EpisodeTracker {
  final List<TVShow> trackedShows;
  
  Future<void> checkNewEpisodes() async {
    for (var show in trackedShows) {
      await fetchLatestEpisodes(show.id);
      if (newEpisodesAvailable) {
        await sendNotification(show);
      }
    }
  }
}

// Schedule periodic checks
final _periodicTask =.periodicTimer(Duration(hours: 4));
```

### 4. Tag System

#### Features
- ✅ Custom tags for user preferences (e.g., "favorite", "rewatch", "spoilers")
- ✅ Tag-based search within catalogue
- ✅ Color-coded tags
- ✅ Auto-tag suggestions based on TMDB genres

---

## Data Models

### Entity Relationships

```
User Catalogue (1) ----(N) Films & TV Shows
   |                              |
   |                              |
(1) ----(N) Tags <--------------(1) --- (N) Tagged Items
```

#### Key Tables/Collections

```yaml
# Local Database Structure (SQLite/Hive)
films:
  - id: int (primary key, user-generated)
  - external_id: int (TMDB ID)
  - title: string
  - overview: text
  - poster_path: string
  - backdrop_path: string
  - rating: float
  - added_date: datetime
  - tags: array<string>

tv_shows:
  - id: int (primary key, user-generated)
  - external_id: int (TMDB ID)
  - title: string
  - overview: text
  - poster_path: string
  - backdrop_path: string
  - first_air_date: date
  - status: enum("ended", "currently airing")
  - added_date: datetime
  - tags: array<string>

episodes:
  - id: int (primary key)
  - show_id: int (foreign key to tv_shows)
  - season_number: int
  - episode_number: int
  - title: string
  - overview: text
  - air_date: date
  - watched: bool
  - watched_at: datetime
  - user_notes: text

tags:
  - id: int (primary key)
  - name: string
  - color: string (hex color for UI)
  - is_default: bool

tag_items:
  - item_id: int (foreign key to films/tv_shows)
  - tag_id: int (foreign key to tags)
```

---

## API Integration

### The Movie Database (TMDB)

#### Free Tier Limits
- **Free Account**: 40 requests/minute, ~3,500/day
- **Production Key**: Higher limits for commercial use

#### Required TMDB Endpoints

```dart
class TMdbService {
  // Search
  Future<SearchResult> search({
    required String query,
    int? page,
  });
  
  // Film Details
  Future<FilmDetails> getFilm(int tmdbId);
  
  // TV Shows
  Future<TVShowDetails> getTVShow(int tmdbId);
  Future<List<Episode>> getTVShowEpisodes(int showId, int seasonNumber);
  Future<bool> isNewEpisodeAvailable(int showId);
  
  // Trending (for home screen)
  Future<List<Film>> getTrendingFilms({String? category});
  Future<List<TVShow>> getTrendingTVShows({String? category});
}

// API Endpoint References:
// https://developers.themoviedb.org/3/documentation/api
```

#### Error Handling Strategy
```dart
enum APIErrorType {
  rateLimit,           // Too many requests
  notFound,            // TMDB ID doesn't exist
  invalidResponse,     // Response format mismatch
  networkError,        // Connection issues
}

class APIResult<T> {
  final bool isSuccess;
  final T? data;
  final APIErrorType error;
  
  factory APIResult.success(T data) => APIResult(isSuccess: true, data: data);
  factory APIResult.error(APIErrorType error) => APIResult(isSuccess: false, error: error);
}
```

---

## Notification System

### Implementation Strategy

#### Firebase Cloud Messaging (FCM)

**Advantages:**
- Cross-platform support
- Free tier available
- Rich push notifications
- Background messaging support

**Setup Steps:**
1. Create Firebase project
2. Generate API keys for Android and iOS
3. Configure `google-services.json` and `GoogleService-Info.plist`
4. Implement token registration
5. Set up notification permissions in app settings

#### Local Notifications (Fallback)
```dart
class LocalNotificationScheduler {
  final List<ScheduledCheck> scheduledChecks;
  
  void scheduleEpisodesCheck() {
    // Schedule next check based on last known episode date
    DateTime nextCheck = DateTime.now().add(const Duration(hours: 4));
    
    localNotifications.schedule(
      id: 'episode_check',
      androidScheduleType: NotificationScheduleType.timeBased,
      scheduledDateTime: nextCheck,
    );
  }
}
```

### Notification Content Template

```dart
class EpisodeNotification {
  final String title;
  final String body;
  final String? imageUrl;
  final int episodeNumber;
  final String seasonNumber;
  
  static const String defaultBody = '🎬 New episode available! Watch it now.';
}

// Example notification:
NotificationData(
  title: '"Breaking Bad" - Season 5, Episode 16',
  body: 'The series finale is finally here!',
  imageUrl: 'https://tmdb.org/path/to/poster.jpg',
)
```

---

## UI/UX Design

### Design Principles
- **Minimalist**: Clean interface with focus on content
- **Responsive**: Adapt to different screen sizes (phones, tablets)
- **Dark Mode**: Support for both light and dark themes
- **Accessibility**: Large touch targets, readable fonts

### Screen Layouts

```
┌─────────────────────────────────────┐
│              Header                  │
│   [Search]  🏠 My Catalogue         │
├─────────────────────────────────────┤
│                                      │
│    Trending Now (Carousel)          │
│      ┌──────┐ ┌──────┐ ┌──────┐    │
│      │  A   │ │  B   │ │  C   │    │
│      └──────┘ └──────┘ └──────┘    │
│                                      │
│    [Add to Catalogue]               │
├─────────────────────────────────────┤
│              Filters                │
│   🎬 Film  📺 TV  ⭐ Rating         │
├─────────────────────────────────────┤
│   ┌───────────────────────────────┐ │
│   │   ┌───────┐ ┌───────┐        │ │
│   │   │ Title │ Tag +    │        │ │
│   │   └───────┘ └───────┘        │ │
│   │   [Watched]  ⏳ Pending      │ │
│   └───────────────────────────────┘ │
├─────────────────────────────────────┤
│           Footer Navigation          │
│   🔍 Search | 📺 Shows | 🎬 Films    │
└─────────────────────────────────────┘
```

### Key Screens

#### 1. Home Screen
- Trending films and TV shows carousel
- Quick search bar with debounce
- Recent additions to catalogue
- "Add to catalogue" quick actions

#### 2. Catalogue Screen
- Grid/List view toggle
- Filter by type (film/TV)
- Tag-based filtering
- Watched episodes progress bar for TV shows

#### 3. Search Results
- Debounced search input
- Type filter tabs
- Recent searches history
- Quick add to catalogue from results

#### 4. Tracking Screen
- List of tracked films/TV shows
- Episode tracking interface (for TV)
- Add/remove from tracking with swipe actions
- Episode progress visualization

#### 5. Settings
- Notification preferences
- Check interval configuration (1h, 3h, 6h, 12h)
- Dark mode toggle
- Theme color picker
- Account/Profile settings
- About & Legal links

---

## Development Phases

### Phase 1: Foundation (Weeks 1-2)

**Goals:**
- [ ] Set up Flutter project structure
- [ ] Configure TMDB API integration
- [ ] Implement local database schema
- [ ] Create basic UI components
- [ ] Set up build configuration

**Deliverables:**
- Working Flutter app with navigation
- TMDB data fetching functionality
- Basic catalogue CRUD operations

### Phase 2: Core Features (Weeks 3-4)

**Goals:**
- [ ] Implement search with debounce
- [ ] Create film/TV show tracking system
- [ ] Build tag management system
- [ ] Add episode tracking for TV shows
- [ ] Implement catalogue filters

**Deliverables:**
- Functional search interface
- Full tracking capabilities
- Tag organization working
- Episode progress tracking

### Phase 3: Notifications (Weeks 5-6)

**Goals:**
- [ ] Integrate Firebase Cloud Messaging
- [ ] Implement episode checking logic
- [ ] Build notification system
- [ ] Set up scheduled background tasks
- [ ] Create notification center UI

**Deliverables:**
- Push notifications working
- Scheduled checks every 4 hours (configurable)
- Notification preferences screen
- In-app notification history

### Phase 4: Polish & Optimization (Weeks 7-8)

**Goals:**
- [ ] Performance optimization
- [ ] Add offline support
- [ ] Implement caching strategies
- [ ] UI/UX refinements
- [ ] Bug fixes and testing

**Deliverables:**
- Optimized app performance
- Offline mode working
- Smooth animations and transitions
- Comprehensive error handling

### Phase 5: Release (Week 9)

**Goals:**
- [ ] Prepare assets and icons
- [ ] Generate app store listings
- [ ] Beta testing with closed group
- [ ] Submit to Google Play Store
- [ ] Submit to Apple App Store

---

## Code Structure

### Example Implementation Snippets

#### Main Entry Point
```dart
// lib/main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'core/network/dio_client.dart';
import 'core/theme/app_theme.dart';
import 'presentation/providers/catalogue_provider.dart';
import 'presentation/providers/notifications_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase for notifications
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Film/TV Tracker',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: MainNavigator(),
    );
  }
}

class MainNavigator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CatalogueProvider()),
        ChangeNotifierProvider(create: (_) => NotificationsProvider()),
      ],
      child: Scaffold(
        body: HomeScreen(),
        bottomNavigationBar: NavigationRail(
          destinations: [
            NavigationRailDestination(icon: Icon(Icons.home), label: Text('Home')),
            NavigationRailDestination(icon: Icon(Icons.search), label: Text('Search')),
            NavigationRailDestination(icon: Icon(Icons.bookmark_border), label: Text('Catalogue')),
            NavigationRailDestination(icon: Icon(Icons.notifications), label: Text('Notifications')),
            NavigationRailDestination(icon: Icon(Icons.settings), label: Text('Settings')),
          ],
        ),
      ),
    );
  }
}
```

#### Debounced Search Widget
```dart
// lib/presentation/widgets/debounce_search.dart
class DebounceSearchInput extends StatefulWidget {
  final Function(String) onSearch;
  
  const DebounceSearchInput({super.key, required this.onSearch});
  
  @override
  State<DebounceSearchInput> createState() => _DebounceSearchInputState();
}

class _DebounceSearchInputState extends State<DebounceSearchInput> {
  Timer? debounceTimer;
  String searchQuery = '';
  bool isSearching = false;
  
  void handleInputChange(String value) {
    if (debounceTimer?.isActive == true) return;
    
    setState(() {
      searchQuery = value;
      isSearching = !value.isEmpty;
    });
    
    debounceTimer?.cancel();
    debounceTimer = Timer(Duration(milliseconds: 500), () {
      if (searchQuery.isNotEmpty && isSearching) {
        widget.onSearch(searchQuery);
      }
    });
  }
  
  @override
  void dispose() {
    debounceTimer?.cancel();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        onChanged: handleInputChange,
        decoration: InputDecoration(
          hintText: 'Search films, shows, tags...',
          prefixIcon: Icon(Icons.search, color: Theme.of(context).colorScheme.primary),
          suffixIcon: searchQuery.isNotEmpty
              ? IconButton(icon: Icon(Icons.clear), onPressed: () => handleInputChange(''))
              : null,
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        ),
      ),
    );
  }
}
```

#### Episode Notification Service
```dart
// lib/core/utils/episode_notifier_service.dart
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class EpisodeNotificationService {
  final FirebaseMessaging _fcm;
  final FlutterLocalNotificationsPlugin _localNotifications;
  
  EpisodeNotificationService();
  
  Future<void> setupNotifications() async {
    // Request permissions
    await _fcm.requestPermission();
    
    // Configure local notifications
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    
    await _localNotifications.initialize(initSettings);
  }
  
  Future<void> scheduleEpisodeCheck() async {
    // Check every 4 hours
    final nextCheck = DateTime.now().add(const Duration(hours: 4));
    await _localNotifications.zonedSchedule(
      const UniqueKey('episode_check'),
      'Checking for new episodes...',
      'This is a reminder that we will check for new TV show episodes.',
      nextCheck,
      AndroidNotificationDetails(
        'episodes_channel',
        'Episode Checker',
        'Automatically checks for new episodes every 4 hours',
        importance: Importance.low,
        ongoing: false,
      ),
    );
    
    // Schedule the actual episode check task (using work manager or similar)
    await _scheduleBackgroundWork();
  }
  
  Future<void> sendNewEpisodeNotification({
    required String showTitle,
    required int seasonNumber,
    required int episodeNumber,
    required String imageUrl,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'episodes_channel',
      'Episode Alerts',
      'When your favorite shows get new episodes',
      channelDescription: 'Notifications about new episodes of tracked shows',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );
    
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    
    final details = NotificationDetails(android: androidDetails, iOS: iosDetails);
    
    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000, // Unique ID
      '$showTitle - S$seasonNumber:E$episodeNumber',
      'New episode available! Watch it now.',
      details,
      payload: jsonEncode({
        'showTitle': showTitle,
        'seasonNumber': seasonNumber,
        'episodeNumber': episodeNumber,
        'imageUrl': imageUrl,
        'action': 'open_app',
      }),
    );
  }
}
```

#### Repository Pattern Implementation
```dart
// lib/data/repositories/catalogue_repository.dart
import 'package:flutter/foundation.dart';
import '../datasources/local/storage_datasource.dart';
import '../models/catalogue_item.dart';

class CatalogueRepository {
  final StorageDataSource _storage;
  
  CatalogueRepository({required StorageDataSource storage})
      : _storage = storage;
  
  Future<List<CatalogueItem>> getCatalogue() async {
    try {
      final items = await _storage.getCatalogue();
      return items;
    } catch (e) {
      if (kDebugMode) print('Error fetching catalogue: $e');
      return [];
    }
  }
  
  Future<void> addToCatalogue({
    required int externalId,
    required String title,
    required String type, // 'film' or 'tv'
    List<String>? tags,
  }) async {
    try {
      final item = CatalogueItem(
        id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        externalId: externalId,
        title: title,
        type: type,
        addedDate: DateTime.now(),
        tags: tags ?? [],
      );
      
      await _storage.addToCatalogue(item);
    } catch (e) {
      if (kDebugMode) print('Error adding to catalogue: $e');
      rethrow;
    }
  }
  
  Future<void> removeFromCatalogue(int id) async {
    try {
      await _storage.removeFromCatalogue(id);
    } catch (e) {
      if (kDebugMode) print('Error removing from catalogue: $e');
      rethrow;
    }
  }
  
  Future<void> addTagToItem({required int itemId, required String tagName}) async {
    try {
      await _storage.addTagToItem(itemId, tagName);
    } catch (e) {
      if (kDebugMode) print('Error adding tag: $e');
      rethrow;
    }
  }
  
  Future<void> removeTagFromItem({required int itemId, required String tagName}) async {
    try {
      await _storage.removeTagFromItem(itemId, tagName);
    } catch (e) {
      if (kDebugMode) print('Error removing tag: $e');
      rethrow;
    }
  }
  
  Future<void> markEpisodeWatched({
    required int showId,
    required int seasonNumber,
    required int episodeNumber,
  }) async {
    try {
      await _storage.markEpisodeWatched(showId, seasonNumber, episodeNumber);
    } catch (e) {
      if (kDebugMode) print('Error marking episode watched: $e');
      rethrow;
    }
  }
}
```

---

## Security & Privacy

### Data Protection Measures

1. **API Key Management**
   - Store TMDB API key securely (environment variables, not hard-coded)
   - Rotate keys periodically for production builds

2. **Local Data Storage**
   - Use encrypted storage where available
   - Implement secure data persistence
   - Consider using Flutter's `flutter_secure_storage`

3. **User Privacy**
   - No user authentication required (optional if needed)
   - All data stored locally
   - Clear privacy policy for app store submission
   - No telemetry without user consent

4. **Permissions**
   - Notification permissions: Required for episode alerts
   - Storage access: For media attachments (if needed)
   - Background execution: Limited to notification checking

### App Store Compliance

- **Google Play**: 
  - Privacy policy link required
  - Data collection disclosure
  - Permissions explanation
  
- **Apple App Store**:
  - Privacy Nutrition Label
  - App Tracking Transparency (if needed)
  - Clear usage description

---

## API Rate Limiting Strategy

```dart
class TMDBRateLimiter {
  static const int _requestsPerMinute = 40;
  static const int _burstLimit = 5;
  
  DateTime? _lastRequestTime;
  int _requestCount = 0;
  
  bool shouldAllowRequest() {
    final now = DateTime.now();
    
    // Reset count if minute passed
    if (_lastRequestTime == null || 
        now.difference(_lastRequestTime!).inMinutes > 1) {
      _lastRequestTime = now;
      _requestCount = 0;
    }
    
    // Check burst limit
    return _requestCount < _burstLimit;
  }
  
  void increment() {
    if (_shouldAllowRequest()) {
      _requestCount++;
      _lastRequestTime = DateTime.now();
      return true;
    }
    return false;
  }
}

// Usage with Dio interceptor
class TMDBInterceptor extends Interceptor {
  final TMDBRateLimiter _limiter;
  
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    if (!_limiter.shouldAllowRequest()) {
      // Retry after delay or show user warning
      handler.reject(
        DioException(
          requestOptions: options,
          error: 'Rate limit exceeded. Please wait a moment.',
          type: DioExceptionType.badResponse,
        ),
      );
    } else {
      handler.next(options);
    }
  }
}
```

---

## Testing Strategy

### Unit Tests
- Repository layer (mock data sources)
- Business logic/use cases
- Helper functions (debounce, date formatting)

### Widget Tests
- Search input behavior
- UI component rendering
- Theme switching

### Integration Tests
- Complete user flows (add to catalogue → search → watch)
- Notification triggers
- Offline mode behavior

---

## Estimated Timeline Summary

| Phase | Duration | Key Deliverables |
|-------|----------|------------------|
| 1. Foundation | 2 weeks | App skeleton, TMDB integration |
| 2. Core Features | 2 weeks | Tracking, search, tags |
| 3. Notifications | 2 weeks | Push notifications, scheduled checks |
| 4. Polish | 2 weeks | Testing, optimization, bug fixes |
| 5. Release | 1 week | App store submission |
| **Total** | **9 weeks** | **Production-ready app** |

---

## Next Steps

1. ✅ Initialize Flutter project
2. ✅ Configure development environment
3. ✅ Obtain TMDB API key (free registration)
4. ✅ Set up Firebase project for notifications
5. ✅ Start Phase 1 implementation

---

## Resources & References

- **TMDB API Documentation**: https://developers.themoviedb.org/3/documentation/api
- **Flutter Official Docs**: https://flutter.dev/docs
- **Firebase Cloud Messaging**: https://firebase.google.com/docs/cloud-messaging/android/client
- **Flutter Local Notifications**: https://pub.dev/packages/flutter_local_notifications

---

*Document Version: 1.0*  
*Last Updated: $(date +%Y-%m-%d)*  
*Author: App Development Team*
