import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'preferences_providers.dart';

class PreferencesScreen extends StatefulWidget {
  const PreferencesScreen({super.key});

  @override
  State<PreferencesScreen> createState() => _PreferencesScreenState();
}

class _PreferencesScreenState extends State<PreferencesScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
        title: Text('Preferences', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _PreferencesTile(
            icon: Icons.language_rounded,
            title: 'Language Selection',
            subtitle: 'Choose vendor app language preference.',
            onTap: () => context.push('/preferences/language'),
          ),
          _PreferencesTile(
            icon: Icons.dark_mode_rounded,
            title: 'Dark Mode',
            subtitle: 'Theme mode and contrast options.',
            onTap: () => context.push('/preferences/theme'),
          ),
          _PreferencesTile(
            icon: Icons.tune_rounded,
            title: 'App Settings',
            subtitle: 'Card density and notification preferences.',
            onTap: () => context.push('/preferences/app'),
          ),
        ],
      ),
    );
  }
}

class LanguageSelectionScreen extends ConsumerStatefulWidget {
  const LanguageSelectionScreen({super.key});

  @override
  ConsumerState<LanguageSelectionScreen> createState() => _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState extends ConsumerState<LanguageSelectionScreen> {
  String _language = 'English';
  bool _saving = false;

  Future<void> _saveLanguage() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final data = await ref.read(preferencesServiceProvider).updateLanguage(_language);
      final nextLanguage = (data['current'] ?? _language).toString();
      if (mounted) {
        setState(() => _language = nextLanguage);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Language preference saved.')),
        );
      }
      ref.invalidate(preferencesLanguageProvider);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save language: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final languageAsync = ref.watch(preferencesLanguageProvider);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
        title: Text('Language Selection', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          languageAsync.when(
            data: (data) {
              final current = (data['current'] ?? _language).toString();
              final options = (data['options'] as List?)?.cast<dynamic>() ?? const ['English'];
              if (_language != current) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) setState(() => _language = current);
                });
              }
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.language_rounded),
                  title: const Text('Select Language'),
                  subtitle: const Text('Used for labels and operational prompts.'),
                  trailing: DropdownButton<String>(
                    value: _language,
                    underline: const SizedBox.shrink(),
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => _language = value);
                    },
                    items: options
                        .map((e) => DropdownMenuItem(value: e.toString(), child: Text(e.toString())))
                        .toList(),
                  ),
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Failed to load language settings: $e'),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _saving ? null : _saveLanguage,
            icon: _saving
                ? const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save_rounded),
            label: Text(_saving ? 'Saving...' : 'Save Language'),
          ),
        ],
      ),
    );
  }
}

class ThemeSettingsScreen extends ConsumerStatefulWidget {
  const ThemeSettingsScreen({super.key});

  @override
  ConsumerState<ThemeSettingsScreen> createState() => _ThemeSettingsScreenState();
}

class _ThemeSettingsScreenState extends ConsumerState<ThemeSettingsScreen> {
  bool _darkMode = false;
  bool _highContrast = false;
  bool _saving = false;

  Future<void> _saveTheme() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final data = await ref.read(preferencesServiceProvider).updateTheme(
            darkMode: _darkMode,
            highContrast: _highContrast,
          );
      if (mounted) {
        setState(() {
          _darkMode = data['dark_mode'] == true;
          _highContrast = data['high_contrast'] == true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Theme preferences saved.')),
        );
      }
      ref.invalidate(preferencesThemeProvider);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save theme settings: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeAsync = ref.watch(preferencesThemeProvider);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
        title: Text('Dark Mode', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          themeAsync.when(
            data: (data) {
              final backendValue = data['dark_mode'] == true;
              final backendContrast = data['high_contrast'] == true;
              if (_darkMode != backendValue || _highContrast != backendContrast) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    setState(() {
                      _darkMode = backendValue;
                      _highContrast = backendContrast;
                    });
                  }
                });
              }
              return Column(
                children: [
                  Card(
                    child: SwitchListTile(
                      value: _darkMode,
                      onChanged: (value) => setState(() => _darkMode = value),
                      title: const Text('Enable dark mode'),
                      subtitle: const Text('Use a dark palette in the app interface.'),
                      secondary: const Icon(Icons.dark_mode_rounded),
                    ),
                  ),
                  Card(
                    child: SwitchListTile(
                      value: _highContrast,
                      onChanged: (value) => setState(() => _highContrast = value),
                      title: const Text('High contrast mode'),
                      subtitle: const Text('Increase contrast for readability.'),
                      secondary: const Icon(Icons.contrast_rounded),
                    ),
                  ),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Failed to load theme settings: $e'),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _saving ? null : _saveTheme,
            icon: _saving
                ? const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save_rounded),
            label: Text(_saving ? 'Saving...' : 'Save Theme Settings'),
          ),
        ],
      ),
    );
  }
}

