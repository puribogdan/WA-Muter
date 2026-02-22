import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_settings_provider.dart';
import '../providers/permissions_provider.dart';

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
            children: [
              const _SectionTitle('Permissions'),
              ListTile(
                title: const Text('Notification Access'),
                subtitle: Text(
                  permissions.hasNotificationAccess ? 'Granted' : 'Not granted',
                ),
                trailing: TextButton(
                  onPressed: permissions.openNotificationSettings,
                  child: const Text('Open'),
                ),
              ),
              ListTile(
                title: const Text('Battery Optimization'),
                subtitle: Text(
                  permissions.batteryOptimizationDisabled ? 'Fixed' : 'Not fixed',
                ),
                trailing: TextButton(
                  onPressed: permissions.openBatterySettings,
                  child: const Text('Open'),
                ),
              ),
              const _SectionTitle('Behavior'),
              SwitchListTile(
                title: const Text('Hide muted notifications instead of silencing'),
                subtitle: const Text('Native hide/dismiss mode is currently the only supported mode'),
                value: settings.hideMutedInsteadOfSilence,
                onChanged: null,
              ),
              SwitchListTile(
                title: const Text('Keep muted notification log'),
                value: settings.keepMutedLog,
                onChanged: settingsProvider.setKeepMutedLog,
              ),
              const _SectionTitle('Upgrade'),
              ListTile(
                title: const Text('Remove ads (one-time)'),
                trailing: OutlinedButton(
                  onPressed: () {},
                  child: const Text('Placeholder'),
                ),
              ),
              const _SectionTitle('About'),
              ListTile(
                title: const Text('Privacy Policy'),
                trailing: OutlinedButton(
                  onPressed: () {},
                  child: const Text('Placeholder'),
                ),
              ),
              const ListTile(
                title: Text('Version'),
                subtitle: Text('1.0.0+1'),
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
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall,
      ),
    );
  }
}
