# 🎬 Film/TV Show Tracker Mobile App

A cross-platform mobile application built with Flutter that allows users to track films and TV shows, receive smart notifications for new episodes, and maintain a personalized catalogue with tagging capabilities.

## 🚀 Features

### Core Functionality
- **Smart Search** - Debounced search across films, TV shows, and tags (waits 500ms after user stops typing)
- **User Catalogue** - Add/remove films and TV shows with a single button tap
- **Episode Tracking** - Track which episodes you've watched with season/episode organization
- **Tag System** - Custom tags to organize your catalogue (e.g., "favorite", "rewatch", "spoilers")
- **Trending Content** - Discover trending films and TV shows powered by TMDB API

### Notification System
- **Push Notifications** - Get alerted when new episodes/seasons become available
- **Configurable Check Interval** - Set how often to check for updates (1h, 3h, 6h, 12h)
- **Smart Notifications** - No spam, only relevant notifications for shows you're watching

### User Interface
- **Clean & Minimalist Design** - Focus on content with beautiful card layouts
- **Grid/List View Toggle** - Switch between viewing modes as you prefer
- **Dark Mode Support** - Automatically adapts to system theme preferences
- **Responsive Layout** - Works seamlessly across different screen sizes

## 🛠️ Technology Stack

### Framework
- **Flutter 3.0+** - Cross-platform mobile development
- **Material Design 3** - Modern UI components

### API Integration
- **TMDB (The Movie Database)** - Free tier: 40 requests/minute, ~3,500/day
- Custom API client with rate limiting and retry logic

### State Management
- **Provider Pattern** - Simple and scalable state management

### Local Storage
- **Hive** - Fast key-value database for offline support
- Encrypted storage options available

### Notifications
- **Firebase Cloud Messaging (FCM)** - Push notifications
- **flutter_local_notifications** - Local scheduled checks

## 📋 Prerequisites

Before you begin, ensure you have:

1. **Flutter SDK** (3.0 or higher)
   ```bash
   flutter doctor
   ```

2. **Android Studio / VS Code** with Flutter extensions

3. **TMDB API Key** (Free account required)
   - Visit: https://www.themoviedb.org/settings/api
   - Create a free account and generate an API key

4. **Firebase Project** (optional, for push notifications)
   - Visit: https://console.firebase.google.com/

## 🏗️ Project Structure

```
lib/
├── core/
│   ├── constants/
│   │   ├── app_constants.dart      # App-wide configuration
│   │   └── api_constants.dart      # TMDB API endpoints
│   ├── network/
│   │   └── dio_client.dart         # HTTP client with rate limiting
│   ├── routing/
│   │   └── app_router.dart         # Navigation routes
│   ├── theme/
│   │   └── app_theme.dart          # Light/dark themes
│   └── utils/
│       └── debounce_helper.dart    # Debounce utility for search
│
├── data/
│   ├── models/
│   │   ├── film_model.dart         # Film data structure
│   │   ├── tv_show_model.dart      # TV show data structure
│   │   ├── episode_model.dart      # Episode tracking model
│   │   ├── catalogue_item.dart     # Base catalogue items
│   │   └── tag_model.dart          # Tag management
│   ├── repositories/               # Repository pattern (to be implemented)
│   └── datasources/                # Data sources (remote/local)
│
├── presentation/
│   ├── screens/
│   │   ├── home/                   # Home screen with trending
│   │   ├── search/                 # Search functionality
│   │   ├── catalogue/              # User's personal collection
│   │   ├── tracking/               # Active tracking view
│   │   └── settings/               # App preferences
│   ├── widgets/                    # Reusable UI components
│   │   ├── debounce_search_widget.dart
│   │   ├── film_card.dart
│   │   └── tv_show_card.dart
│   └── navigation/
│       └── main_navigator.dart     # Main app navigation
│
└── main.dart                       # App entry point
```

## 🔧 Getting Started

### 1. Clone the Repository
```bash
git clone <repository-url>
cd iz-show-time
```

