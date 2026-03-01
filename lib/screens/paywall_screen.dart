import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/services/feature_gate_service.dart';
import '../core/services/monetization_config.dart';
import '../core/services/purchase_service.dart';
import '../providers/app_settings_provider.dart';
import '../theme/app_tokens.dart';

class PaywallScreen extends StatefulWidget {
  final GateViolation reason;

  const PaywallScreen({
    super.key,
    required this.reason,
  });

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  bool _isPurchasing = false;
  bool _isRestoring = false;
  String _priceLabel = 'USD 9.99';

  @override
  void initState() {
    super.initState();
    _loadPrice();
  }

  Future<void> _loadPrice() async {
    final label = await PurchaseService.getLifetimePriceLabel();
    if (!mounted || label == null || label.isEmpty) return;
    setState(() => _priceLabel = label);
  }

  Future<void> _purchase() async {
    if (!MonetizationConfig.isConfigured) {
      _showMessage(
        'Billing is not configured yet. Add REVENUECAT_PUBLIC_SDK_KEY.',
      );
      return;
    }
    setState(() => _isPurchasing = true);
    try {
      final unlocked = await PurchaseService.purchaseLifetimeUnlock();
      if (!mounted) return;
      if (!unlocked) return;
      await context.read<AppSettingsProvider>().syncPremiumFromStore();
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      _showMessage('Purchase failed. Please try again.');
    } finally {
      if (mounted) setState(() => _isPurchasing = false);
    }
  }

  Future<void> _restore() async {
    if (!MonetizationConfig.isConfigured) {
      _showMessage(
        'Billing is not configured yet. Add REVENUECAT_PUBLIC_SDK_KEY.',
      );
      return;
    }
    setState(() => _isRestoring = true);
    try {
      final unlocked = await PurchaseService.restorePurchases();
      if (!mounted) return;
      await context.read<AppSettingsProvider>().syncPremiumFromStore();
      if (!mounted) return;
      if (unlocked) {
        Navigator.of(context).pop(true);
      } else {
        _showMessage('No eligible purchases found.');
      }
    } catch (_) {
      if (!mounted) return;
      _showMessage('Restore failed. Please try again.');
    } finally {
      if (mounted) setState(() => _isRestoring = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final accent = Theme.of(context).colorScheme.primary;
    final isDark = context.isDarkTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Lifetime Protection')),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.pagePadding),
              children: [
                _PaywallHero(
                  accent: accent,
                  isDark: isDark,
                ),
                const SizedBox(height: AppSpacing.gap16),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppRadii.card),
                    gradient: LinearGradient(
                      colors: [
                        accent.withValues(alpha: isDark ? 0.28 : 0.16),
                        accent.withValues(alpha: isDark ? 0.12 : 0.06),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border.all(
                      color: accent.withValues(alpha: isDark ? 0.35 : 0.22),
                    ),
                  ),
                  padding: AppSpacing.cardPadding,
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: isDark ? 0.30 : 0.18),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.workspace_premium_rounded,
                          color: accent,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Stop being interrupted on your own time.',
                              style: AppTypography.sectionTitle.copyWith(
                                color: tokens.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _subtitleForReason(widget.reason),
                              style: AppTypography.secondaryBody.copyWith(
                                color: tokens.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.gap16),
                Container(
                  decoration: AppDecorations.card(context),
                  padding: AppSpacing.cardPadding,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: isDark ? 0.22 : 0.14),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          'LIMITED FREE PLAN',
                          style: AppTypography.micro.copyWith(
                            color: accent,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Premium unlock includes:',
                        style: AppTypography.bodyStrong.copyWith(
                          color: tokens.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Upgrade to create unlimited Quiet Hours and silence multiple chats.',
                        style: AppTypography.secondaryBody.copyWith(
                          color: tokens.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _FeatureRow(
                        text: 'Unlimited Quiet Hours',
                        color: tokens.success,
                      ),
                      const SizedBox(height: 10),
                      _FeatureRow(
                        text: 'Silence multiple chats per schedule',
                        color: tokens.success,
                      ),
                      const SizedBox(height: 10),
                      _FeatureRow(
                        text: 'Full interruption history',
                        color: tokens.success,
                      ),
                      const SizedBox(height: 10),
                      _FeatureRow(
                        text: 'Lifetime access',
                        color: tokens.success,
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'You deserve uninterrupted evenings.',
                        style: AppTypography.secondaryBodyStrong.copyWith(
                          color: tokens.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SafeArea(
            minimum: const EdgeInsets.fromLTRB(
              AppSpacing.pagePadding,
              8,
              AppSpacing.pagePadding,
              AppSpacing.pagePadding,
            ),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: tokens.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: tokens.divider),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Lifetime protection',
                          style: AppTypography.bodyStrong.copyWith(
                            color: tokens.textPrimary,
                          ),
                        ),
                      ),
                      Text(
                        _priceLabel,
                        style: AppTypography.sectionTitle.copyWith(
                          color: accent,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.gap8),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _isPurchasing ? null : _purchase,
                    child: Text(
                      _isPurchasing ? 'Processing...' : 'Unlock Lifetime Protection',
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.gap8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Not now'),
                  ),
                ),
                const SizedBox(height: AppSpacing.gap8),
                TextButton(
                  onPressed: _isRestoring ? null : _restore,
                  child: Text(_isRestoring ? 'Restoring...' : 'Restore purchases'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _subtitleForReason(GateViolation reason) {
    switch (reason) {
      case GateViolation.scheduleLimit:
        return 'Free plan allows only 1 Quiet Hours setup. Upgrade to add more.';
      case GateViolation.chatLimit:
        return 'Free plan allows only 1 chat per Quiet Hours setup. Upgrade to add more.';
      case GateViolation.none:
        return 'Upgrade for complete personal-time protection.';
    }
  }
}

class _PaywallHero extends StatelessWidget {
  final Color accent;
  final bool isDark;

  const _PaywallHero({
    required this.accent,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return Container(
      height: 180,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accent.withValues(alpha: isDark ? 0.34 : 0.20),
            accent.withValues(alpha: isDark ? 0.20 : 0.10),
          ],
        ),
        border: Border.all(
          color: accent.withValues(alpha: isDark ? 0.40 : 0.24),
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -16,
            top: -14,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: isDark ? 0.10 : 0.22),
              ),
            ),
          ),
          Positioned(
            left: -20,
            bottom: -30,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: isDark ? 0.08 : 0.16),
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: isDark ? 0.16 : 0.30),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.workspace_premium_rounded,
                    size: 34,
                    color: accent,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Protection that runs when you are off',
                  style: AppTypography.sectionTitle.copyWith(
                    color: tokens.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Set stronger boundaries with fewer interruptions.',
                  style: AppTypography.secondaryBody.copyWith(
                    color: tokens.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final String text;
  final Color color;

  const _FeatureRow({
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Row(
      children: [
        Icon(Icons.check_circle, size: 18, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: AppTypography.body.copyWith(color: tokens.textPrimary),
          ),
        ),
      ],
    );
  }
}
