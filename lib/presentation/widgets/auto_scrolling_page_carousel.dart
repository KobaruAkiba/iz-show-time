import 'dart:async';

import 'package:flutter/material.dart';

/// Peaking [PageView] with timed auto-advance, pause-on-drag, and infinite loop.
///
/// Auto-scroll runs only when there are at least two pages, the screen is
/// active, the app is resumed, animations are allowed, and [isPaused] is false.
class AutoScrollingPageCarousel extends StatefulWidget {
  const AutoScrollingPageCarousel({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    required this.height,
    this.isScreenActive = true,
    this.isPaused = false,
    this.viewportFraction = 0.82,
    this.interval = const Duration(seconds: 5),
    this.resumeIdle = const Duration(seconds: 4),
    this.animationDuration = const Duration(milliseconds: 400),
    this.animationCurve = Curves.easeInOutCubic,
    this.onPageChanged,
    this.showIndicators = true,
  });

  final int itemCount;
  final Widget Function(BuildContext context, int index, bool isActive)
      itemBuilder;
  final double height;
  final bool isScreenActive;
  final bool isPaused;
  final double viewportFraction;
  final Duration interval;
  final Duration resumeIdle;
  final Duration animationDuration;
  final Curve animationCurve;
  final ValueChanged<int>? onPageChanged;
  final bool showIndicators;

  @override
  State<AutoScrollingPageCarousel> createState() =>
      _AutoScrollingPageCarouselState();
}

class _AutoScrollingPageCarouselState extends State<AutoScrollingPageCarousel>
    with WidgetsBindingObserver {
  static const _infiniteMultiplier = 1000;

  late final PageController _controller;
  Timer? _autoTimer;
  Timer? _resumeTimer;
  bool _userDragging = false;
  bool _autoAnimating = false;
  bool _appResumed = true;
  int _logicalIndex = 0;
  late int _basePage;

  bool get _reduceMotion =>
      MediaQuery.maybeOf(context)?.disableAnimations ?? false;

  bool get _canAutoScroll =>
      widget.itemCount > 1 &&
      widget.isScreenActive &&
      !widget.isPaused &&
      _appResumed &&
      !_userDragging &&
      !_reduceMotion;

  int get _initialPage =>
      widget.itemCount > 1 ? widget.itemCount * _infiniteMultiplier : 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _basePage = _initialPage;
    _controller = PageController(
      viewportFraction: widget.viewportFraction,
      initialPage: _basePage,
    );
    _logicalIndex = 0;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _armAutoTimer();
    });
  }

  @override
  void didUpdateWidget(covariant AutoScrollingPageCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.itemCount != widget.itemCount && widget.itemCount > 0) {
      _logicalIndex = _logicalIndex.clamp(0, widget.itemCount - 1);
      if (widget.itemCount == 1 && _controller.hasClients) {
        _controller.jumpToPage(0);
      }
    }
    if (oldWidget.isScreenActive != widget.isScreenActive ||
        oldWidget.isPaused != widget.isPaused ||
        oldWidget.itemCount != widget.itemCount) {
      if (_canAutoScroll) {
        _armAutoTimer();
      } else {
        _cancelTimers();
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _appResumed = state == AppLifecycleState.resumed;
    if (_appResumed) {
      _armAutoTimer();
    } else {
      _cancelTimers();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cancelTimers();
    _controller.dispose();
    super.dispose();
  }

  void _cancelTimers() {
    _autoTimer?.cancel();
    _autoTimer = null;
    _resumeTimer?.cancel();
    _resumeTimer = null;
  }

  void _armAutoTimer() {
    _autoTimer?.cancel();
    _resumeTimer?.cancel();
    if (!_canAutoScroll) return;
    _autoTimer = Timer(widget.interval, _advance);
  }

  Future<void> _advance() async {
    if (!_canAutoScroll || !_controller.hasClients) return;

    final current = _controller.page?.round() ?? _basePage;
    final next = current + 1;
    _autoAnimating = true;
    try {
      await _controller.animateToPage(
        next,
        duration: widget.animationDuration,
        curve: widget.animationCurve,
      );
    } finally {
      _autoAnimating = false;
    }
    if (mounted && !_userDragging) _armAutoTimer();
  }

  void _onUserInteractionStart() {
    _autoAnimating = false;
    _userDragging = true;
    _cancelTimers();
  }

  void _onUserInteractionEnd() {
    if (_autoAnimating) return;
    _userDragging = false;
    _resumeTimer?.cancel();
    if (!_canAutoScroll) return;
    _resumeTimer = Timer(widget.resumeIdle, _armAutoTimer);
  }

  int _toLogical(int page) {
    if (widget.itemCount <= 0) return 0;
    return page % widget.itemCount;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.itemCount <= 0) {
      return SizedBox(height: widget.height);
    }

    final single = widget.itemCount == 1;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: widget.height,
          child: NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              if (notification.depth != 0) return false;

              if (notification is ScrollStartNotification &&
                  notification.dragDetails != null) {
                _onUserInteractionStart();
              } else if (notification is ScrollEndNotification) {
                _onUserInteractionEnd();
              }
              return false;
            },
            child: PageView.builder(
              controller: _controller,
              physics: single
                  ? const NeverScrollableScrollPhysics()
                  : null,
              // Large finite count keeps viewportFraction peaking stable
              // while still feeling endless for typical carousel sizes.
              itemCount: single
                  ? 1
                  : widget.itemCount * _infiniteMultiplier * 2,
              onPageChanged: (page) {
                final logical = _toLogical(page);
                if (logical != _logicalIndex) {
                  setState(() => _logicalIndex = logical);
                  widget.onPageChanged?.call(logical);
                }
              },
              itemBuilder: (context, page) {
                final index = _toLogical(page);
                final isActive = index == _logicalIndex;
                return AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    double scale = 1.0;
                    if (_controller.position.haveDimensions) {
                      final pageValue =
                          _controller.page ?? page.toDouble();
                      scale = (1 - (pageValue - page).abs() * 0.12)
                          .clamp(0.88, 1.0);
                    }
                    return Transform.scale(scale: scale, child: child);
                  },
                  // Inset so MediaPosterCard glow (ambient blur≈22 + lift
                  // blur 16 / dy 4) paints inside PageView's default clip —
                  // prefer this over Clip.none to avoid bleed into indicators.
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(8, 14, 8, 24),
                    child: widget.itemBuilder(context, index, isActive),
                  ),
                );
              },
            ),
          ),
        ),
        if (widget.showIndicators && widget.itemCount > 1) ...[
          const SizedBox(height: 12),
          _CarouselIndicators(
            count: widget.itemCount,
            currentIndex: _logicalIndex,
          ),
        ],
      ],
    );
  }
}

class _CarouselIndicators extends StatelessWidget {
  const _CarouselIndicators({
    required this.count,
    required this.currentIndex,
  });

  final int count;
  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        final isActive = index == currentIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: isActive ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: isActive
                ? colorScheme.primary
                : colorScheme.onSurface.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}
