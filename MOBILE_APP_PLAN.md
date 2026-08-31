# Mobile Film/TV Show Tracker App - Development Plan

## 📱 Project Overview

**App Name:** IzShowTime Tracker  
**Platform:** Flutter (iOS & Android)  
**Purpose:** Track and manage personal film and TV show collection with smart notifications and tagging system.

---

## 🎯 Core Features

### 1. Content Discovery & Search
- **TMDB Integration**: Fetch movies, TV shows, episodes from The Movie Database (free API)
- **Debounced Search**: Real-time search with 500ms debounce delay for optimal performance
- **Multi-type Search**: Search across films, TV shows, episodes, and tags simultaneously
- **Trending Content**: Display trending movies and TV shows daily

### 2. Catalogue Management
- **Add to Collection**: One-click "Add to my catalogue" button
- **Smart Categorization**: Separate viewing for Films (movies) and TV Shows
- **Tag System**: User-defined tags to organize content by mood, genre, quality, etc.
- **Season/Episode Tracking**: For TV shows, track watched episodes per season

### 3. Notification System
- **Periodic Checks**: Query API every 4 hours for new episodes/seasons
- **Device Notifications**: Local push notifications when new content available
- **Firebase Integration**: Firebase Cloud Messaging (FCM) for reliable delivery
- **Background Sync**: Handle app lifecycle changes gracefully

### 4. User Interface Design
- **Clean & Modern**: Material Design 3 principles
- **Responsive Layout**: Adapts to phone, tablet, and foldable devices
- **Grid/List Views**: Toggle between compact grid and detailed list views
- **Dark Mode Support**: Built-in dark/light theme support

---

## 🏗️ Architecture Overview

### Project Structure
```
lib/
├── core/                    # Core utilities and configuration
│   ├── constants/          # API endpoints, app-wide settings
│   ├── network/            # HTTP client (Dio) with rate limiting
│   ├── routing/            # App navigation routes
│   └── utils/              # Helper functions (debounce, etc.)
├── data/                   # Data layer
│   ├── models/             # Data models (Film, TVShow, Tag, Episode)
│   └── services/           # API service clients
├── presentation/           # UI layer
│   ├── navigation/         # Main navigator & navigation logic
│   ├── screens/            # Screen widgets
│   │   ├── home/          # Home screen with trending content
│   │   ├── search/        # Search functionality
│   │   ├── catalogue/     # User's personal collection
│   │   ├── tracking/      # Episode tracking detail view
│   │   └── settings/      # App configuration & API key management
│   └── widgets/            # Reusable UI components
├── main.dart               # App entry point
└── providers/              # State management (Riverpod)
```

### Data Flow
```
User Action → Router → Screen → Provider → Service → API → Response → Update State
         ↓                                              ↓
    Notification Manager ←─────────────────────── FCM Token
```

---

## 🔧 Technology Stack

### Framework & Platform
- **Flutter SDK**: Cross-platform UI framework
- **Dart Language**: Typed language for Flutter development

### Networking & Data
- **Dio**: HTTP client with interceptors for rate limiting
- **TMDB API**: Movie/TV show database (Free tier: 40 requests/min)
- **Firebase Cloud Messaging**: Push notifications for new episodes

### State Management
- **Riverpod**: Provider-based reactive state management
- **Local Storage**: JSON serialization for offline viewing

### UI Components
- **Material Design 3**: Modern Material components
- **Cached Network Image**: Optimized image loading with caching

---

## 📋 Implementation Phases

### Phase 1: Foundation (Current) ✓
- [x] Project structure setup
- [x] Core constants and configuration
- [x] API client with rate limiting
- [x] Data models definition
- [x] Navigation routing system
- [x] Basic UI screens created

### Phase 2: TMDB Integration (Next)
- [ ] Implement Movie Search Service
- [ ] Implement TV Show Search Service  
- [ ] Fetch trending content
- [ ] Episode data fetching
- [ ] Handle API errors and rate limits

### Phase 3: Catalogue Features
- [ ] Implement "Add to Catalogue" functionality
- [ ] Tag management system
- [ ] Season/episode tracking UI
- [ ] Personal collection display
- [ ] Grid/List view toggle

### Phase 4: Search & Filtering
- [ ] Debounced search implementation
- [ ] Multi-type search (movies + TV shows)
- [ ] Filter by tags
- [ ] Filter by date added, rating, etc.
- [ ] Recent searches history

### Phase 5: Notification System
- [ ] Firebase SDK integration
- [ ] Token management & refresh
- [ ] Local notification triggers
- [ ] Background task scheduling (4-hour interval)
- [ ] Permission handling for notifications

### Phase 6: Polish & Testing
- [ ] Error states & empty states
- [ ] Loading indicators & skeletons
- [ ] Pull-to-refresh functionality
- [ ] Offline mode support
- [ ] Performance optimization
- [ ] Accessibility features
- [ ] App icon & splash screen

---

## 🔐 Privacy & Security

### API Key Management
- **Environment Variables**: Store API keys in `.env` files (not committed to git)
- **Obfuscation**: Enable code obfuscation for production builds
- **Secure Storage**: Consider using Flutter Secure Storage for sensitive data

