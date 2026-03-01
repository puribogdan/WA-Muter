import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/models/app_settings.dart';
import '../providers/app_settings_provider.dart';
import '../providers/permissions_provider.dart';
import '../theme/app_tokens.dart';
import '../core/services/feature_gate_service.dart';
import 'paywall_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<PermissionsProvider, AppSettingsProvider>(
      builder: (context, permissions, settingsProvider, _) {
        final settings = settingsProvider.settings;

        return Scaffold(
          appBar: AppBar(title: const Text('Settings')),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.pagePadding,
              AppSpacing.gap12,
              AppSpacing.pagePadding,
              AppSpacing.section,
            ),
            children: [
              const _SectionTitle('Premium'),
              _SettingsRow(
                child: ListTile(
                  title: Text(
                    settings.isPremium ? 'Premium active' : 'Upgrade to Premium',
                  ),
                  subtitle: Text(
                    settings.isPremium
                        ? 'Unlimited Quiet Hours and chats unlocked'
                        : 'Free plan: 1 Quiet Hours setup and 1 chat per setup',
                  ),
                  trailing: settings.isPremium
                      ? const Icon(Icons.verified, color: Colors.green)
                      : FilledButton(
                          onPressed: () async {
                            final unlocked = await Navigator.of(context).push<bool>(
                              MaterialPageRoute(
                                builder: (_) => const PaywallScreen(
                                  reason: GateViolation.scheduleLimit,
                                ),
                              ),
                            );
                            if (unlocked == true && context.mounted) {
                              await settingsProvider.load();
                            }
                          },
                          child: const Text('Unlock'),
                        ),
                ),
              ),
              const _SectionTitle('Permissions'),
              _SettingsRow(
                child: ListTile(
                  title: const Text('Notification Access'),
                  subtitle: Text(
                    permissions.hasNotificationAccess ? 'Granted' : 'Not granted',
                  ),
                  trailing: TextButton(
                    onPressed: () {
                      permissions.openNotificationSettings();
                    },
                    child: const Text('Open'),
                  ),
                ),
              ),
              _SettingsRow(
                child: ListTile(
                  title: const Text('Battery Optimization'),
                  subtitle: Text(
                    permissions.batteryOptimizationDisabled ? 'Fixed' : 'Not fixed',
                  ),
                  trailing: TextButton(
                    onPressed: () {
                      permissions.openBatterySettings();
                    },
                    child: const Text('Open'),
                  ),
                ),
              ),
              const _SectionTitle('Behavior'),
              _SettingsRow(
                child: SwitchListTile(
                  title: const Text('Keep muted notification log'),
                  value: settings.keepMutedLog,
                  onChanged: (value) {
                    settingsProvider.setKeepMutedLog(value);
                  },
                ),
              ),
              _SettingsRow(
                child: ListTile(
                  title: const Text('Theme'),
                  subtitle: const Text('System, light, or dark appearance'),
                  trailing: DropdownButtonHideUnderline(
                    child: DropdownButton<AppThemePreference>(
                      value: settings.themePreference,
                      borderRadius: BorderRadius.circular(AppRadii.input),
                      items: const [
                        DropdownMenuItem(
                          value: AppThemePreference.system,
                          child: Text('System'),
                        ),
                        DropdownMenuItem(
                          value: AppThemePreference.light,
                          child: Text('Light'),
                        ),
                        DropdownMenuItem(
                          value: AppThemePreference.dark,
                          child: Text('Dark'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          settingsProvider.setThemePreference(value);
                        }
                      },
                    ),
                  ),
                ),
              ),
              const _SectionTitle('About'),
              _SettingsRow(
                child: ListTile(
                  title: const Text('Privacy Policy'),
                  trailing: OutlinedButton(
                    onPressed: () {},
                    child: const Text('Placeholder'),
                  ),
                ),
              ),
              const _SettingsRow(
                child: ListTile(
                  title: Text('Version'),
                  subtitle: Text('1.0.0+1'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 16, 0, 8),
      child: Text(
        title,
        style: AppTypography.sectionTitle.copyWith(color: context.tokens.primary),
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  final Widget child;

  const _SettingsRow({required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.gap12),
      child: DecoratedBox(
        decoration: AppDecorations.listRow(context),
        child: child,
      ),
    );
  }
}
