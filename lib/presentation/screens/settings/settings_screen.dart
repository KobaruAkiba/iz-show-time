import 'package:flutter/material.dart';
import '../../widgets/app_page_header.dart';
import '../../../core/services/app_services.dart';
import '../../../l10n/l10n.dart';

/// Settings screen with app preferences
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static const _appVersion = '1.0.0';
  static const _tmdbLogoAsset = 'assets/images/TmdbLogo.jpg';

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppPageHeader(),
            Expanded(
              child: ListView(
                children: [
                  _buildSectionTitle(context, l10n.settingsAbout),
                  ListTile(
                    leading: const Icon(Icons.info_outline),
                    title: Text(l10n.settingsVersion),
                    subtitle: const Text(_appVersion),
                  ),
                  _buildTmdbAttribution(context),
                  const Divider(),
                  _buildSectionTitle(context, l10n.settingsDataManagement),
                  ListTile(
                    leading: const Icon(Icons.cleaning_services_outlined),
                    title: Text(l10n.settingsClearCacheTitle),
                    subtitle: Text(l10n.settingsClearCacheSubtitle),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showClearCacheDialog(context),
                  ),
                  ListTile(
                    leading: Icon(Icons.delete_outline, color: Colors.red[500]),
                    title: Text(
                      l10n.settingsClearAllTitle,
                      style: TextStyle(color: Colors.red[700]),
                    ),
                    subtitle: Text(l10n.settingsClearAllSubtitle),
                    trailing: Icon(Icons.chevron_right, color: Colors.red[400]),
                    onTap: () => _showClearDataDialog(context),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
      ),
    );
  }

  Widget _buildTmdbAttribution(BuildContext context) {
    final l10n = context.l10n;
    final bodyStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Colors.grey[700],
        );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.settingsTmdbAttribution,
            style: bodyStyle,
          ),
          const SizedBox(height: 12),
          Center(
            child: Image.asset(
              _tmdbLogoAsset,
              height: 40,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            l10n.settingsTmdbDisclaimer,
            style: bodyStyle,
          ),
        ],
      ),
    );
  }

  void _showClearCacheDialog(BuildContext context) {
    final l10n = context.l10n;

    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.cleaning_services_outlined),
        title: Text(l10n.settingsClearCacheTitle),
        content: Text(l10n.settingsClearCacheBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.actionCancel),
          ),
          FilledButton(
            onPressed: () {
              AppServices().clearCacheData();
              if (dialogContext.mounted) Navigator.pop(dialogContext);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(l10n.cacheClearedSuccessfully),
                  ),
                );
              }
            },
            child: Text(l10n.settingsClearCacheConfirm),
          ),
        ],
      ),
    );
  }

  void _showClearDataDialog(BuildContext context) {
    final l10n = context.l10n;

    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: Icon(Icons.warning_amber_rounded, color: Colors.red[700]),
        title: Text(l10n.settingsClearAllTitle),
        content: Text(l10n.settingsClearAllBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.actionCancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red[700],
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              await AppServices().clearAllData();
              if (dialogContext.mounted) Navigator.pop(dialogContext);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(l10n.allDataClearedSuccessfully),
                  ),
                );
              }
            },
            child: Text(l10n.settingsClearAllConfirm),
          ),
        ],
      ),
    );
  }
}
