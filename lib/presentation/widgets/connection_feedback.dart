import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/network/connection_alert_style.dart';
import '../../core/network/network_feedback.dart';
import '../../l10n/l10n.dart';

export '../../core/network/connection_alert_style.dart';

/// Full-area, non-modal status for blocking content loads.
///
/// Use when primary content cannot be shown (home trending, search results).
class ConnectionStatusPanel extends StatelessWidget {
  const ConnectionStatusPanel({
    super.key,
    required this.kind,
    this.onRetry,
    this.title,
    this.body,
  });

  final ConnectionIssueKind kind;
  final VoidCallback? onRetry;
  final String? title;
  final String? body;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final colors = ConnectionFeedbackColors.resolve(scheme, kind);
    final resolvedTitle = title ?? ConnectionFeedbackCopy.title(l10n, kind);
    final resolvedBody = body ?? ConnectionFeedbackCopy.body(l10n, kind);

    return Semantics(
      container: true,
      liveRegion: true,
      label: '$resolvedTitle. $resolvedBody',
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  ConnectionFeedbackCopy.icon(kind),
                  size: 56,
                  color: colors.accent,
                ),
                const SizedBox(height: 16),
                Text(
                  resolvedTitle,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: scheme.onSurface,
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  resolvedBody,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                        height: 1.4,
                        fontSize: 16,
                      ),
                ),
                if (onRetry != null) ...[
                  const SizedBox(height: 24),
                  ConstrainedBox(
                    constraints: const BoxConstraints(
                      minWidth: 160,
                      minHeight: 48,
                    ),
                    child: FilledButton.icon(
                      onPressed: onRetry,
                      icon: const Icon(Icons.refresh_rounded, size: 20),
                      label: Text(l10n.actionRetry),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Compact inline row shown while a request is still in flight (slow path).
class ConnectionSlowStatus extends StatelessWidget {
  const ConnectionSlowStatus({super.key, this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final colors =
        ConnectionFeedbackColors.resolve(scheme, ConnectionIssueKind.slow);
    final text = message ?? l10n.connectionSlow;

    return Semantics(
      liveRegion: true,
      label: text,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: scheme.outlineVariant),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: colors.accent,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  text,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colors.foreground,
                        fontSize: 15,
                        height: 1.35,
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Centered spinner that reveals a slow-connection hint after a delay.
class ConnectionAwareLoading extends StatefulWidget {
  const ConnectionAwareLoading({
    super.key,
    this.slowAfter = AppConstants.slowConnectionThreshold,
    this.message,
  });

  final Duration slowAfter;
  final String? message;

  @override
  State<ConnectionAwareLoading> createState() => _ConnectionAwareLoadingState();
}

class _ConnectionAwareLoadingState extends State<ConnectionAwareLoading> {
  Timer? _timer;
  bool _showSlowHint = false;

  @override
  void initState() {
    super.initState();
    NetworkFeedback.beginInlineSlowFeedback();
    _timer = Timer(widget.slowAfter, () {
      if (mounted) setState(() => _showSlowHint = true);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    NetworkFeedback.endInlineSlowFeedback();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            if (_showSlowHint) ...[
              const SizedBox(height: 24),
              ConnectionSlowStatus(
                message: widget.message ?? l10n.connectionSlow,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// ScaffoldMessenger helpers for local (context-bound) connection feedback.
extension ConnectionFeedbackMessenger on BuildContext {
  void showConnectionSnackBar({
    required ConnectionIssueKind kind,
    VoidCallback? onRetry,
    String? message,
    Duration duration = const Duration(seconds: 5),
  }) {
    final text = message ?? ConnectionFeedbackCopy.body(l10n, kind);
    final messenger = ScaffoldMessenger.of(this);

    messenger.clearSnackBars();
    messenger.showSnackBar(
      buildConnectionSnackBar(
        context: this,
        kind: kind,
        message: text,
        onRetry: onRetry,
        duration: duration,
      ),
    );
  }

  void showConnectionBanner({
    required ConnectionIssueKind kind,
    VoidCallback? onRetry,
    String? message,
  }) {
    final text = message ??
        '${ConnectionFeedbackCopy.title(l10n, kind)}. '
            '${ConnectionFeedbackCopy.body(l10n, kind)}';
    final messenger = ScaffoldMessenger.of(this);

    messenger.clearMaterialBanners();
    messenger.showMaterialBanner(
      buildConnectionBanner(
        context: this,
        kind: kind,
        message: text,
        onRetry: onRetry == null
            ? null
            : () {
                messenger.hideCurrentMaterialBanner();
                onRetry();
              },
        onDismiss: messenger.hideCurrentMaterialBanner,
      ),
    );
  }

  void hideConnectionBanner() {
    ScaffoldMessenger.of(this).hideCurrentMaterialBanner();
  }
}
