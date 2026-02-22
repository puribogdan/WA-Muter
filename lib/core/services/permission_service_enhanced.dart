import 'package:flutter_notification_listener/flutter_notification_listener.dart';
import 'dart:developer' as developer;
import 'dart:io';

// Enhanced logging function to ensure visibility
void _enhancedLog(String message, {String level = 'INFO'}) {
  final timestamp = DateTime.now().toIso8601String();
  final logMessage = '[$timestamp] [$level] $message';
  
  // Multiple logging approaches to ensure visibility
  developer.log(logMessage);
  print(logMessage); // Standard print for console
  
  // Log to file as backup
  _logToFile(logMessage);
}

// File logging backup
void _logToFile(String message) {
  try {
    final file = File('/storage/emulated/0/Download/wa_debug_logs.txt');
    file.writeAsStringSync('$message\n', mode: FileMode.append, flush: true);
  } catch (e) {
    // Ignore file write errors
  }
}

class PermissionServiceEnhanced {
  // Check if permission is granted
  static Future<bool> checkPermission() async {
    _enhancedLog('🔍 Checking notification listener permission...');
    
    try {
      // Check if service can start (this requires proper manifest + user permission)
      await NotificationsListener.startService(
        title: 'Permission Check',
        description: 'Testing permission',
      );
      _enhancedLog('✅ Permission check PASSED - Service started successfully', level: 'SUCCESS');
      await NotificationsListener.stopService();
      return true;
    } catch (e) {
      _enhancedLog('❌ Permission check FAILED - Error: $e', level: 'ERROR');
      // Determine specific error type
      if (e.toString().contains('permission')) {
        _enhancedLog('🔧 Issue: Manifest missing required permissions/service declaration', level: 'ERROR');
      } else if (e.toString().contains('bind')) {
        _enhancedLog('🔧 Issue: Service binding failed - check AndroidManifest.xml', level: 'ERROR');
      } else if (e.toString().contains('ClassNotFoundException')) {
        _enhancedLog('🔧 Issue: Wrong service class name in AndroidManifest.xml', level: 'ERROR');
      } else {
        _enhancedLog("🔧 Issue: User hasn't granted notification access in settings", level: 'ERROR');
      }
      return false;
    }
  }

  // Request Android 13+ POST_NOTIFICATIONS permission
  static Future<bool> requestPostNotificationsPermission() async {
    // For Android 13+, the POST_NOTIFICATIONS permission is requested when the service tries to start
    // We'll rely on the system to prompt the user when needed
    _enhancedLog('📱 Android 13+ POST_NOTIFICATIONS will be requested automatically by the system');
    return true;
  }

  // Open settings to grant permission
  static Future<void> requestPermission() async {
    _enhancedLog('🔧 Opening notification access settings...');
    
    try {
      await NotificationsListener.openPermissionSettings();
      _enhancedLog('✅ Notification access settings opened successfully');
    } catch (e) {
      _enhancedLog('❌ Failed to open notification access settings: $e', level: 'ERROR');
      
      // Fallback: Provide manual instructions
      _enhancedLog('📋 MANUAL INSTRUCTIONS:', level: 'ERROR');
      _enhancedLog('1. Go to Android Settings', level: 'ERROR');
      _enhancedLog("2. Find 'Notifications' or 'Apps'", level: 'ERROR');
      _enhancedLog("3. Find 'Special Access' or 'Advanced'", level: 'ERROR');
      _enhancedLog("4. Enable 'Notification Access'", level: 'ERROR');
      _enhancedLog("5. Find and enable this app: 'whatsapp_group_scheduler'", level: 'ERROR');
      
      rethrow;
    }
  }

