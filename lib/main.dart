import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
      child: MaterialApp(
        title: 'WA Muter',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme(),
        darkTheme: AppTheme.darkTheme(),
        themeMode: ThemeMode.system,
        home: const AppBootstrapScreen(),
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
  int _step = 0;

  @override
  Widget build(BuildContext context) {
    if (_step == 0) {
      return WelcomeOnboardingScreen(
        onContinue: () => setState(() => _step = 1),
      );
    }
    return PermissionsScreen(
      onFinish: () async {
        await context.read<PermissionsProvider>().refresh();
      },
    );
  }
}
