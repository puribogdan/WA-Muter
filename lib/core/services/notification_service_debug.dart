import 'dart:developer' as developer;
import 'dart:isolate';
import 'dart:ui';
import 'dart:io';

import 'package:flutter_notification_listener/flutter_notification_listener.dart';
import 'storage_service.dart';
import 'time_check_service.dart';

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

// TOP-LEVEL CALLBACK - Must be outside any class for native access
@pragma('vm:entry-point')
void _callback(NotificationEvent evt) {
  _enhancedLog('📱 [BACKGROUND] Received: ${evt.packageName} - ${evt.title}');
  
  final SendPort? send = IsolateNameServer.lookupPortByName('_listener_');
  if (send == null) {
    _enhancedLog("❌ [BACKGROUND] Can't find the sender port", level: 'ERROR');
  } else {
    _enhancedLog('📤 [BACKGROUND] Sending event to UI');
    send.send(evt);
  }
}

class NotificationServiceDebug {
  static const bool _isListening = false;
  static ReceivePort? _port;
  static DateTime? _serviceStartTime;
  static const bool _isForegroundMode = false;
  static const bool _serviceInitialized = false;
  static const bool _uiMonitoringActive = false; // Separate from service status

  // Comprehensive service status check
  static Map<String, dynamic> getServiceStatus() {
    return {
      'isListening': _isListening,
      'uiMonitoringActive': _uiMonitoringActive,
      'isForegroundMode': _isForegroundMode,
      'serviceInitialized': _serviceInitialized,
      'serviceStartTime': _serviceStartTime?.toIso8601String(),
      'uptime': serviceUptime,
      'isServiceRunning': _isListening,
    };
  }

  // Detailed debugging function
  static Future<void> performDiagnosticCheck() async {
    _enhancedLog('🔍 Starting comprehensive diagnostic check...', level: 'DIAGNOSTIC');
    
    try {
      // Check current service state
      _enhancedLog('📊 Service Status: ${getServiceStatus()}', level: 'DIAGNOSTIC');
      
      // Check stored data
      final selectedGroups = await StorageService.getSelectedGroups();
      final schedule = await StorageService.getSchedule();
      
      _enhancedLog('👥 Selected Groups: ${selectedGroups.length} groups', level: 'DIAGNOSTIC');
      _enhancedLog("📅 Schedule: ${schedule != null ? schedule.getFormattedTime() : 'No schedule set'}", level: 'DIAGNOSTIC');
      
      if (schedule != null) {
        final isWithinSchedule = TimeCheckService.isWithinSchedule(schedule.startTime, schedule.endTime);
        _enhancedLog('⏰ Schedule Active: $isWithinSchedule', level: 'DIAGNOSTIC');
      }
      
      // Check notification listener permission
      try {
        await NotificationsListener.startService(
          title: 'Diagnostic Check',
          description: 'Testing permission',
        );
        _enhancedLog('✅ Notification listener permission: GRANTED', level: 'DIAGNOSTIC');
        await NotificationsListener.stopService();
      } catch (e) {
        _enhancedLog('❌ Notification listener permission: DENIED - $e', level: 'DIAGNOSTIC');
      }
      
      // Check isolate communication
      final send = IsolateNameServer.lookupPortByName('_listener_');
      _enhancedLog("📡 Isolate Communication: ${send != null ? 'ACTIVE' : 'INACTIVE'}", level: 'DIAGNOSTIC');
      
      _enhancedLog('🏁 Diagnostic check completed', level: 'DIAGNOSTIC');
    } catch (e) {
      _enhancedLog('❌ Diagnostic check failed: $e', level: 'ERROR');
    }
  }

  // Get service uptime
  static String get serviceUptime {
    if (_serviceStartTime == null) {
      return 'Not running';
    }
    
    final now = DateTime.now();
    final duration = now.difference(_serviceStartTime!);
    
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;
    
    if (hours > 0) {
      return '${hours}h ${minutes}m ${seconds}s';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }
}