  // Enhanced permission check with detailed diagnostics
  static Future<Map<String, dynamic>> getDetailedPermissionStatus() async {
    _enhancedLog('🔍 Running detailed permission diagnostic...');
    
    final status = <String, dynamic>{
      'notificationListenerPermission': false,
      'serviceStartTest': false,
      'settingsAccessible': false,
      'error': null,
    };
    
    try {
      // Test 1: Try to start service (this requires proper manifest + user permission)
      await NotificationsListener.startService(
        title: 'Permission Check',
        description: 'Testing permission',
      );
      status['serviceStartTest'] = true;
      _enhancedLog('✅ Service start test: PASSED');
      
      await NotificationsListener.stopService();
      status['notificationListenerPermission'] = true;
      _enhancedLog('✅ Notification listener permission: GRANTED');
      
    } catch (e) {
      status['error'] = e.toString();
      _enhancedLog('❌ Service start test: FAILED - $e', level: 'ERROR');
      
      // Determine specific error type
      if (e.toString().contains('permission')) {
        _enhancedLog('🔧 Issue: Manifest missing required permissions/service declaration', level: 'ERROR');
      } else if (e.toString().contains('bind')) {
        _enhancedLog('🔧 Issue: Service binding failed - check AndroidManifest.xml', level: 'ERROR');
      } else if (e.toString().contains('ClassNotFoundException')) {
        _enhancedLog('🔧 Issue: Wrong service class name in AndroidManifest.xml', level: 'ERROR');
      } else {
        _enhancedLog("🔧 Issue: User hasn't granted notification access in settings", level: 'ERROR');
      }
    }
    
    try {
      // Test 2: Check if settings can be opened
      await NotificationsListener.openPermissionSettings();
      status['settingsAccessible'] = true;
      _enhancedLog('✅ Settings accessible: YES');
    } catch (e) {
      _enhancedLog('❌ Settings accessible: NO - $e', level: 'WARNING');
    }
    
    return status;
  }

  // Get user-friendly permission instructions
  static String getPermissionInstructions() {
    return '''
🔐 NOTIFICATION ACCESS PERMISSION REQUIRED

To use WhatsApp Scheduler, you MUST grant notification access:

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

🔄 After granting permission:
• Return to the app
• The service should start working
• You should see notification blocking active

📍 Where to Find:
• Settings → Apps → whatsapp_group_scheduler → Permissions → Notification Access
• OR Settings → Notifications → Special Access → Notification Access → whatsapp_group_scheduler

❌ Common Issues:
• App not appearing in notification access list
• Permission granted but service still not working
• Need to restart app after granting permission
''';
  }

  // Quick permission test with user feedback
  static Future<bool> testPermissionWithFeedback() async {
    _enhancedLog('🧪 Testing permission with detailed feedback...');
    
    try {
      // Step 1: Test service start
      _enhancedLog('📡 Step 1: Testing service startup...');
      await NotificationsListener.startService(
        title: 'Permission Test',
        description: 'Testing if notification access works',
      );
      
      _enhancedLog('✅ Step 1 PASSED: Service started successfully');
      await NotificationsListener.stopService();
      
      // Step 2: Test settings access
      _enhancedLog('⚙️ Step 2: Testing settings access...');
      await NotificationsListener.openPermissionSettings();
      _enhancedLog('✅ Step 2 PASSED: Settings accessible');
      
      _enhancedLog('🎉 ALL TESTS PASSED: Permission fully functional!');
      return true;
      
    } catch (e) {
      _enhancedLog('❌ Permission test FAILED: $e', level: 'ERROR');
      
      // Provide specific guidance based on error
      if (e.toString().contains('permission') || e.toString().contains('access')) {
        _enhancedLog('🔧 SOLUTION: Grant notification access in Android Settings', level: 'ERROR');
        _enhancedLog(getPermissionInstructions(), level: 'ERROR');
      } else if (e.toString().contains('bind')) {
        _enhancedLog('🔧 SOLUTION: Check AndroidManifest.xml service declaration', level: 'ERROR');
      } else {
        _enhancedLog('🔧 SOLUTION: Check logs and permissions', level: 'ERROR');
      }
      
      return false;
    }
  }
}