class AppSettingsScreen extends ConsumerStatefulWidget {
  const AppSettingsScreen({super.key});

  @override
  ConsumerState<AppSettingsScreen> createState() => _AppSettingsScreenState();
}

class _AppSettingsScreenState extends ConsumerState<AppSettingsScreen> {
  bool _compactCards = false;
  bool _silentAlerts = false;
  bool _notificationEnabled = true;
  bool _autoPrintReceipts = false;
  bool _saving = false;

  Future<void> _saveAppSettings() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final data = await ref.read(preferencesServiceProvider).updateAppSettings(
            compactCards: _compactCards,
            silentAlerts: _silentAlerts,
            notificationEnabled: _notificationEnabled,
            autoPrintReceipts: _autoPrintReceipts,
          );

      if (mounted) {
        setState(() {
          _compactCards = data['compact_cards'] == true;
          _silentAlerts = data['silent_alerts'] == true;
          _notificationEnabled = data['notification_enabled'] != false;
          _autoPrintReceipts = data['auto_print_receipts'] == true;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('App settings saved.')),
        );
      }

      ref.invalidate(preferencesAppProvider);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save app settings: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final appAsync = ref.watch(preferencesAppProvider);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
        title: Text('App Settings', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          appAsync.when(
            data: (data) {
              final compact = data['compact_cards'] == true;
              final silent = data['silent_alerts'] == true;
              final notifications = data['notification_enabled'] != false;
              final autoPrint = data['auto_print_receipts'] == true;
              if (_compactCards != compact ||
                  _silentAlerts != silent ||
                  _notificationEnabled != notifications ||
                  _autoPrintReceipts != autoPrint) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    setState(() {
                      _compactCards = compact;
                      _silentAlerts = silent;
                      _notificationEnabled = notifications;
                      _autoPrintReceipts = autoPrint;
                    });
                  }
                });
              }
              return Column(
                children: [
                  Card(
                    child: SwitchListTile(
                      value: _compactCards,
                      onChanged: (value) => setState(() => _compactCards = value),
                      title: const Text('Compact order cards'),
                      subtitle: const Text('Reduce card spacing in dashboard queue.'),
                    ),
                  ),
                  Card(
                    child: SwitchListTile(
                      value: _notificationEnabled,
                      onChanged: (value) => setState(() => _notificationEnabled = value),
                      title: const Text('Notifications enabled'),
                      subtitle: const Text('Receive in-app alerts for important events.'),
                    ),
                  ),
                  Card(
                    child: SwitchListTile(
                      value: _autoPrintReceipts,
                      onChanged: (value) => setState(() => _autoPrintReceipts = value),
                      title: const Text('Auto print receipts'),
                      subtitle: const Text('Print receipts automatically for accepted orders.'),
                    ),
                  ),
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.save_as_rounded),
                      title: FilledButton.icon(
                        onPressed: _saving ? null : _saveAppSettings,
                        icon: _saving
                            ? const SizedBox(
                                height: 16,
                                width: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.save_rounded),
                        label: Text(_saving ? 'Saving...' : 'Save App Settings'),
                      ),
                    ),
                  ),
                  Card(
                    child: SwitchListTile(
                      value: _silentAlerts,
                      onChanged: (value) => setState(() => _silentAlerts = value),
                      title: const Text('Silent alerts'),
                      subtitle: const Text('Only show in-app badges without sound.'),
                    ),
                  ),
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.settings_suggest_rounded),
                      title: const Text('Backend Operational Settings'),
                      subtitle: Text(
                        'Auto-accept: ${data['auto_accept_orders']} | Busy mode: ${data['busy_mode_enabled']} | Prep avg: ${data['preparation_time_avg']}m',
                      ),
                    ),
                  ),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Failed to load app settings: $e'),
          ),
        ],
      ),
    );
  }
}

class _PreferencesTile extends StatelessWidget {
  const _PreferencesTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, color: Colors.teal.shade600),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: onTap,
      ),
    );
  }
}
