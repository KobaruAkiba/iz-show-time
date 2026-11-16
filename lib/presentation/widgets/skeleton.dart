import 'package:flutter/material.dart';

/// Pulses its [child] to signal loading. Wrap a layout of [SkeletonBox]es
/// shaped like the content being loaded.
class Skeleton extends StatefulWidget {
  const Skeleton({super.key, required this.child});

  final Widget child;

  @override
  State<Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<Skeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: FadeTransition(
        opacity: Tween<double>(begin: 0.45, end: 1).animate(_controller),
        child: widget.child,
      ),
    );
  }
}

/// Placeholder block standing in for a piece of content.
class SkeletonBox extends StatelessWidget {
  const SkeletonBox({
    super.key,
    this.width,
    required this.height,
    this.radius = 8,
  });

  final double? width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

/// Rows shaped like the media list tiles (poster, title, two lines).
class MediaListSkeleton extends StatelessWidget {
  const MediaListSkeleton({super.key, this.itemCount = 6});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return Skeleton(
      child: ListView.separated(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: itemCount,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, __) => const _TileSkeleton(),
      ),
    );
  }
}

class _TileSkeleton extends StatelessWidget {
  const _TileSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        SkeletonBox(width: 56, height: 84, radius: 10),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SkeletonBox(width: 160, height: 14),
              SizedBox(height: 8),
              SkeletonBox(height: 12),
              SizedBox(height: 6),
              SkeletonBox(width: 110, height: 12),
            ],
          ),
        ),
      ],
    );
  }
}

/// Home while trending loads: section title, poster card, a few tiles.
class HomeSkeleton extends StatelessWidget {
  const HomeSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const Skeleton(
      child: SingleChildScrollView(
        physics: NeverScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(16, 20, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SkeletonBox(width: 170, height: 22),
            SizedBox(height: 8),
            SkeletonBox(width: 230, height: 12),
            SizedBox(height: 20),
            Center(child: SkeletonBox(width: 250, height: 370, radius: 16)),
            SizedBox(height: 32),
            SkeletonBox(width: 190, height: 22),
            SizedBox(height: 16),
            _TileSkeleton(),
            SizedBox(height: 12),
            _TileSkeleton(),
          ],
        ),
      ),
    );
  }
}

/// Detail sheet while the title loads: poster, title and chips, text lines.
class DetailSkeleton extends StatelessWidget {
  const DetailSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const Skeleton(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SkeletonBox(width: 100, height: 150, radius: 12),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonBox(height: 22),
                    SizedBox(height: 12),
                    SkeletonBox(width: 140, height: 16),
                    SizedBox(height: 12),
                    SkeletonBox(width: 180, height: 16),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 24),
          SkeletonBox(height: 44, radius: 22),
          SizedBox(height: 24),
          SkeletonBox(width: 120, height: 14),
          SizedBox(height: 10),
          SkeletonBox(height: 12),
          SizedBox(height: 6),
          SkeletonBox(height: 12),
          SizedBox(height: 6),
          SkeletonBox(width: 220, height: 12),
        ],
      ),
    );
  }
}
