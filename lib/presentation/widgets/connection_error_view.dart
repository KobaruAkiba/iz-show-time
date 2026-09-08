import 'package:flutter/material.dart';

import '../../core/network/api_error.dart';
import '../../core/network/network_feedback.dart';
import '../../l10n/l10n.dart';
import 'connection_feedback.dart';

/// Full-screen / section failure UI with high-contrast affordances.
///
/// Prefer this over ad-hoc cloud-off + text for blocking content loads
/// (Home trending, Search results).
class ConnectionErrorView extends StatelessWidget {
  const ConnectionErrorView({
    super.key,
    required this.onRetry,
    this.errorType,
    this.message,
    this.title,
  });

  final VoidCallback onRetry;
  final ApiErrorType? errorType;
  final String? message;
  final String? title;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isConnection = errorType == null ||
        NetworkFeedback.isConnectionIssue(errorType!);
    final kind = errorType == null
        ? ConnectionIssueKind.unreachable
        : NetworkFeedback.issueKindFor(errorType!);

    return ConnectionStatusPanel(
      kind: isConnection ? kind : ConnectionIssueKind.unreachable,
      onRetry: onRetry,
      title: title ?? (isConnection ? null : l10n.errorGeneric),
      body: message ??
          (errorType != null
              ? NetworkFeedback.messageFor(errorType!, l10n)
              : l10n.errorGeneric),
    );
  }
}
