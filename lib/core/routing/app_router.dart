import 'package:flutter/material.dart';
import '../../presentation/screens/home/home_screen.dart';
import '../../presentation/screens/search/search_screen.dart';
import '../../presentation/screens/catalogue/catalogue_screen.dart';
import '../../presentation/screens/tracking/tracking_screen.dart';
import '../../presentation/screens/settings/settings_screen.dart';

/// Application router configuration for navigation
class AppRouter {
  static const String homeRoute = '/';
  static const String searchRoute = '/search';
  static const String catalogueRoute = '/catalogue';
  static const String trackingRoute = '/tracking';
  static const String settingsRoute = '/settings';

  /// Get route name for a given location
  static String getRouteName(String location) {
    if (location == homeRoute || location.isEmpty) return homeRoute;

    switch (location) {
      case searchRoute:
        return searchRoute;
      case catalogueRoute:
        return catalogueRoute;
      case trackingRoute:
        return trackingRoute;
      case settingsRoute:
        return settingsRoute;
      default:
        return homeRoute;
    }
  }

  /// Build a Map of all routes with their destinations and names
  static final Map<String, WidgetBuilder> routes = <String, WidgetBuilder>{
    homeRoute: (context) => const HomeScreen(),
    searchRoute: (context) => const SearchScreen(initialQuery: ''),
    catalogueRoute: (context) => const CatalogueScreen(),
    trackingRoute: (context) => const TrackingScreen(),
    settingsRoute: (context) => const SettingsScreen(),
  };

  /// Get a route builder for a specific location
  static WidgetBuilder getRouteBuilder(String location) {
    final routeName = getRouteName(location);
    return routes[routeName]!;
  }

  /// Get the destination widget for a given route name
  static Widget? getDestination(String location, BuildContext context) {
    final routeName = getRouteName(location);
    final builder = routes[routeName];

    if (builder == null) return null;

    // In a real app, you'd use Navigator or state management to persist this widget
    // For now, we'll show a placeholder
    return Scaffold(
      appBar: AppBar(title: Text(routeName)),
      body: Center(child: Text('Route: $routeName')),
    );
  }
}
