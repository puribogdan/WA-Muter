import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/models/app_settings.dart';
import 'core/models/mute_schedule.dart';
import 'core/services/app_settings_service.dart';
import 'core/services/detected_groups_service.dart';
import 'core/services/mute_log_service.dart';
import 'core/services/schedule_service.dart';
import 'providers/app_settings_provider.dart';
import 'providers/detected_groups_provider.dart';
import 'providers/mute_log_provider.dart';
import 'providers/permissions_provider.dart';
import 'providers/schedules_provider.dart';
import 'screens/app_shell_screen.dart';
import 'screens/permissions_screen.dart';
import 'screens/welcome_onboarding_screen.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const AppRoot());
}

class AppRoot extends StatelessWidget {
  const AppRoot({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => PermissionsProvider()..initialize(),
        ),
        ChangeNotifierProvider(
          create: (_) => SchedulesProvider(ScheduleService())..load(),
        ),
        ChangeNotifierProvider(
          create: (_) => DetectedGroupsProvider(DetectedGroupsService())..load(),
        ),
        ChangeNotifierProvider(
          create: (_) => AppSettingsProvider(AppSettingsService())..load(),
        ),
        ChangeNotifierProvider(
          create: (_) => MuteLogProvider(MuteLogService()),
        ),
      ],
      child: Consumer<AppSettingsProvider>(
        builder: (context, appSettings, _) {
          final pref = appSettings.settings.themePreference;
          final themeMode = switch (pref) {
            AppThemePreference.light => ThemeMode.light,
            AppThemePreference.dark => ThemeMode.dark,
            AppThemePreference.system => ThemeMode.system,
          };

          return MaterialApp(
            title: 'ChatMuter',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            themeMode: themeMode,
            home: const AppBootstrapScreen(),
          );
        },
      ),
    );
  }
}

class AppBootstrapScreen extends StatelessWidget {
  const AppBootstrapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<PermissionsProvider>(
      builder: (context, permissions, _) {
        if (permissions.isLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (!permissions.hasNotificationAccess) {
          return const PermissionGateFlow();
        }
        return const AppShellScreen();
      },
    );
  }
}

class PermissionGateFlow extends StatefulWidget {
  const PermissionGateFlow({super.key});

  @override
  State<PermissionGateFlow> createState() => _PermissionGateFlowState();
}

class _PermissionGateFlowState extends State<PermissionGateFlow> {
  _PermissionGateStep _step = _PermissionGateStep.onboarding;
  _OffHoursPreset _preset = _OffHoursPreset.sixPmToEightAm;
  TimeOfDay? _customStart;
  TimeOfDay? _customEnd;

  @override
  Widget build(BuildContext context) {
    switch (_step) {
      case _PermissionGateStep.onboarding:
        return WelcomeOnboardingScreen(
          onContinue: () => setState(() => _step = _PermissionGateStep.preset),
        );
      case _PermissionGateStep.preset:
        return _OffHoursPresetScreen(
          onContinue: (preset, customStart, customEnd) {
            setState(() {
              _preset = preset;
              _customStart = customStart;
              _customEnd = customEnd;
              _step = _PermissionGateStep.permissions;
            });
          },
        );
      case _PermissionGateStep.permissions:
        return PermissionsScreen(
          onFinish: _handleProtectionActivated,
        );
    }
  }

  Future<void> _handleProtectionActivated() async {
    await context.read<PermissionsProvider>().refresh();
    if (!mounted) return;
    final permissions = context.read<PermissionsProvider>();
    if (!permissions.hasNotificationAccess) return;
    await _maybeCreateFirstQuietHours();
  }

  Future<void> _maybeCreateFirstQuietHours() async {
    final schedulesProvider = context.read<SchedulesProvider>();
    if (schedulesProvider.schedules.isNotEmpty) return;

    TimeOfDay start;
    TimeOfDay end;
    switch (_preset) {
      case _OffHoursPreset.sixPmToEightAm:
        start = const TimeOfDay(hour: 18, minute: 0);
        end = const TimeOfDay(hour: 8, minute: 0);
        break;
      case _OffHoursPreset.sevenPmToSevenAm:
        start = const TimeOfDay(hour: 19, minute: 0);
        end = const TimeOfDay(hour: 7, minute: 0);
        break;
      case _OffHoursPreset.custom:
        start = _customStart ?? const TimeOfDay(hour: 18, minute: 0);
        end = _customEnd ?? const TimeOfDay(hour: 8, minute: 0);
        break;
    }

    final schedule = MuteSchedule(
      name: 'My Quiet Hours',
      startTime: start,
      endTime: end,
      days: const {1, 2, 3, 4, 5, 6, 7},
      groups: const <String>[],
      enabled: true,
    );
    await schedulesProvider.upsert(schedule);
  }
}

