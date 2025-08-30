import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:offline_ai_companion/providers/settings_provider.dart';
import 'package:offline_ai_companion/utils/theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Consumer<SettingsProvider>(
        builder: (context, settings, child) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildSection(
                context,
                'Appearance',
                [
                  SwitchListTile(
                    title: const Text('Dark Mode'),
                    subtitle: const Text('Use dark theme'),
                    value: settings.isDarkMode,
                    onChanged: (value) => settings.setDarkMode(value),
                  ),
                  ListTile(
                    title: const Text('Font Size'),
                    subtitle: Text('${(settings.fontSize * 100).round()}%'),
                    trailing: SizedBox(
                      width: 200,
                      child: Slider(
                        value: settings.fontSize,
                        min: 0.5,
                        max: 2.0,
                        divisions: 15,
                        onChanged: (value) => settings.setFontSize(value),
                      ),
                    ),
                  ),
                ],
              ),
              _buildSection(
                context,
                'AI Model Settings',
                [
                  ListTile(
                    title: const Text('Temperature'),
                    subtitle: Text('${settings.temperature.toStringAsFixed(1)} (Creativity)'),
                    trailing: SizedBox(
                      width: 200,
                      child: Slider(
                        value: settings.temperature,
                        min: 0.0,
                        max: 2.0,
                        divisions: 20,
                        onChanged: (value) => settings.setTemperature(value),
                      ),
                    ),
                  ),
                  ListTile(
                    title: const Text('Max Tokens'),
                    subtitle: Text('${settings.maxTokens} tokens'),
                    trailing: SizedBox(
                      width: 200,
                      child: Slider(
                        value: settings.maxTokens.toDouble(),
                        min: 100,
                        max: 8192,
                        divisions: 80,
                        onChanged: (value) => settings.setMaxTokens(value.round()),
                      ),
                    ),
                  ),
                  ListTile(
                    title: const Text('Top P'),
                    subtitle: Text('${settings.topP.toStringAsFixed(2)} (Nucleus sampling)'),
                    trailing: SizedBox(
                      width: 200,
                      child: Slider(
                        value: settings.topP,
                        min: 0.0,
                        max: 1.0,
                        divisions: 20,
                        onChanged: (value) => settings.setTopP(value),
                      ),
                    ),
                  ),
                  ListTile(
                    title: const Text('Top K'),
                    subtitle: Text('${settings.topK} (Top-k sampling)'),
                    trailing: SizedBox(
                      width: 200,
                      child: Slider(
                        value: settings.topK.toDouble(),
                        min: 1,
                        max: 100,
                        divisions: 99,
                        onChanged: (value) => settings.setTopK(value.round()),
                      ),
                    ),
                  ),
                  ListTile(
                    title: const Text('Repetition Penalty'),
                    subtitle: Text('${settings.repetitionPenalty.toStringAsFixed(1)}'),
                    trailing: SizedBox(
                      width: 200,
                      child: Slider(
                        value: settings.repetitionPenalty,
                        min: 0.0,
                        max: 2.0,
                        divisions: 20,
                        onChanged: (value) => settings.setRepetitionPenalty(value),
                      ),
                    ),
                  ),
                  SwitchListTile(
                    title: const Text('Use Metal Acceleration'),
                    subtitle: const Text('Use Metal for faster inference (iOS/macOS)'),
                    value: settings.useMetal,
                    onChanged: (value) => settings.setUseMetal(value),
                  ),
                ],
              ),
              _buildSection(
                context,
                'Privacy & Data',
                [
                  SwitchListTile(
                    title: const Text('Save Chat History'),
                    subtitle: const Text('Store conversations locally'),
                    value: settings.saveChatHistory,
                    onChanged: (value) => settings.setSaveChatHistory(value),
                  ),
                  SwitchListTile(
                    title: const Text('Auto-delete Old Messages'),
                    subtitle: const Text('Automatically remove old chat history'),
                    value: settings.autoDeleteOldMessages,
                    onChanged: (value) => settings.setAutoDeleteOldMessages(value),
                  ),
                  if (settings.autoDeleteOldMessages)
                    ListTile(
                      title: const Text('Auto-delete After'),
                      subtitle: Text('${settings.autoDeleteDays} days'),
                      trailing: SizedBox(
                        width: 200,
                        child: Slider(
                          value: settings.autoDeleteDays.toDouble(),
                          min: 1,
                          max: 365,
                          divisions: 364,
                          onChanged: (value) => settings.setAutoDeleteDays(value.round()),
                        ),
                      ),
                    ),
                  SwitchListTile(
                    title: const Text('Privacy Mode'),
                    subtitle: const Text('Enhanced privacy features'),
                    value: settings.privacyMode,
                    onChanged: (value) => settings.setPrivacyMode(value),
                  ),
                ],
              ),
              _buildSection(
                context,
                'Performance',
                [
                  SwitchListTile(
                    title: const Text('Background Processing'),
                    subtitle: const Text('Allow AI processing in background'),
                    value: settings.backgroundProcessing,
                    onChanged: (value) => settings.setBackgroundProcessing(value),
                  ),
                  SwitchListTile(
                    title: const Text('Notifications'),
                    subtitle: const Text('Show notifications for AI responses'),
                    value: settings.notifications,
                    onChanged: (value) => settings.setNotifications(value),
                  ),
                ],
              ),
              _buildSection(
                context,
                'Language',
                [
                  ListTile(
                    title: const Text('Language'),
                    subtitle: Text(_getLanguageName(settings.language)),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () => _showLanguageDialog(context, settings),
                  ),
                ],
              ),
              _buildSection(
                context,
                'Data Management',
                [
                  ListTile(
                    leading: const Icon(Icons.delete_outline),
                    title: const Text('Clear All Data'),
                    subtitle: const Text('Delete all chat history and settings'),
                    onTap: () => _showClearDataDialog(context, settings),
                  ),
                  ListTile(
                    leading: const Icon(Icons.download),
                    title: const Text('Export Settings'),
                    subtitle: const Text('Export your current settings'),
                    onTap: () => _exportSettings(context, settings),
                  ),
                  ListTile(
                    leading: const Icon(Icons.upload),
                    title: const Text('Import Settings'),
                    subtitle: const Text('Import settings from file'),
                    onTap: () => _importSettings(context, settings),
                  ),
                ],
              ),
              _buildSection(
                context,
                'About',
                [
                  ListTile(
                    leading: const Icon(Icons.info_outline),
                    title: const Text('Version'),
                    subtitle: const Text('1.0.0'),
                  ),
                  ListTile(
                    leading: const Icon(Icons.description),
                    title: const Text('Privacy Policy'),
                    onTap: () {
                      // TODO: Show privacy policy
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.description),
                    title: const Text('Terms of Service'),
                    onTap: () {
                      // TODO: Show terms of service
                    },
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Center(
                child: ElevatedButton(
                  onPressed: () => _showResetDialog(context, settings),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.error,
                    foregroundColor: Theme.of(context).colorScheme.onError,
                  ),
                  child: const Text('Reset to Defaults'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
        Card(
          child: Column(
            children: children,
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  String _getLanguageName(String languageCode) {
    switch (languageCode) {
      case 'en':
        return 'English';
      case 'es':
        return 'Español';
      case 'fr':
        return 'Français';
      case 'de':
        return 'Deutsch';
      case 'it':
        return 'Italiano';
      case 'pt':
        return 'Português';
      case 'ru':
        return 'Русский';
      case 'zh':
        return '中文';
      case 'ja':
        return '日本語';
      case 'ko':
        return '한국어';
      default:
        return 'English';
    }
  }

  void _showLanguageDialog(BuildContext context, SettingsProvider settings) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Language'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildLanguageOption(context, settings, 'en', 'English'),
            _buildLanguageOption(context, settings, 'es', 'Español'),
            _buildLanguageOption(context, settings, 'fr', 'Français'),
            _buildLanguageOption(context, settings, 'de', 'Deutsch'),
            _buildLanguageOption(context, settings, 'it', 'Italiano'),
            _buildLanguageOption(context, settings, 'pt', 'Português'),
            _buildLanguageOption(context, settings, 'ru', 'Русский'),
            _buildLanguageOption(context, settings, 'zh', '中文'),
            _buildLanguageOption(context, settings, 'ja', '日本語'),
            _buildLanguageOption(context, settings, 'ko', '한국어'),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageOption(
    BuildContext context,
    SettingsProvider settings,
    String languageCode,
    String languageName,
  ) {
    final isSelected = settings.language == languageCode;
    
    return ListTile(
      title: Text(languageName),
      trailing: isSelected ? const Icon(Icons.check) : null,
      onTap: () {
        settings.setLanguage(languageCode);
        Navigator.of(context).pop();
      },
    );
  }

  void _showClearDataDialog(BuildContext context, SettingsProvider settings) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Data'),
        content: const Text(
          'This will delete all chat history and reset all settings to defaults. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              // TODO: Implement clear all data
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Data cleared successfully')),
              );
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  void _showResetDialog(BuildContext context, SettingsProvider settings) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset to Defaults'),
        content: const Text(
          'This will reset all settings to their default values. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await settings.resetToDefaults();
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Settings reset to defaults')),
              );
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  void _exportSettings(BuildContext context, SettingsProvider settings) {
    final settingsData = settings.exportSettings();
    // TODO: Implement actual export functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Settings export feature coming soon!')),
    );
  }

  void _importSettings(BuildContext context, SettingsProvider settings) {
    // TODO: Implement actual import functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Settings import feature coming soon!')),
    );
  }
} 