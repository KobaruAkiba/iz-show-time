import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';

/// List that shows [pageSize] items first, then reveals more as the user scrolls.
///
/// When all already-loaded items are visible and [hasMoreRemote] is true,
/// [onLoadMore] is invoked so the parent can fetch the next API page.
class LazyPagedListView extends StatefulWidget {
  const LazyPagedListView({
    super.key,
    required this.totalItemCount,
    required this.itemBuilder,
    this.pageSize = AppConstants.listPageSize,
    this.padding = const EdgeInsets.all(16),
    this.leading,
    this.onRefresh,
    this.onLoadMore,
    this.hasMoreRemote = false,
    this.isLoadingMore = false,
    this.resetKey,
    this.physics,
    this.controller,
  });

  final int totalItemCount;
  final IndexedWidgetBuilder itemBuilder;
  final int pageSize;
  final EdgeInsetsGeometry padding;
  final Widget? leading;
  final Future<void> Function()? onRefresh;
  final Future<void> Function()? onLoadMore;
  final bool hasMoreRemote;
  final bool isLoadingMore;

  /// When this value changes, the visible window resets to [pageSize].
  final Object? resetKey;
  final ScrollPhysics? physics;
  final ScrollController? controller;

  @override
  State<LazyPagedListView> createState() => _LazyPagedListViewState();
}

class _LazyPagedListViewState extends State<LazyPagedListView> {
  late int _visibleCount;
  late final ScrollController _controller;
  late final bool _ownsController;
  bool _loadMoreQueued = false;

  @override
  void initState() {
    super.initState();
    _visibleCount = _clampVisible(widget.pageSize);
    _ownsController = widget.controller == null;
    _controller = widget.controller ?? ScrollController();
  }

  @override
  void dispose() {
    if (_ownsController) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant LazyPagedListView oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.resetKey != widget.resetKey) {
      _visibleCount = _clampVisible(widget.pageSize);
      return;
    }

    // After a remote page appends items, reveal the next local window.
    if (widget.totalItemCount > oldWidget.totalItemCount &&
        _visibleCount >= oldWidget.totalItemCount) {
      _visibleCount = _clampVisible(_visibleCount + widget.pageSize);
    } else {
      _visibleCount = _clampVisible(_visibleCount);
    }
  }

  int _clampVisible(int desired) {
    if (widget.totalItemCount <= 0) return 0;
    return desired.clamp(0, widget.totalItemCount);
  }

  bool _onScroll(ScrollNotification notification) {
    if (notification.metrics.axis != Axis.vertical) return false;
    if (notification is! ScrollUpdateNotification &&
        notification is! OverscrollNotification) {
      return false;
    }

    final remaining =
        notification.metrics.maxScrollExtent - notification.metrics.pixels;
    if (remaining > 240) return false;

    _tryRevealOrLoadMore();
    return false;
  }

  void _tryRevealOrLoadMore() {
    if (_visibleCount < widget.totalItemCount) {
      setState(() {
        _visibleCount = _clampVisible(_visibleCount + widget.pageSize);
      });
      return;
    }

    if (!widget.hasMoreRemote ||
        widget.isLoadingMore ||
        widget.onLoadMore == null ||
        _loadMoreQueued) {
      return;
    }

    _loadMoreQueued = true;
    widget.onLoadMore!().whenComplete(() {
      _loadMoreQueued = false;
    });
  }

  /// If the first page does not fill the viewport, keep revealing (or loading)
  /// until the list becomes scrollable or data is exhausted.
  void _fillViewportIfNeeded() {
    if (!mounted || !_controller.hasClients) return;

    final maxExtent = _controller.position.maxScrollExtent;
    if (maxExtent > 0) return;

    if (_visibleCount < widget.totalItemCount ||
        (widget.hasMoreRemote && !widget.isLoadingMore)) {
      _tryRevealOrLoadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) => _fillViewportIfNeeded());

    final leadingCount = widget.leading == null ? 0 : 1;
    final showFooter = widget.isLoadingMore;
    final footerCount = showFooter ? 1 : 0;
    final itemCount = leadingCount + _visibleCount + footerCount;

    Widget list = NotificationListener<ScrollNotification>(
      onNotification: _onScroll,
      child: ListView.builder(
        controller: _controller,
        physics: widget.physics,
        padding: widget.padding,
        itemCount: itemCount,
        itemBuilder: (context, index) {
          if (widget.leading != null && index == 0) {
            return widget.leading!;
          }

          final itemIndex = index - leadingCount;
          if (itemIndex < _visibleCount) {
            return widget.itemBuilder(context, itemIndex);
          }

          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
            ),
          );
        },
      ),
    );

    if (widget.onRefresh != null) {
      list = RefreshIndicator(
        onRefresh: widget.onRefresh!,
        child: list,
      );
    }

    return list;
  }
}

/// Increases [visibleCount] by [pageSize] when the parent scroll view nears the end.
/// Use when items live inside an outer [SingleChildScrollView] / [CustomScrollView].
bool handleLazyParentScroll({
  required ScrollNotification notification,
  required int totalCount,
  required int visibleCount,
  required void Function(int newVisibleCount) onRevealMore,
  int pageSize = AppConstants.listPageSize,
  double threshold = 240,
}) {
  if (notification.metrics.axis != Axis.vertical) return false;
  if (notification is! ScrollUpdateNotification &&
      notification is! OverscrollNotification &&
      notification is! ScrollMetricsNotification) {
    return false;
  }
  if (visibleCount >= totalCount) return false;

  final maxExtent = notification.metrics.maxScrollExtent;
  final remaining = maxExtent - notification.metrics.pixels;

  // Undersized content (nothing to scroll) or near the bottom.
  if (maxExtent > 0 && remaining > threshold) return false;

  onRevealMore((visibleCount + pageSize).clamp(0, totalCount));
  return false;
}
