import 'package:flutter/material.dart';
import '../../core/routing/app_router.dart';
import '../screens/home/home_screen.dart';
import '../screens/search/search_screen.dart';
import '../screens/catalogue/catalogue_screen.dart';
import '../screens/settings/settings_screen.dart';

enum MainTab { home, search, catalogue, settings }

/// Main navigator for the app with bottom navigation
class MainNavigator extends StatefulWidget {
  const MainNavigator({super.key});

  @override
  State<MainNavigator> createState() => _MainNavigatorState();
}

class _MainNavigatorState extends State<MainNavigator> {
  MainTab _currentTab = MainTab.home;

  int get _currentIndex => _currentTab.index;

  Widget _screenFor(MainTab tab) {
    switch (tab) {
      case MainTab.home:
        return const HomeScreen();
      case MainTab.search:
        return SearchScreen(
          initialQuery: '',
          isActive: _currentTab == MainTab.search,
        );
      case MainTab.catalogue:
        return CatalogueScreen(
          isActive: _currentTab == MainTab.catalogue,
        );
      case MainTab.settings:
        return const SettingsScreen();
    }
  }

  void _selectTab(int index) {
    if (index < 0 || index >= MainTab.values.length) return;
    setState(() => _currentTab = MainTab.values[index]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: MainTab.values
            .map(
              (tab) => KeyedSubtree(
                key: ValueKey(tab.name),
                child: _screenFor(tab),
              ),
            )
            .toList(),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          final args = ModalRoute.of(context)?.settings.arguments
              as Map<String, dynamic>?;
          if (args != null && args['query'] != null && index == 1) {
            _selectTab(1);
            Navigator.of(context).push(
              MaterialPageRoute<String>(
                builder: (context) =>
                    SearchScreen(initialQuery: args['query'].toString()),
              ),
            );
          } else {
            _selectTab(index);
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
            icon: Icon(Icons.settings),
            selectedIcon: Icon(Icons.settings_rounded, size: 32),
            label: 'Settings',
          ),
        ],
      ),
    );
  }

  void navigateTo(int index) {
    _selectTab(index);

    if (index == 1 && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  Future<void> navigateToWithArgs(int index, Map<String, dynamic> args) async {
    final query = args['query']?.toString() ?? '';

    if (index == 1 && query.isNotEmpty) {
      await Navigator.of(context).push(
        MaterialPageRoute<String>(
          builder: (context) => SearchScreen(initialQuery: query),
        ),
      );
    } else {
      _selectTab(index);
    }
  }

  void popCurrentRoute() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  void showOnScreen(String message, {int? index}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

extension NavigatorExtension on BuildContext {
  void navigateToSettings() {
    Navigator.pushNamed(this, AppRouter.settingsRoute);
  }

  void showSnackBar(String message) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();
