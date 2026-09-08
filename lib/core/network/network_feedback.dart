import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import 'api_error.dart';
import 'connection_alert_style.dart';

/// Global, reusable user feedback for connection problems and slow API calls.
///
/// Wire [messengerKey] into [MaterialApp.scaffoldMessengerKey]. Use [runSilent]
/// around background / non-UI network work so SnackBars and banners stay quiet.
///
/// When a full-screen [ConnectionAwareLoading] is mounted, call
/// [beginInlineSlowFeedback] / [endInlineSlowFeedback] so the inline hint owns
/// slow feedback and the global MaterialBanner stays suppressed.
abstract final class NetworkFeedback {
  static final GlobalKey<ScaffoldMessengerState> messengerKey =
      GlobalKey<ScaffoldMessengerState>();

  static int _silentDepth = 0;
  static int _slowRequestCount = 0;
  static int _inlineSlowOwners = 0;
  static bool _slowBannerVisible = false;

  static bool get isSilent => _silentDepth > 0;

  /// Suppresses transient connection UI while [action] runs (episode checks,
  /// background refresh, etc.).
  static Future<T> runSilent<T>(Future<T> Function() action) async {
    _silentDepth++;
    try {
      return await action();
    } finally {
      _silentDepth--;
    }
  }

  /// Registers a full-screen loading UI that shows its own slow-connection hint.
  /// Suppresses the global MaterialBanner for the duration it is mounted.
  static void beginInlineSlowFeedback() {
    _inlineSlowOwners++;
    if (_inlineSlowOwners == 1) {
      _hideSlowBanner();
    }
  }

  /// Unregisters an inline slow-feedback owner (pair with [beginInlineSlowFeedback]).
  static void endInlineSlowFeedback() {
    if (_inlineSlowOwners <= 0) return;
    _inlineSlowOwners--;
  }

  static bool isConnectionIssue(ApiErrorType type) {
    return type == ApiErrorType.networkError || type == ApiErrorType.timeout;
  }

  static ConnectionIssueKind issueKindFor(ApiErrorType type) {
    switch (type) {
      case ApiErrorType.timeout:
        return ConnectionIssueKind.timeout;
      case ApiErrorType.networkError:
        return ConnectionIssueKind.noConnection;
      default:
        return ConnectionIssueKind.unreachable;
    }
  }

  static String messageFor(ApiErrorType type, [AppLocalizations? l10n]) {
    return apiErrorMessage(type, l10n);
  }

  /// Transient SnackBar for connection / API failures (detail sheets, load-more).
  static void showError(
    ApiErrorType type, {
    String? message,
    VoidCallback? onRetry,
  }) {
    if (isSilent) return;

    final messenger = messengerKey.currentState;
    if (messenger == null) return;

    final context = messenger.context;
    if (!context.mounted) return;

    final kind = issueKindFor(type);
    // Hide banner UI only — Dio still owns _slowRequestCount via dismissSlowConnection.
    _hideSlowBanner();
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        buildConnectionSnackBar(
          context: context,
          kind: kind,
          message: message ?? messageFor(type, context.l10n),
          onRetry: onRetry,
        ),
      );
  }

  static void showErrorFrom(Object error, {VoidCallback? onRetry}) {
    if (error is ApiException) {
      showError(error.type, message: error.message, onRetry: onRetry);
      return;
    }
    showError(ApiErrorType.networkError, onRetry: onRetry);
  }

  /// Tracks a slow in-flight request. Shows a MaterialBanner only when no
  /// [ConnectionAwareLoading] owns slow feedback and the app is not silent.
  static void showSlowConnection() {
    final becomingFirst = _slowRequestCount == 0;
    _slowRequestCount++;

    if (!becomingFirst || isSilent || _inlineSlowOwners > 0) return;

    final messenger = messengerKey.currentState;
    if (messenger == null) return;

    final context = messenger.context;
    if (!context.mounted) return;

    _slowBannerVisible = true;
    messenger
      ..hideCurrentMaterialBanner()
      ..showMaterialBanner(
        buildConnectionBanner(
          context: context,
          kind: ConnectionIssueKind.slow,
          message: context.l10n.connectionSlow,
          onDismiss: () {
            _slowRequestCount = 0;
            _hideSlowBanner();
          },
        ),
      );
  }

  static void dismissSlowConnection() {
    if (_slowRequestCount <= 0) return;
    _slowRequestCount--;
    if (_slowRequestCount > 0) return;
    _hideSlowBanner();
  }

  static void _hideSlowBanner() {
    if (!_slowBannerVisible) return;
    _slowBannerVisible = false;
    messengerKey.currentState?.hideCurrentMaterialBanner();
  }
}
