import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/permissions_provider.dart';
import '../widgets/status_pill.dart';

class PermissionsScreen extends StatelessWidget {
  final VoidCallback onFinish;

  const PermissionsScreen({
    super.key,
    required this.onFinish,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<PermissionsProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          appBar: AppBar(title: const Text('Setup')),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _PermissionCard(
                title: 'Notification Access',
                text:
                    'Required to detect WhatsApp group notifications and silence them.',
                status: provider.hasNotificationAccess ? 'Granted' : 'Not granted',
                statusOk: provider.hasNotificationAccess,
                buttonLabel: 'Grant',
                onTap: provider.openNotificationSettings,
              ),
              const SizedBox(height: 12),
              _PermissionCard(
                title: 'Battery Optimization',
                text: 'Recommended to keep the service running reliably.',
                status:
                    provider.batteryOptimizationDisabled ? 'Fixed' : 'Not fixed',
                statusOk: provider.batteryOptimizationDisabled,
                buttonLabel: 'Fix',
                onTap: provider.openBatterySettings,
              ),
            ],
          ),
          bottomNavigationBar: SafeArea(
            minimum: const EdgeInsets.all(16),
            child: FilledButton(
              onPressed: provider.hasNotificationAccess ? onFinish : null,
              child: const Text('Finish'),
            ),
          ),
        );
      },
    );
  }
}

class _PermissionCard extends StatelessWidget {
  final String title;
  final String text;
  final String status;
  final bool statusOk;
  final String buttonLabel;
  final Future<void> Function() onTap;

  const _PermissionCard({
    required this.title,
    required this.text,
    required this.status,
    required this.statusOk,
    required this.buttonLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                StatusPill(label: status, ok: statusOk),
              ],
            ),
            const SizedBox(height: 8),
            Text(text),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: onTap,
              child: Text(buttonLabel),
            ),
          ],
        ),
      ),
    );
  }
}
