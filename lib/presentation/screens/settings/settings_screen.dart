import 'package:flutter/material.dart';
import '../../widgets/app_page_header.dart';
import '../../../core/services/app_services.dart';

/// Settings screen with app preferences
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static const _appVersion = '1.0.0';
  static const _tmdbLogoAsset = 'assets/images/TmdbLogo.jpg';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppPageHeader(),
            Expanded(
              child: ListView(
                children: [
                  _buildSectionTitle(context, 'About'),
                  const ListTile(
                    leading: Icon(Icons.info_outline),
                    title: Text('Version'),
                    subtitle: Text(_appVersion),
                  ),
                  _buildTmdbAttribution(context),
                  const Divider(),
                  _buildSectionTitle(context, 'Data Management'),
                  ListTile(
                    leading: const Icon(Icons.cleaning_services_outlined),
                    title: const Text('Clear Cache Data'),
                    subtitle: const Text(
                      'Free space by removing cached API responses. '
                      'Catalogue and watch history are kept',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showClearCacheDialog(context),
                  ),
                  ListTile(
                    leading: Icon(Icons.delete_outline, color: Colors.red[500]),
                    title: Text(
                      'Clear All Data',
                      style: TextStyle(color: Colors.red[700]),
                    ),
                    subtitle: const Text(
                      'Remove catalogue, watch history, and cached data',
                    ),
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
    final bodyStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Colors.grey[700],
        );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Data and images provided from The Movie Database',
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
            'This product uses the TMDB API but is not endorsed or certified by TMDB.',
            style: bodyStyle,
          ),
        ],
      ),
    );
  }

  void _showClearCacheDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.cleaning_services_outlined),
        title: const Text('Clear Cache Data'),
        content: const Text(
          'This will remove cached API responses to free space on your device.\n\n'
          'Your catalogue and watch history will not be deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              AppServices().clearCacheData();
              if (dialogContext.mounted) Navigator.pop(dialogContext);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Cache data cleared successfully'),
                  ),
                );
              }
            },
            child: const Text('Clear Cache'),
          ),
        ],
      ),
    );
  }

  void _showClearDataDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: Icon(Icons.warning_amber_rounded, color: Colors.red[700]),
        title: const Text('Clear All Data'),
        content: const Text(
          'This will permanently delete your catalogue, watch history, '
          'and cached data.\n\n'
          'Your data cannot be recovered after this action.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
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
                  const SnackBar(
                    content: Text('All data cleared successfully'),
                  ),
                );
              }
            },
            child: const Text('Delete All Data'),
          ),
        ],
      ),
    );
  }
}
