import 'package:flutter/material.dart';
import '../../../core/services/app_services.dart';
import '../../../data/models/watchlist_entry.dart';
import '../../widgets/app_page_header.dart';
import 'catalogue_view.dart';
import 'library_segment_switch.dart';
import 'watchlist_view.dart';

/// Library tab: switches between the catalogue and the watchlist.
class CatalogueScreen extends StatefulWidget {
  final bool isActive;

  /// Called by the empty watchlist to send the user to the Search tab.
  final VoidCallback? onFindSomethingToWatch;

  const CatalogueScreen({
    super.key,
    this.isActive = true,
    this.onFindSomethingToWatch,
  });

  @override
  State<CatalogueScreen> createState() => _CatalogueScreenState();
}

class _CatalogueScreenState extends State<CatalogueScreen> {
  final _appServices = AppServices();

  /// Kept in memory for as long as the navigator keeps this tab alive.
  LibrarySegment _segment = LibrarySegment.watched;

  void _refreshCounts() => setState(() {});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const AppPageHeader(),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: ValueListenableBuilder<List<WatchlistEntry>>(
                valueListenable: _appServices.watchlist.listenable,
                builder: (context, entries, _) => LibrarySegmentSwitch(
                  selected: _segment,
                  onChanged: (segment) => setState(() => _segment = segment),
                  watchedCount: _appServices.catalogue.length,
                  toWatchCount: entries.length,
                ),
              ),
            ),
            // Both views stay mounted so each keeps its search and filters.
            Expanded(
              child: IndexedStack(
                index: _segment.index,
                children: [
                  CatalogueView(
                    isActive:
                        widget.isActive && _segment == LibrarySegment.watched,
                    onCatalogueChanged: _refreshCounts,
                  ),
                  WatchlistView(
                    onFindSomethingToWatch: widget.onFindSomethingToWatch,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
