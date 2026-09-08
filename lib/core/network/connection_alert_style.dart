import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';

/// Connection-focused issue kinds for mobile feedback.
enum ConnectionIssueKind {
  noConnection,
  timeout,
  slow,
  unreachable,
}

/// High-contrast colors for connection surfaces (SnackBar / banner / panel).
abstract final class ConnectionFeedbackColors {
  static ({Color background, Color foreground, Color accent}) resolve(
    ColorScheme scheme,
    ConnectionIssueKind kind,
  ) {
    switch (kind) {
      case ConnectionIssueKind.noConnection:
      case ConnectionIssueKind.unreachable:
        return (
          background: scheme.errorContainer,
          foreground: scheme.onErrorContainer,
          accent: scheme.error,
        );
      case ConnectionIssueKind.timeout:
        return (
          background: scheme.tertiaryContainer,
          foreground: scheme.onTertiaryContainer,
          accent: scheme.tertiary,
        );
      case ConnectionIssueKind.slow:
        return (
          background: scheme.surfaceContainerHighest,
          foreground: scheme.onSurface,
          accent: scheme.primary,
        );
    }
  }
}

/// Shared copy + iconography for connection feedback.
abstract final class ConnectionFeedbackCopy {
  static String title(AppLocalizations l10n, ConnectionIssueKind kind) {
    switch (kind) {
      case ConnectionIssueKind.noConnection:
        return l10n.connectionNoNetworkTitle;
      case ConnectionIssueKind.timeout:
        return l10n.connectionTimeoutTitle;
      case ConnectionIssueKind.slow:
        return l10n.connectionSlowTitle;
      case ConnectionIssueKind.unreachable:
        return l10n.connectionUnreachableTitle;
    }
  }

  static String body(AppLocalizations l10n, ConnectionIssueKind kind) {
    switch (kind) {
      case ConnectionIssueKind.noConnection:
        return l10n.errorNoConnection;
      case ConnectionIssueKind.timeout:
        return l10n.errorTimeout;
      case ConnectionIssueKind.slow:
        return l10n.connectionSlow;
      case ConnectionIssueKind.unreachable:
        return l10n.errorUnreachable;
    }
  }

  static IconData icon(ConnectionIssueKind kind) {
    switch (kind) {
      case ConnectionIssueKind.noConnection:
        return Icons.wifi_off_rounded;
      case ConnectionIssueKind.timeout:
        return Icons.timer_off_outlined;
      case ConnectionIssueKind.slow:
        return Icons.hourglass_top_rounded;
      case ConnectionIssueKind.unreachable:
        return Icons.cloud_off_rounded;
    }
  }
}

/// Builds a high-contrast floating [SnackBar] for connection issues.
SnackBar buildConnectionSnackBar({
  required BuildContext context,
  required ConnectionIssueKind kind,
  required String message,
  VoidCallback? onRetry,
  Duration duration = const Duration(seconds: 5),
}) {
  final l10n = context.l10n;
  final scheme = Theme.of(context).colorScheme;
  final colors = ConnectionFeedbackColors.resolve(scheme, kind);

  return SnackBar(
    behavior: SnackBarBehavior.floating,
    duration: duration,
    backgroundColor: colors.background,
    elevation: 6,
    margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10),
      side: BorderSide(color: colors.accent.withValues(alpha: 0.55)),
    ),
    content: Row(
      children: [
        Icon(
          ConnectionFeedbackCopy.icon(kind),
          color: colors.foreground,
          size: 22,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            message,
            style: TextStyle(
              color: colors.foreground,
              fontSize: 15,
              height: 1.35,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
    action: onRetry == null
        ? null
        : SnackBarAction(
            label: l10n.actionRetry,
            textColor: colors.foreground,
            onPressed: onRetry,
          ),
  );
}

/// Builds a high-contrast [MaterialBanner] for connection / slow status.
MaterialBanner buildConnectionBanner({
  required BuildContext context,
  required ConnectionIssueKind kind,
  required String message,
  VoidCallback? onRetry,
  VoidCallback? onDismiss,
}) {
  final l10n = context.l10n;
  final scheme = Theme.of(context).colorScheme;
  final colors = ConnectionFeedbackColors.resolve(scheme, kind);

  return MaterialBanner(
    backgroundColor: colors.background,
    elevation: 2,
    padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
    leading: Icon(
      ConnectionFeedbackCopy.icon(kind),
      color: colors.foreground,
      size: 24,
    ),
    content: Text(
      message,
      style: TextStyle(
        color: colors.foreground,
        fontSize: 15,
        height: 1.35,
        fontWeight: FontWeight.w600,
      ),
    ),
    actions: [
      if (onRetry != null)
        TextButton(
          onPressed: onRetry,
          style: TextButton.styleFrom(
            foregroundColor: colors.foreground,
            minimumSize: const Size(48, 48),
            padding: const EdgeInsets.symmetric(horizontal: 12),
          ),
          child: Text(l10n.actionRetry),
        ),
      TextButton(
        onPressed: onDismiss,
        style: TextButton.styleFrom(
          foregroundColor: colors.foreground,
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.symmetric(horizontal: 12),
        ),
        child: Text(l10n.actionDismiss),
      ),
    ],
  );
}
