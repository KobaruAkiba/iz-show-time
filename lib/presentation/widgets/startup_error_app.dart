import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../../core/theme/app_theme.dart';
import '../../l10n/l10n.dart';

/// Shown instead of the app when startup fails, so the user is not left on
/// the splash screen with no way forward.
class StartupErrorApp extends StatefulWidget {
  const StartupErrorApp({super.key, required this.onRetry});

  /// Runs startup again; replaces this app on success.
  final Future<void> Function() onRetry;

  @override
  State<StartupErrorApp> createState() => _StartupErrorAppState();
}

class _StartupErrorAppState extends State<StartupErrorApp> {
  bool _retrying = false;

  Future<void> _retry() async {
    setState(() => _retrying = true);
    try {
      await widget.onRetry();
    } finally {
      if (mounted) setState(() => _retrying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) {
          final l10n = context.l10n;
          final textTheme = Theme.of(context).textTheme;
          return Scaffold(
            body: SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 56,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        l10n.startupErrorTitle,
                        textAlign: TextAlign.center,
                        style: textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.startupErrorBody,
                        textAlign: TextAlign.center,
                        style: textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 24),
                      FilledButton.icon(
                        onPressed: _retrying ? null : _retry,
                        icon: const Icon(Icons.refresh),
                        label: Text(l10n.actionRetry),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
