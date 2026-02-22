import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import '../core/services/permission_service.dart';

class PermissionsProvider extends ChangeNotifier with WidgetsBindingObserver {
  bool _isLoading = true;
  bool _hasNotificationAccess = false;
  bool _batteryOptimizationDisabled = false;

  bool get isLoading => _isLoading;
  bool get hasNotificationAccess => _hasNotificationAccess;
  bool get batteryOptimizationDisabled => _batteryOptimizationDisabled;

  Future<void> initialize() async {
    WidgetsBinding.instance.addObserver(this);
    await refresh();
  }

  Future<void> refresh() async {
    _isLoading = true;
    notifyListeners();

    _hasNotificationAccess = await PermissionService.hasNotificationAccess();
    _batteryOptimizationDisabled =
        await PermissionService.isBatteryOptimizationDisabled();

    _isLoading = false;
    notifyListeners();
  }

  Future<void> openNotificationSettings() async {
    await PermissionService.openNotificationAccessSettings();
  }

  Future<void> openBatterySettings() async {
    await PermissionService.openBatteryOptimizationSettings();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      refresh();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
