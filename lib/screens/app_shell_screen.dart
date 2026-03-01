import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/services/feature_gate_service.dart';
import '../core/services/notification_service.dart';
import '../providers/app_settings_provider.dart';
import '../providers/permissions_provider.dart';
import '../providers/schedules_provider.dart';
import '../theme/app_tokens.dart';
import 'activity_screen.dart';
import 'paywall_screen.dart';
import 'schedule_editor_screen.dart';
import 'schedules_dashboard_screen.dart';
import 'settings_screen.dart';

class AppShellScreen extends StatefulWidget {
  const AppShellScreen({super.key});

  @override
  State<AppShellScreen> createState() => _AppShellScreenState();
}

class _AppShellScreenState extends State<AppShellScreen>
    with WidgetsBindingObserver {
  int _currentIndex = 0;
  bool _serviceStartInFlight = false;

  static const _tabs = [
    SchedulesDashboardScreen(),
    ActivityScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ensureNotificationServiceRunning();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _ensureNotificationServiceRunning();
    }
  }

  Future<void> _ensureNotificationServiceRunning() async {
    if (_serviceStartInFlight || !mounted) return;

    final permissions = context.read<PermissionsProvider>();
    if (!permissions.hasNotificationAccess) return;

    _serviceStartInFlight = true;
    try {
      await NotificationService.ensureServiceRunning();
    } catch (_) {
      // Service startup errors are surfaced via in-app diagnostics/logs.
    } finally {
      _serviceStartInFlight = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Scaffold(
      backgroundColor: tokens.background,
      body: Stack(
        children: [
          _tabs[_currentIndex],
          Positioned(
            top: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(top: 8, right: 12),
                child: IconButton(
                  onPressed: _openSettings,
                  icon: const Icon(Icons.settings_outlined, size: 22),
                  visualDensity: VisualDensity.compact,
                  tooltip: 'Settings',
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: Transform.translate(
        offset: const Offset(0, -2),
        child: GestureDetector(
          onTap: _openCreateSchedule,
          behavior: HitTestBehavior.opaque,
          child: SizedBox(
            width: 74,
            height: 74,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _BottomOuterRingPainter(
                      color: context.isDarkTheme
                          ? tokens.background
                          : AppColors.lightChartGrid,
                      strokeWidth: 8,
                      innerCircleDiameter: 58,
                    ),
                  ),
                ),
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.green,
                    boxShadow: AppShadows.floating(context.isDarkTheme),
                  ),
                  child: const Icon(Icons.add, color: Colors.white),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Theme.of(context).navigationBarTheme.backgroundColor,
            borderRadius: BorderRadius.circular(AppRadii.bottomNav),
            boxShadow: AppShadows.floating(context.isDarkTheme),
            border: Border.all(
              color: context.isDarkTheme ? tokens.divider : Colors.transparent,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadii.bottomNav),
            child: SizedBox(
              height: 76,
              child: Row(
                children: [
                  Expanded(
                    child: _NavItem(
                      icon: Icons.schedule,
                      label: 'Home',
                      selected: _currentIndex == 0,
                      onTap: () => setState(() => _currentIndex = 0),
                    ),
                  ),
                  const SizedBox(width: 92),
                  Expanded(
                    child: _NavItem(
                      icon: Icons.history,
                      label: 'Activity',
                      selected: _currentIndex == 1,
                      onTap: () => setState(() => _currentIndex = 1),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openSettings() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const SettingsScreen()));
  }

  Future<void> _openCreateSchedule() async {
    final settings = context.read<AppSettingsProvider>().settings;
    final scheduleCount = context.read<SchedulesProvider>().schedules.length;
    const gate = FeatureGateService();
    final violation = gate.canCreateSchedule(
      isPremium: settings.isPremium,
      existingScheduleCount: scheduleCount,
    );

    if (violation != GateViolation.none) {
      final unlocked = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => PaywallScreen(reason: violation),
        ),
      );
      if (unlocked != true || !mounted) return;
    }

    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const ScheduleEditorScreen()));
  }
}

class _BottomOuterRingPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double innerCircleDiameter;

  const _BottomOuterRingPainter({
    required this.color,
    required this.strokeWidth,
    required this.innerCircleDiameter,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    // Arc is drawn so its inner edge touches the green circle boundary.
    final arcDiameter = innerCircleDiameter + strokeWidth;
    final left = (size.width - arcDiameter) / 2;
    final top = (size.height - arcDiameter) / 2;
    final rect = Rect.fromLTWH(left, top, arcDiameter, arcDiameter);

    // Draw only bottom semicircle.
    canvas.drawArc(rect, 0, 3.141592653589793, false, paint);
  }

  @override
  bool shouldRepaint(covariant _BottomOuterRingPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.innerCircleDiameter != innerCircleDiameter;
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final selectedColor = Theme.of(context).colorScheme.primary;
    final unselectedColor = tokens.textSecondary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: selected ? selectedColor : unselectedColor),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTypography.secondaryBodyStrong.copyWith(
                color: selected ? selectedColor : unselectedColor,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