### User Data
- **Local Only**: All catalogue data stored locally on device
- **No Cloud Sync**: Designed as privacy-first, local-only application
- **Export Feature**: Allow users to export their collection as JSON backup

---

## 🎨 UI/UX Guidelines

### Color Scheme
```dart
Primary:     #6200EE (Material Purple)
Secondary:   #03DAC6 (Material Teal)
Background:  #121212 (Dark mode)
Surface:     #1E1E1E
Text:        #FFFFFF (Primary), #B0B0B0 (Secondary)
Accent:      #FFB74D (Orange for notifications)
```

### Typography
- **Headline 1**: 28sp, bold - Screen titles
- **Headline 2**: 24sp, semi-bold - Section headers  
- **Body Text**: 16sp, regular - Main content
- **Caption**: 12sp - Labels and metadata

### Spacing System
Based on `8px` grid system:
- Content padding: 24px from edges
- Card spacing: 16px
- Button height: 48px minimum

---

## ⚠️ Known Issues & Technical Debt

1. **Model Mismatches**: Some UI widgets reference models with different field names
   - `Film.posterUrl` should be `Film.posterPath`
   - `Film.originalTitle` exists but needs verification in widgets

2. **Route Builder Type**: `getRouteBuilder` returns wrong type
   - Current: `Widget Function(BuildContext)?`
   - Expected: `WidgetBuilder` (which is `Widget Function(BuildContext)`)

3. **Constant Values**: Some constants use deprecated APIs
   - `.withOpacity()` → Use `.withValues()` instead

4. **Navigation Context**: Missing `navigatorKey` reference causing undefined errors

5. **Timer Class**: References to `Timer` class without proper import in widgets

---

## 📊 Performance Considerations

### Image Loading
- Use `cached_network_image` package
- Implement progressive loading with skeletons
- Lazy load images outside viewport
- Cache at multiple resolutions (thumb, small, large)

### Network Requests
- Rate limiting interceptor prevents API bans
- Debounce search inputs (500ms delay)
- Batch requests where possible
- Retry logic for transient errors (max 3 retries with exponential backoff)

### Memory Management
- Dispose timers in widget lifecycle (`dispose()`)
- Cancel pending network calls when screen closes
- Clear large lists from memory on navigation away

---

## 🚀 Future Enhancements (Post-MVP)

1. **Social Features** (Optional)
   - Share collection via social media
   - Private sharing of specific movies/shows

2. **Advanced Search**
   - Cast member search
   - Director/creator filtering
   - Advanced date ranges

3. **Analytics Dashboard**
   - Watch history statistics
   - Most watched genres/time periods
   - Engagement metrics

4. **Multi-language Support**
   - i18n for interface translations
   - Fetch dubbed/subtitled content from TMDB

5. **Advanced Notifications**
   - Smart suggestions ("You might like...")
   - Watch party coordination
   - Reminders based on viewing habits

---

## 📚 Development Resources

### Documentation Links
- [Flutter Documentation](https://flutter.dev/docs)
- [Riverpod Documentation](https://riverpod.dev/)
- [Firebase Cloud Messaging](https://firebase.google.com/docs/cloud-messaging)
- [TMDB API Reference](https://www.themoviedb.org/documentation/api)

### Code Style Guidelines
```yaml
# See .analysis_options.yaml for configured rules
- prefer_const_constructors
- prefer_final_fields
- require_trailing_commas
- use_key_in_widget_constructors
```

---

## 🤝 Contributing & Maintenance

### Pull Request Process
1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make changes and run `flutter test`
4. Update documentation if needed
5. Submit pull request

### Issue Reporting
- Use GitHub Issues for bugs
- Tag issues appropriately: `bug`, `feature`, `enhancement`, `question`
- Include reproduction steps and environment details

---

## 📄 License & Credits

This project is built for educational purposes. All TMDB data is subject to their [terms of service](https://www.themoviedb.org/documentation/api).

### Key Contributors (Placeholder)
- Primary Developer: [Your Name]
- Design System: Material Design 3
- Data Source: The Movie Database (TMDB)

---

## 🎬 Sample User Journey

1. **Onboarding**: User opens app, grants notification permissions
2. **Home Screen**: Browse trending movies and TV shows
3. **Search**: Type "Breaking Bad" → Add to catalogue with one click
4. **Tagging**: Select tags: "drama", "classic", "watched"
5. **Tracking**: Navigate to catalogue → View "Breaking Bad" season 1
6. **Notifications**: Receive push notification at 2 PM when Season 6 Episode 13 releases
7. **Discovery**: Click notification → Open app → See new episode in tracking view

---

## ✅ Acceptance Criteria

- [ ] App runs on Android and iOS simulators/emulators
- [ ] Search works with debouncing (no excessive API calls)
- [ ] Users can add movies and TV shows to personal catalogue
- [ ] Tags can be applied to catalogue items
- [ ] Episode tracking works for TV shows (season/episode level)
- [ ] Notifications appear after 4-hour interval when new episodes released
- [ ] UI is responsive on phones, tablets, and foldable devices
- [ ] API rate limits are respected (max 40 req/min per TMDB free tier)

---

**Last Updated**: $(date +%Y-%m-%d)  
**Status**: Phase 1 - Foundation Complete ✓  
**Next Milestone**: Phase 2 - TMDB Integration 🚧
