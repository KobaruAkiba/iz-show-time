import 'package:flutter/material.dart';
import '../../widgets/debounce_search_widget.dart';

/// Main home screen showing trending content and quick access to catalogue
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  final List<String> _placeholderItems =
      List.generate(8, (index) => 'Item $index');

  // Tab indices for filtering content
  int _currentTabIndex = 0;
  PageController? _pageController;

  @override
  void initState() {
    super.initState();

    // Simulate loading - in real implementation, fetch trending content from API
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _pageController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Initialize page controller on first build if not already initialized
    if (_pageController == null) {
      _pageController = PageController(viewportFraction: 0.85);
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header with Search
            _buildHeader(),

            const SizedBox(height: 16),

            // Quick Actions / Recent Additions (placeholder)
            if (!_isLoading) ...[
              _buildQuickActionsSection(),

              const SizedBox(height: 20),

              // Trending Content
              _buildTrendingSection(),

              const SizedBox(height: 16),
            ],
          ],
        ),
      ),
    );
  }

  void _handleSearch(String query) async {
    // Navigate to search screen with the query
    if (mounted) {
      Navigator.pushNamed(context, '/search', arguments: query);
    }
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: DebounceSearchWidget(
            onSearch: _handleSearch,
          ),
        ),
        const SizedBox(width: 16),

        // Filter button (placeholder)
        IconButton(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Filter features coming soon')),
            );
          },
          icon: const Icon(Icons.tune),
        ),
      ],
    );
  }

  Widget _buildQuickActionsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Quick Actions',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              TextButton(onPressed: () {}, child: const Text('See All')),
            ],
          ),

          const SizedBox(height: 12),

          // Quick action items (placeholder)
          Row(
            children: [
              Expanded(
                flex: 2,
                child: _buildQuickActionTile(
                  icon: Icons.add,
                  title: 'Add to Catalogue',
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: _buildQuickActionTile(
                  icon: Icons.notifications_active,
                  title: 'Notifications',
                  color: Colors.orange[700]!,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionTile({
    required IconData icon,
    required String title,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '🔥 Trending Now',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              TextButton(onPressed: () {}, child: const Text('See All')),
            ],
          ),
        ),

        // Horizontal scrollable content
        SizedBox(
          height: 240,
          child: _isLoading
              ? Container(
                  color: Theme.of(context)
                      .colorScheme
                      .surfaceContainerHighest
                      .withValues(alpha: 0.5),
                  child: const Center(child: CircularProgressIndicator()),
                )
              : PageView.builder(
                  controller: _pageController!,
                  itemCount: _placeholderItems.length,
                  onPageChanged: (index) {
                    setState(() {
                      _currentTabIndex = index;
                    });
                  },
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Stack(
                        children: [
                          // Item card (alternating film/TV)
                          AspectRatio(
                            aspectRatio: 16 / 9,
                            child: Card(
                              elevation: 4,
                              child: Stack(
                                children: [
                                  // Content image
                                  Align(
                                    alignment: Alignment.center,
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                            colors: [
                                              Theme.of(context)
                                                  .colorScheme
                                                  .primary
                                                  .withValues(alpha: 0.8),
                                              Theme.of(context)
                                                  .colorScheme
                                                  .secondary
                                                  .withValues(alpha: 0.6),
                                            ],
                                          ),
                                        ),
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                                index.isOdd
                                                    ? Icons.movie
                                                    : Icons.tv,
                                                size: 48,
                                                color: Colors.white70),
                                            const SizedBox(height: 16),
                                            Text(
                                              _placeholderItems[index],
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),

                                  // Overlay gradient
                                  Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      color: Colors.black12,
                                    ),
                                  ),

                                  // Type indicator badge
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.black54,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        index.isOdd ? '🎬 Film' : '📺 Show',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Add to catalogue button overlay
                          Positioned(
                            bottom: 8,
                            right: 8,
                            child: IconButton(
                              onPressed: () {},
                              icon: const Icon(Icons.bookmark_border,
                                  color: Colors.white70),
                              iconSize: 28,
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.black54,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),

        // Page indicator dots (only show when not loading)
        if (!_isLoading)
          SizedBox(
            height: 8,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_placeholderItems.length, (index) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: index == _currentTabIndex ? 20 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: index == _currentTabIndex
                        ? Theme.of(context).colorScheme.primary
                        : Colors.grey.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
          ),
      ],
    );
  }
}

/// Helper extension for odd/even checking
extension on int {
  bool get isOdd => this % 2 == 1;
}
