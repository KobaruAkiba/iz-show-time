import 'dart:convert';
import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_file_dialog/flutter_file_dialog.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../widgets/app_page_header.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/app_services.dart';
import '../../../l10n/l10n.dart';

/// Settings screen with app preferences
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static const _appVersion = '1.0.0';
  static const _authorName = 'Mirko Corba';
  static const _tmdbLogoAsset = 'assets/images/TmdbLogo.png';
  static const _paypalLogoAsset = 'assets/images/PaypalLogo.png';

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
                  _buildSectionTitle(context, l10n.settingsAppearance),
                  _buildThemeSelector(context),
                  const Divider(),
                  _buildSectionTitle(context, l10n.settingsCredits),
                  _buildTmdbAttribution(context),
                  const Divider(),
                  _buildSectionTitle(context, l10n.settingsSupportMe),
                  _buildSupportMeSection(context),
                  const Divider(),
                  _buildSectionTitle(context, l10n.settingsDataManagement),
                  ListTile(
                    leading: const Icon(Icons.import_export_outlined),
                    title: Text(l10n.settingsBackupRestoreTitle),
                    subtitle: Text(l10n.settingsBackupRestoreSubtitle),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showBackupRestoreActions(context),
                  ),
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
                  const Divider(),
                  _buildSectionTitle(context, l10n.settingsAbout),
                  ListTile(
                    leading: const Icon(Icons.info_outline),
                    title: Text(l10n.settingsVersion),
                    subtitle: const Text(_appVersion),
                  ),
                  ListTile(
                    leading: const Icon(Icons.person_outline),
                    title: Text(l10n.settingsAuthor),
                    subtitle: const Text(_authorName),
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
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.primary,
            ),
      ),
    );
  }

  Widget _buildThemeSelector(BuildContext context) {
    final l10n = context.l10n;

    return ValueListenableBuilder<ThemeMode>(
      valueListenable: AppServices().themeModeListenable,
      builder: (context, themeMode, _) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: SegmentedButton<ThemeMode>(
            segments: [
              ButtonSegment<ThemeMode>(
                value: ThemeMode.system,
                label: Text(l10n.settingsThemeSystem),
                icon: const Icon(Icons.brightness_auto),
              ),
              ButtonSegment<ThemeMode>(
                value: ThemeMode.light,
                label: Text(l10n.settingsThemeLight),
                icon: const Icon(Icons.light_mode_outlined),
              ),
              ButtonSegment<ThemeMode>(
                value: ThemeMode.dark,
                label: Text(l10n.settingsThemeDark),
                icon: const Icon(Icons.dark_mode_outlined),
              ),
            ],
            selected: {themeMode},
            onSelectionChanged: (selected) {
              AppServices().setThemeMode(selected.first);
            },
          ),
        );
      },
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
            child: InkWell(
              onTap: () => _openTmdbHome(context),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Image.asset(
                  _tmdbLogoAsset,
                  height: 40,
                  fit: BoxFit.contain,
                ),
              ),
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

  Future<void> _openTmdbHome(BuildContext context) async {
    final l10n = context.l10n;
    final uri = Uri.parse(AppConstants.tmdbHomeUrl);

    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.settingsTmdbLinkError)),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.settingsTmdbLinkError)),
        );
      }
    }
  }

  Widget _buildSupportMeSection(BuildContext context) {
    final l10n = context.l10n;
    final bodyStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Colors.grey[700],
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Text(
            l10n.settingsSupportMeDescription,
            style: bodyStyle,
          ),
        ),
        ListTile(
          leading: const Icon(Icons.volunteer_activism_outlined),
          title: Text.rich(
            TextSpan(
              style: Theme.of(context).textTheme.bodyLarge,
              children: [
                TextSpan(text: l10n.settingsDonatePaypal),
                WidgetSpan(
                  alignment: PlaceholderAlignment.middle,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 2),
                    child: Image.asset(
                      _paypalLogoAsset,
                      height: 18,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ],
            ),
          ),
          trailing: const Icon(Icons.open_in_new),
          onTap: () => _openPaypalDonate(context),
        ),
      ],
    );
  }

  Future<void> _openPaypalDonate(BuildContext context) async {
    final l10n = context.l10n;
    final uri = Uri.parse(AppConstants.paypalDonateUrl);

    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.settingsDonatePaypalError)),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.settingsDonatePaypalError)),
        );
      }
    }
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
            onPressed: () async {
              await AppServices().clearCacheData();
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

  Future<void> _showBackupRestoreActions(BuildContext context) async {
    final l10n = context.l10n;
    final action = await showModalBottomSheet<_BackupAction>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.save_alt_outlined),
              title: Text(l10n.settingsBackupExportTitle),
              subtitle: Text(l10n.settingsBackupExportSubtitle),
              onTap: () => Navigator.pop(sheetContext, _BackupAction.backup),
            ),
            ListTile(
              leading: const Icon(Icons.restore_outlined),
              title: Text(l10n.settingsBackupImportTitle),
              subtitle: Text(l10n.settingsBackupImportSubtitle),
              onTap: () => Navigator.pop(sheetContext, _BackupAction.restore),
            ),
          ],
        ),
      ),
    );

    if (!context.mounted || action == null) return;

    switch (action) {
      case _BackupAction.backup:
        await _exportBackup(context);
      case _BackupAction.restore:
        await _restoreBackup(context);
    }
  }

  Future<_BackupExportDestination?> _pickBackupExportDestination(
    BuildContext context,
  ) {
    final l10n = context.l10n;
    return showModalBottomSheet<_BackupExportDestination>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.folder_outlined),
              title: Text(l10n.settingsBackupSaveLocallyTitle),
              subtitle: Text(l10n.settingsBackupSaveLocallySubtitle),
              onTap: () => Navigator.pop(
                sheetContext,
                _BackupExportDestination.saveLocally,
              ),
            ),
            ListTile(
              leading: const Icon(Icons.share_outlined),
              title: Text(l10n.settingsBackupShareTitle),
              subtitle: Text(l10n.settingsBackupShareSubtitle),
              onTap: () => Navigator.pop(
                sheetContext,
                _BackupExportDestination.share,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportBackup(BuildContext context) async {
    final l10n = context.l10n;

    try {
      final jsonBackup = await AppServices().exportUserDataBackup();
      if (!context.mounted) return;

      final suggestedName = _buildBackupFileName();
      final bytes = Uint8List.fromList(utf8.encode(jsonBackup));

      final bool saved;
      if (_isMobileBackupPlatform) {
        final destination = await _pickBackupExportDestination(context);
        if (!context.mounted || destination == null) return;

        saved = switch (destination) {
          _BackupExportDestination.saveLocally =>
            await _saveBackupLocally(bytes, suggestedName),
          _BackupExportDestination.share =>
            await _shareBackup(bytes, suggestedName, l10n),
        };
      } else {
        saved = await _saveBackupWithDesktopPicker(bytes, suggestedName);
      }

      if (!saved || !context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.backupExportedSuccessfully)),
      );
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.settingsBackupExportError)),
        );
      }
    }
  }

  Future<bool> _saveBackupLocally(Uint8List bytes, String fileName) async {
    final savedPath = await FlutterFileDialog.saveFile(
      params: SaveFileDialogParams(
        data: bytes,
        fileName: fileName,
        mimeTypesFilter: const ['application/json'],
      ),
    );
    return savedPath != null && savedPath.isNotEmpty;
  }

  Future<bool> _shareBackup(
    Uint8List bytes,
    String fileName,
    AppLocalizations l10n,
  ) async {
    final tempFile = File('${Directory.systemTemp.path}/$fileName');
    await tempFile.writeAsBytes(bytes, flush: true);

    try {
      final result = await Share.shareXFiles(
        [XFile(tempFile.path, mimeType: 'application/json', name: fileName)],
        text: l10n.settingsBackupShareSubtitle,
      );
      return result.status == ShareResultStatus.success;
    } finally {
      if (await tempFile.exists()) {
        await tempFile.delete();
      }
    }
  }

  Future<bool> _saveBackupWithDesktopPicker(
    Uint8List bytes,
    String suggestedName,
  ) async {
    final location = await getSaveLocation(
      suggestedName: suggestedName,
      acceptedTypeGroups: const [
        XTypeGroup(
          label: 'JSON',
          extensions: ['json'],
          mimeTypes: ['application/json'],
        ),
      ],
    );
    if (location == null) return false;

    final backupFile = XFile.fromData(
      bytes,
      mimeType: 'application/json',
      name: suggestedName,
    );
    await backupFile.saveTo(location.path);
    return true;
  }

  Future<void> _restoreBackup(BuildContext context) async {
    final l10n = context.l10n;

    try {
      final jsonBackup = await _pickBackupFileContents();
      if (jsonBackup == null || !context.mounted) return;

      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          icon: Icon(Icons.warning_amber_rounded, color: Colors.orange[700]),
          title: Text(l10n.settingsBackupRestoreConfirmTitle),
          content: Text(l10n.settingsBackupRestoreConfirmBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(l10n.actionCancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(l10n.settingsBackupRestoreConfirmAction),
            ),
          ],
        ),
      );

      if (confirmed != true || !context.mounted) return;

      await AppServices().restoreUserDataBackup(jsonBackup);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.backupRestoredSuccessfully)),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.settingsBackupRestoreError)),
        );
      }
    }
  }

  Future<String?> _pickBackupFileContents() async {
    if (_isMobileBackupPlatform) {
      final path = await FlutterFileDialog.pickFile(
        params: const OpenFileDialogParams(
          dialogType: OpenFileDialogType.document,
          fileExtensionsFilter: ['json'],
          mimeTypesFilter: ['application/json'],
          // Helps iOS document picker recognize JSON backups.
          allowedUtiTypes: [
            'public.json',
            'public.text',
            'public.data',
          ],
          copyFileToCacheDir: true,
        ),
      );
      if (path == null || path.isEmpty) return null;
      return File(path).readAsString();
    }

    final file = await openFile(
      acceptedTypeGroups: const [
        XTypeGroup(
          label: 'JSON',
          extensions: ['json'],
          mimeTypes: ['application/json'],
        ),
      ],
    );
    if (file == null) return null;
    return file.readAsString();
  }

  String _buildBackupFileName() {
    final now = DateTime.now().toUtc();
    final y = now.year.toString().padLeft(4, '0');
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    final hh = now.hour.toString().padLeft(2, '0');
    final mm = now.minute.toString().padLeft(2, '0');
    final ss = now.second.toString().padLeft(2, '0');
    return 'iz-show-time-backup-$y$m$d-$hh$mm$ss.json';
  }

  bool get _isMobileBackupPlatform {
    return switch (defaultTargetPlatform) {
      TargetPlatform.android || TargetPlatform.iOS => true,
      _ => false,
    };
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

enum _BackupAction { backup, restore }

enum _BackupExportDestination { saveLocally, share }
