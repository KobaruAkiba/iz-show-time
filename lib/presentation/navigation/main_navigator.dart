import 'package:flutter/material.dart';
import '../../core/routing/app_router.dart';
import '../screens/home/home_screen.dart';
import '../screens/search/search_screen.dart';
import '../screens/catalogue/catalogue_screen.dart';
import '../screens/tracking/tracking_screen.dart';
import '../screens/settings/settings_screen.dart';

/// Main navigator for the app with bottom navigation
class MainNavigator extends StatefulWidget {
  const MainNavigator({super.key});

  @override
  State<MainNavigator> createState() => _MainNavigatorState();
}

class _MainNavigatorState extends State<MainNavigator> {
  // Navigation destinations
  final List<Widget> _screens = [
    const HomeScreen(),
    const SearchScreen(initialQuery: ''),
    const CatalogueScreen(),
    const TrackingScreen(),
    const SettingsScreen(),
  ];

  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });

          // If navigating to search screen with a query argument
          final args = ModalRoute.of(context)?.settings.arguments
              as Map<String, dynamic>?;
          if (args != null && args['query'] != null && index == 1) {
            setState(() {
              _currentIndex = 1;
            });
            // Navigate to search screen with the query - this will trigger a new route
            Navigator.of(context).push(
              MaterialPageRoute<String>(
                builder: (context) =>
                    SearchScreen(initialQuery: args['query'].toString()),
              ),
            );
          } else {
            setState(() {
              _currentIndex = index;
            });
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home),
            selectedIcon: Icon(Icons.home_outlined, size: 32),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.search),
            selectedIcon: Icon(Icons.search_rounded, size: 32),
            label: 'Search',
          ),
          NavigationDestination(
            icon: Icon(Icons.bookmark_border),
            selectedIcon: Icon(Icons.bookmark_outline_rounded, size: 32),
            label: 'Catalogue',
          ),
          NavigationDestination(
            icon: Icon(Icons.notifications_outlined),
            selectedIcon: Icon(Icons.notifications_active, size: 32),
            label: 'Notifications',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings),
            selectedIcon: Icon(Icons.settings_rounded, size: 32),
            label: 'Settings',
          ),
        ],
      ),
    );
  }

  /// Navigate to a specific screen by index
  void navigateTo(int index) {
    setState(() {
      _currentIndex = index;
    });

    if (index == 1 && Navigator.of(context).canPop()) {
      // Pop current route and show search screen
      Navigator.of(context).pop();
    }
  }

  /// Navigate to a specific screen with arguments
  Future<void> navigateToWithArgs(int index, Map<String, dynamic> args) async {
    final query = args['query']?.toString() ?? '';

    if (index == 1 && query.isNotEmpty) {
      // Navigate to search with the query
      await Navigator.of(context).push(
        MaterialPageRoute<String>(
          builder: (context) => SearchScreen(initialQuery: query),
        ),
      );
    } else {
      setState(() {
        _currentIndex = index;
      });
    }
  }

  /// Pop current navigation stack
  void popCurrentRoute() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  /// Show snackbar on a specific screen
  void showOnScreen(String message, {int? index}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

/// Helper extension for navigation from any BuildContext
extension NavigatorExtension on BuildContext {
  /// Navigate to settings screen
  void navigateToSettings() {
    Navigator.pushNamed(this, AppRouter.settingsRoute);
  }

  /// Show snackbar message
  void showSnackBar(String message) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

/// Main app navigator key for programmatic navigation from outside MaterialApp
final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();
