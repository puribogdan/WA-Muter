# Permission Service Enhancement

## Current Issue
App not appearing in notification access settings

## Root Cause
The flutter_notification_listener plugin requires explicit notification access permission that must be granted by the user through Android Settings.

## Solution Code Additions

### Enhanced Permission Check
```dart
// Add to lib/core/services/permission_service.dart

static Future<Map<String, dynamic>> getDetailedPermissionStatus() async {
  _enhancedLog("🔍 Running detailed permission diagnostic...");
  
  final status = <String, dynamic>{
    'notificationListenerPermission': false,
    'serviceStartTest': false,
    'settingsAccessible': false,
    'error': null,
  };
  
  try {
    // Test 1: Try to start service (requires permission)
    await NotificationsListener.startService(
      title: "Permission Check",
      description: "Testing permission",
    );
    status['serviceStartTest'] = true;
    _enhancedLog("✅ Service start test: PASSED");
    
    await NotificationsListener.stopService();
    status['notificationListenerPermission'] = true;
    _enhancedLog("✅ Notification listener permission: GRANTED");
    
  } catch (e) {
    status['error'] = e.toString();
    _enhancedLog("❌ Service start test: FAILED - $e", level: 'ERROR');
  }
  
  return status;
}
```

### User-Friendly Instructions
```dart
static String getPermissionInstructions() {
  return '''
🔐 NOTIFICATION ACCESS PERMISSION REQUIRED

📱 Step-by-Step Instructions:
1. Open Android Settings
2. Go to 'Apps' or 'Applications'  
3. Find and tap 'whatsapp_group_scheduler'
4. Tap 'Permissions'
5. Look for 'Notification Access' or 'Special Access'
6. Enable the toggle for 'Notification Access'

🔧 Alternative Path:
1. Android Settings → Notifications → Special Access
2. Enable 'Notification Access'
3. Find and enable 'whatsapp_group_scheduler'

⚠️ IMPORTANT:
• The app MUST appear in the notification access list
• This permission is required for notification monitoring
• Without it, notification silencing will not work
''';
}
```

### Debug Permission Screen
```dart
// Add debug screen to show detailed permission status

class PermissionDebugScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Permission Debug')),
      body: Column(
        children: [
          ElevatedButton(
            onPressed: () async {
              final status = await PermissionService.getDetailedPermissionStatus();
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('Permission Status'),
                  content: Text(status.toString()),
                ),
              );
            },
            child: Text('Check Permission Status'),
          ),
          ElevatedButton(
            onPressed: () async {
              await PermissionService.requestPermission();
            },
            child: Text('Open Permission Settings'),
          ),
          Text(PermissionService.getPermissionInstructions()),
        ],
      ),
    );
  }
}
```

## Testing Steps
1. Add enhanced permission checking
2. Run detailed diagnostic
3. Manually grant notification access
4. Verify service starts successfully
5. Test notification blocking

## Expected Result
After granting notification access:
- App should appear in notification access settings
- Service should start without errors  
