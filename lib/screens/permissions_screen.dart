import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/permissions_provider.dart';
import '../theme/app_tokens.dart';
import '../widgets/status_pill.dart';

class PermissionsScreen extends StatelessWidget {
  static const Color _bgColor = Color(0xFF0B0F0A);
  static const Color _accentColor = Color(0xFFA3B836);
  static const Color _primaryText = Color(0xFFF3F4F5);
  static const Color _secondaryText = Color(0xFFA7B0A9);

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
          backgroundColor: _bgColor,
          body: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const SizedBox(height: 24),
              const Text(
                'Final setup',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: _primaryText,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Grant the required permissions so ChatMuter can protect your quiet hours.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: _secondaryText,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 28),
              _PermissionCard(
                title: 'Notification Access',
                text:
                    'Allow the app to silence WhatsApp during your Quiet Hours.',
                status: provider.hasNotificationAccess ? 'Granted' : 'Not granted',
                statusOk: provider.hasNotificationAccess,
                buttonLabel: 'Grant',
                onTap: provider.openNotificationSettings,
              ),
              const SizedBox(height: AppSpacing.gap12),
              _PermissionCard(
                title: 'Battery Optimization',
                text: 'Keep protection running reliably.',
                status:
                    provider.batteryOptimizationDisabled ? 'Fixed' : 'Not fixed',
                statusOk: provider.batteryOptimizationDisabled,
                buttonLabel: 'Fix',
                onTap: provider.openBatterySettings,
              ),
            ],
          ),
          bottomNavigationBar: SafeArea(
            minimum: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: provider.hasNotificationAccess ? onFinish : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accentColor,
                  disabledBackgroundColor: _accentColor.withOpacity(0.35),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
                child: const Text(
                  'Activate Protection',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: _bgColor,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PermissionCard extends StatelessWidget {
  static const Color _bgColor = Color(0xFF0B0F0A);
  static const Color _accentColor = Color(0xFFA3B836);
  static const Color _primaryText = Color(0xFFF3F4F5);
  static const Color _secondaryText = Color(0xFFA7B0A9);

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
    return Container(
      decoration: BoxDecoration(
        color: _bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _secondaryText.withOpacity(0.4),
          width: 1.2,
        ),
      ),
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: AppTypography.sectionTitle.copyWith(
                      color: _primaryText,
                    ),
                  ),
                ),
                StatusPill(label: status, ok: statusOk),
              ],
            ),
            const SizedBox(height: AppSpacing.gap8),
            Text(
              text,
              style: AppTypography.secondaryBody.copyWith(
                color: _secondaryText,
              ),
            ),
            const SizedBox(height: AppSpacing.gap12),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: _accentColor, width: 1.4),
                foregroundColor: _accentColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: onTap,
              child: Text(buttonLabel),
            ),
          ],
        ),
      ),
    );
  }
}
