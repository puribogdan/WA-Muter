import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'lib/providers/schedule_provider.dart';
import 'lib/core/services/storage_service.dart';

/// Test to verify dashboard schedule sync functionality
Future<void> main() async {
  print('=== Dashboard Schedule Sync Test ===');
  
  // Clear any existing data
  await StorageService.clearSchedule();
  print('🧹 Cleared existing schedule data');
  
  // Create a ScheduleProvider (simulates the dashboard)
  final scheduleProvider = ScheduleProvider();
  print('📱 Created ScheduleProvider (simulates dashboard)');
  
  // Test 1: Initial state
  print('\n1. Testing initial state...');
  print('   Has schedule: ${scheduleProvider.hasSchedule}');
  print('   Schedule preview: "${scheduleProvider.schedulePreview}"');
  
  // Test 2: Set start time (simulates user setting time in schedule screen)
  print('\n2. Setting start time to 09:00...');
  await scheduleProvider.setStartTime(TimeOfDay(hour: 9, minute: 0));
  print('   Has schedule: ${scheduleProvider.hasSchedule}');
  print('   Start time: ${scheduleProvider.startTime?.hour}:${scheduleProvider.startTime?.minute.toString().padLeft(2, '0')}');
  
  // Test 3: Set end time (completes the schedule)
  print('\n3. Setting end time to 17:00...');
  await scheduleProvider.setEndTime(TimeOfDay(hour: 17, minute: 0));
  print('   Has schedule: ${scheduleProvider.hasSchedule}');
  print('   Schedule preview: "${scheduleProvider.schedulePreview}"');
  print('   Duration: ${scheduleProvider.getDurationHours()} hours');
  print('   Within schedule: ${scheduleProvider.isWithinSchedule()}');
  
  // Test 4: Create new provider (simulates app restart/dashboard refresh)
  print('\n4. Testing persistence with new provider...');
  final scheduleProvider2 = ScheduleProvider();
  
  // Small delay to ensure storage is completed
  await Future.delayed(Duration(milliseconds: 100));
  
  print('   Has schedule: ${scheduleProvider2.hasSchedule}');
  print('   Schedule preview: "${scheduleProvider2.schedulePreview}"');
  print('   Duration: ${scheduleProvider2.getDurationHours()} hours');
  print('   Within schedule: ${scheduleProvider2.isWithinSchedule()}');
  
  // Test 5: Test real-time sync
  print('\n5. Testing real-time updates...');
  print('   Before change - Preview: "${scheduleProvider2.schedulePreview}"');
  
  // Change the schedule
  await scheduleProvider2.setStartTime(TimeOfDay(hour: 22, minute: 0));
  print('   After changing start time - Preview: "${scheduleProvider2.schedulePreview}"');
  
  // Test results
  print('\n=== Test Results ===');
  if (scheduleProvider2.hasSchedule && 
      scheduleProvider2.schedulePreview == "22:00 - 17:00" &&
      scheduleProvider2.getDurationHours() == 19) {
    print('✅ SUCCESS: Dashboard schedule sync works correctly!');
    print('   - Schedule persists across provider instances');
    print('   - Real-time updates work');
    print('   - Provider methods function properly');
  } else {
    print('❌ FAILURE: Dashboard schedule sync has issues.');
    print('   Expected: hasSchedule=true, preview="22:00 - 17:00", duration=19');
    print('   Actual: hasSchedule=${scheduleProvider2.hasSchedule}, preview="${scheduleProvider2.schedulePreview}", duration=${scheduleProvider2.getDurationHours()}');
  }
  
  // Cleanup
  print('\n6. Cleaning up...');
  await StorageService.clearSchedule();
  print('Test completed! 🧹');
}