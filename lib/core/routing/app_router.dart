import 'package:flutter/material.dart';
import '../../presentation/screens/search/search_screen.dart';
import '../../presentation/screens/catalogue/catalogue_screen.dart';
import '../../presentation/screens/settings/settings_screen.dart';
import '../../presentation/navigation/main_navigator.dart';

/// Application router configuration for navigation
class AppRouter {
  static const String homeRoute = '/';
  static const String searchRoute = '/search';
  static const String catalogueRoute = '/catalogue';
  static const String settingsRoute = '/settings';

  static final Map<String, WidgetBuilder> routes = <String, WidgetBuilder>{
    homeRoute: (context) => const MainNavigator(),
    searchRoute: (context) => const SearchScreen(initialQuery: ''),
    catalogueRoute: (context) => const CatalogueScreen(),
    settingsRoute: (context) => const SettingsScreen(),
  };

  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case searchRoute:
        final query = settings.arguments is String
            ? settings.arguments as String
            : '';
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (context) => SearchScreen(initialQuery: query),
        );
      case homeRoute:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (context) => const MainNavigator(),
        );
      case catalogueRoute:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (context) => const CatalogueScreen(),
        );
      case settingsRoute:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (context) => const SettingsScreen(),
        );
      default:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (context) => const MainNavigator(),
        );
    }
  }
}