### 2. Install Dependencies
```bash
flutter pub get
```

### 3. Configure API Keys
Edit `lib/core/constants/api_constants.dart`:
```dart
// Add your TMDB API key (you'll need to add this to the actual implementation)
static const String _devKey = 'YOUR_TMDB_API_KEY_HERE';
```

Or use environment variables:
```dart
static const String get tmdb {
  if (kDebugMode) {
    return const String.fromEnvironment('TMDB_API_KEY');
  }
  return '';
}
```

### 4. Set Up Firebase (Optional - for push notifications)
1. Create a Firebase project at https://console.firebase.google.com/
2. Add Android and iOS apps to your project
3. Download configuration files:
   - `google-services.json` → Android directory
   - `GoogleService-Info.plist` → iOS directory
4. Add dependencies in `pubspec.yaml`:
```yaml
dev_dependencies:
  firebase_core_web: ^2.10.0
  flutterfire_cli: ^0.5.0
```
5. Run:
```bash
flutterfire configure --platform=android
flutterfire configure --platform=ios
```

### 5. Run the App
```bash
# For Android emulator/device
flutter run

# For iOS simulator
flutter run -d ios

# Debug mode
flutter run --debug
```

## 📱 Using the App

### Adding Content to Your Catalogue
1. Go to **Home** or **Search** screen
2. Search for a film or TV show
3. Tap the bookmark icon on any item
4. The item is added to your personal catalogue

### Tracking Episodes
1. Navigate to **Tracking** tab
2. Select a TV show from your catalogue
3. Mark episodes as watched (coming in next phase)
4. Get notifications when new episodes air!

### Managing Tags
1. Long press on any item in your catalogue
2. Add custom tags like "favorite", "rewatch", etc.
3. Use tag filters to find similar content

## 🔄 Development Workflow

### Adding New Features
1. Create models in `lib/data/models/`
2. Update repositories in `lib/data/repositories/`
3. Create UI components in `lib/presentation/widgets/`
4. Add screens in `lib/presentation/screens/`

### Testing
```bash
# Run unit tests
flutter test

# Run with coverage
flutter test --coverage

# Debug on device
flutter run --debug-protocol
```

### Building Releases
```bash
# Android APK
flutter build apk --release

# iOS App
flutter build ios --release

# Universal Flutter app (Android + iOS)
flutter build apk --split-per-abi
```

## 🔒 Security Notes

### API Key Management
⚠️ **Important**: Never hardcode API keys in production builds!

**Recommended approach:**
1. Use environment variables via `BuildConfig` or `dotenv`
2. For Flutter Web, use build flags: `flutter run --dart-define=TMDB_API_KEY=value`
3. Consider server-side proxy for sensitive operations

### Data Privacy
- All data is stored locally on device
- No user authentication required (optional)
- No telemetry without explicit consent

## 🐛 Known Issues & Limitations

- [ ] TV show episode tracking needs backend sync
- [ ] Offline mode for search results needs enhancement
- [ ] Background episode checking requires Work Manager setup
- [ ] Tag suggestions based on TMDB genres not yet implemented

## 🚀 Roadmap

### Phase 1 (Current) ✅
- [x] App foundation and structure
- [x] UI/UX implementation
- [x] Search functionality with debounce
- [x] Catalogue management

### Phase 2 (Next) 📅
- [ ] Complete repository layer with Hive
- [ ] Full offline support
- [ ] Image caching strategy
- [ ] Push notification integration

### Phase 3 (Future) 🔮
- [ ] Smart recommendations
- [ ] Watch party features
- [ ] Social sharing
- [ ] Statistics and analytics

## 📄 License

This project is open source and available under the MIT License.

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📧 Contact

For questions or support, please create an issue in this repository.

## 🙏 Acknowledgments

- **TMDB** - For providing free and open movie/TV show data
- **Flutter Team** - For the amazing framework
- **Firebase** - For notification services

---

*Built with ❤️ using Flutter and TMDB API*
