import 'package:flutter/material.dart';

/// Settings screen with app preferences
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Notification interval in hours
  int _notificationInterval = 4;
  final List<int> _intervalOptions = [1, 3, 6, 12, 24];

  // Toggle states
  bool _isDarkModeEnabled = false;
  bool _isNotificationsEnabled = true;
  bool _isBackgroundChecksEnabled = true;
  bool _showTagsInResults = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          // App Info Section
          _buildSectionTitle('App Preferences'),

          _buildSwitchListTile(
            title: 'Dark Mode',
            subtitle: 'Toggle system or manual dark theme',
            trailing: Text(_isDarkModeEnabled ? 'ON' : 'OFF'),
            value: _isDarkModeEnabled,
            onChanged: (value) {
              setState(() => _isDarkModeEnabled = value);
            },
          ),

          const Divider(),

          // Notification Settings Section
          _buildSectionTitle('Notifications'),

          _buildSwitchListTile(
            title: 'Episode Alerts',
            subtitle: 'Get notified when new episodes air',
            trailing: Text(_isNotificationsEnabled ? 'ON' : 'OFF'),
            value: _isNotificationsEnabled,
            onChanged: (value) {
              setState(() => _isNotificationsEnabled = value);
            },
          ),

          if (_isNotificationsEnabled) ...[
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'Check Interval',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            Wrap(
              spacing: 8,
              children: _intervalOptions.map((interval) {
                return ChoiceChip(
                  label: Text('\$${interval}h'),
                  selected: _notificationInterval == interval,
                  onSelected: (selected) {
                    if (selected)
                      setState(() => _notificationInterval = interval);
                  },
                  selectedColor: Theme.of(context).colorScheme.primaryContainer,
                  checkmarkColor:
                      Theme.of(context).colorScheme.onPrimaryContainer,
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
          ],

          _buildSwitchListTile(
            title: 'Background Checks',
            subtitle: 'Check for new episodes in background',
            trailing: Text(_isBackgroundChecksEnabled ? 'ON' : 'OFF'),
            value: _isBackgroundChecksEnabled,
            onChanged: (value) {
              setState(() => _isBackgroundChecksEnabled = value);
            },
          ),

          const Divider(),

          // Display Settings Section
          _buildSectionTitle('Display'),

          _buildSwitchListTile(
            title: 'Show Tags in Search',
            subtitle: 'Include tags in search results',
            trailing: Text(_showTagsInResults ? 'ON' : 'OFF'),
            value: _showTagsInResults,
            onChanged: (value) {
              setState(() => _showTagsInResults = value);
            },
          ),

          const Divider(),

          // About Section
          _buildSectionTitle('About'),

          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('Version 1.0.0'),
            subtitle: Text('Build date: ${DateTime.now().toString()}'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {},
          ),

          ListTile(
            leading: const Icon(Icons.description),
            title: const Text('Privacy Policy'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _showExternalUrl('https://yourapp.com/privacy'),
          ),

          ListTile(
            leading: const Icon(Icons.policy),
            title: const Text('Terms of Service'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _showExternalUrl('https://yourapp.com/terms'),
          ),

          const SizedBox(height: 20),

          // Data Management Section
          _buildSectionTitle('Data Management'),

          ListTile(
            leading: Icon(Icons.delete_outline, color: Colors.red[500]),
            title: Text('Clear All Data',
                style: TextStyle(color: Colors.red[700])),
            subtitle: const Text('This will remove all catalogue items'),
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _showClearDataDialog(),
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
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

  Widget _buildSwitchListTile({
    required String title,
    required String subtitle,
    required Widget trailing,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      title: Text(title),
      subtitle: Text(subtitle),
      secondary: trailing,
      activeThumbColor: Theme.of(context).colorScheme.primary,
      value: value,
      onChanged: onChanged,
    );
  }

  void _showExternalUrl(String url) {
    // In real implementation, open URL in browser
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Opening $url...')),
    );
  }

  void _showClearDataDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Data'),
        content: const Text(
            'Are you sure you want to clear all your catalogue data? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              // Implement actual data clearing logic
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('All data cleared successfully')),
              );
              Navigator.pop(context);
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
