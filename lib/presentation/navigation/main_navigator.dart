import 'package:flutter/material.dart';
import '../../l10n/l10n.dart';
import '../screens/home/home_screen.dart';
import '../screens/search/search_screen.dart';
import '../screens/catalogue/catalogue_screen.dart';
import '../screens/settings/settings_screen.dart';
import 'main_tab.dart';

export 'main_tab.dart' show MainTab;

/// Main navigator for the app with bottom navigation
class MainNavigator extends StatefulWidget {
  const MainNavigator({super.key, MainTabRequests? tabRequests})
    : _tabRequests = tabRequests;

  final MainTabRequests? _tabRequests;

  MainTabRequests get tabRequests => _tabRequests ?? mainTabRequests;

  @override
  State<MainNavigator> createState() => _MainNavigatorState();
}

class _MainNavigatorState extends State<MainNavigator> {
  MainTab _currentTab = MainTab.home;

  int get _currentIndex => _currentTab.index;

  @override
  void initState() {
    super.initState();
    // A request made before the first build: nothing is open above the tabs
    // yet, so the tab is just selected.
    _currentTab = widget.tabRequests.take() ?? _currentTab;
    widget.tabRequests.addListener(_handleTabRequest);
  }

  @override
  void didUpdateWidget(MainNavigator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tabRequests == widget.tabRequests) return;
    oldWidget.tabRequests.removeListener(_handleTabRequest);
    widget.tabRequests.addListener(_handleTabRequest);
  }

  @override
  void dispose() {
    widget.tabRequests.removeListener(_handleTabRequest);
    super.dispose();
  }

  void _handleTabRequest() {
    final tab = widget.tabRequests.take();
    if (tab == null) return;
    // Close routes and sheets above the tabs, or the switch stays hidden.
    appNavigatorKey.currentState?.popUntil((route) => route.isFirst);
    _selectTab(tab.index);
  }

  Widget _screenFor(MainTab tab) {
    switch (tab) {
      case MainTab.home:
        return HomeScreen(isActive: _currentTab == MainTab.home);
      case MainTab.search:
        return SearchScreen(
          initialQuery: '',
          isActive: _currentTab == MainTab.search,
        );
      case MainTab.catalogue:
        return CatalogueScreen(
          isActive: _currentTab == MainTab.catalogue,
          onFindSomethingToWatch: () => _selectTab(MainTab.search.index),
        );
      case MainTab.settings:
        return SettingsScreen(
          isActive: _currentTab == MainTab.settings,
        );
    }
  }

  void _selectTab(int index) {
    if (index < 0 || index >= MainTab.values.length) return;
    setState(() => _currentTab = MainTab.values[index]);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    // Back from a secondary tab returns to Home instead of closing the app.
    return PopScope(
      canPop: _currentTab == MainTab.home,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _selectTab(MainTab.home.index);
      },
      child: _buildScaffold(l10n),
    );
  }

  Widget _buildScaffold(AppLocalizations l10n) {
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
        onDestinationSelected: _selectTab,
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home, size: 32),
            label: l10n.navHome,
          ),
          NavigationDestination(
            icon: const Icon(Icons.search_outlined),
            selectedIcon: const Icon(Icons.search, size: 32),
            label: l10n.navSearch,
          ),
          NavigationDestination(
            icon: const Icon(Icons.bookmark_border),
            selectedIcon: const Icon(Icons.bookmark, size: 32),
            label: l10n.navCatalogue,
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings_outlined),
            selectedIcon: const Icon(Icons.settings, size: 32),
            label: l10n.navSettings,
          ),
        ],
      ),
    );
  }
}

final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();