enum _PermissionGateStep { onboarding, preset, permissions }

enum _OffHoursPreset { sixPmToEightAm, sevenPmToSevenAm, custom }

class _OffHoursPresetScreen extends StatefulWidget {
  final void Function(
    _OffHoursPreset preset,
    TimeOfDay? customStart,
    TimeOfDay? customEnd,
  )
  onContinue;

  const _OffHoursPresetScreen({
    required this.onContinue,
  });

  @override
  State<_OffHoursPresetScreen> createState() => _OffHoursPresetScreenState();
}

class _OffHoursPresetScreenState extends State<_OffHoursPresetScreen> {
  static const Color _bgColor = Color(0xFF0B0F0A);
  static const Color _accentColor = Color(0xFFA3B836);
  static const Color _primaryText = Color(0xFFF3F4F5);
  static const Color _secondaryText = Color(0xFFA7B0A9);

  _OffHoursPreset _selectedPreset = _OffHoursPreset.sixPmToEightAm;
  TimeOfDay? _customStart;
  TimeOfDay? _customEnd;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              Text(
                'Pick your quiet hours',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: _primaryText,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Choose the schedule ChatMuter should use by default.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: _secondaryText,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 28),
              _PresetChoiceTile(
                title: '6PM-8AM',
                value: _OffHoursPreset.sixPmToEightAm,
                groupValue: _selectedPreset,
                onChanged: _setPreset,
              ),
              const SizedBox(height: 12),
              _PresetChoiceTile(
                title: '7PM-7AM',
                value: _OffHoursPreset.sevenPmToSevenAm,
                groupValue: _selectedPreset,
                onChanged: _setPreset,
              ),
              const SizedBox(height: 12),
              _PresetChoiceTile(
                title: 'Custom',
                value: _OffHoursPreset.custom,
                groupValue: _selectedPreset,
                onChanged: _setPreset,
              ),
              if (_selectedPreset == _OffHoursPreset.custom) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: _accentColor, width: 1.4),
                          foregroundColor: _accentColor,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: () => _pickCustomTime(isStart: true),
                        child: Text(
                          _customStart == null ? 'Start' : _formatTime(_customStart!),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: _accentColor, width: 1.4),
                          foregroundColor: _accentColor,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: () => _pickCustomTime(isStart: false),
                        child: Text(
                          _customEnd == null ? 'End' : _formatTime(_customEnd!),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              const Spacer(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: SizedBox(
          height: 56,
          child: ElevatedButton(
            onPressed: _continue,
            style: ElevatedButton.styleFrom(
              backgroundColor: _accentColor,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
            ),
            child: const Text(
              'Continue',
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
  }

  void _setPreset(_OffHoursPreset? value) {
    if (value == null) return;
    setState(() => _selectedPreset = value);
  }

  Future<void> _pickCustomTime({required bool isStart}) async {
    final initial = isStart
        ? (_customStart ?? const TimeOfDay(hour: 18, minute: 0))
        : (_customEnd ?? const TimeOfDay(hour: 8, minute: 0));
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _customStart = picked;
      } else {
        _customEnd = picked;
      }
    });
  }

  String _formatTime(TimeOfDay time) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  void _continue() {
    if (_selectedPreset == _OffHoursPreset.custom &&
        (_customStart == null || _customEnd == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select custom start and end times.')),
      );
      return;
    }

    widget.onContinue(_selectedPreset, _customStart, _customEnd);
  }
}

class _PresetChoiceTile extends StatelessWidget {
  static const Color _bgColor = Color(0xFF0B0F0A);
  static const Color _accentColor = Color(0xFFA3B836);
  static const Color _primaryText = Color(0xFFF3F4F5);
  static const Color _secondaryText = Color(0xFFA7B0A9);

  final String title;
  final _OffHoursPreset value;
  final _OffHoursPreset groupValue;
  final ValueChanged<_OffHoursPreset?> onChanged;

  const _PresetChoiceTile({
    required this.title,
    required this.value,
    required this.groupValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final selected = value == groupValue;
    return Container(
      decoration: BoxDecoration(
        color: _bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: selected ? _accentColor : _secondaryText.withOpacity(0.4),
          width: selected ? 2 : 1.2,
        ),
      ),
      child: RadioListTile<_OffHoursPreset>(
        activeColor: _accentColor,
        title: Text(
          title,
          style: const TextStyle(
            color: _primaryText,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        value: value,
        groupValue: groupValue,
        onChanged: onChanged,
      ),
    );
  }
}
