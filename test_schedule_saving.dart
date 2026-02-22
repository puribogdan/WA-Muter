import 'package:flutter/material.dart';
import 'lib/providers/schedule_provider.dart';
import 'lib/core/services/storage_service.dart';

/// Test script to verify schedule saving functionality
/// Run this to test if schedule times persist correctly
Future<void> main() async {
  print('=== Schedule Saving Test ===');
  
  // Test 1: Clear any existing schedule
  print('\n1. Clearing existing schedule...');
  await StorageService.clearSchedule();
  
  // Test 2: Create schedule provider and test partial schedule saving
  print('\n2. Testing partial schedule saving...');
  final provider = ScheduleProvider();
  
  // Set just start time
  print('Setting start time to 09:00...');
  await provider.setStartTime(TimeOfDay(hour: 9, minute: 0));
  print('Start time: ${provider.startTime?.hour}:${provider.startTime?.minute.toString().padLeft(2, '0')}');
  print('Has schedule: ${provider.hasSchedule}');
  
  // Set just end time
  print('\nSetting end time to 17:00...');
  await provider.setEndTime(TimeOfDay(hour: 17, minute: 0));
  print('End time: ${provider.endTime?.hour}:${provider.endTime?.minute.toString().padLeft(2, '0')}');
  print('Has schedule: ${provider.hasSchedule}');
  
  // Test 3: Create new provider to test persistence
  print('\n3. Testing persistence with new provider...');
  final provider2 = ScheduleProvider();
  
  // Small delay to ensure storage is completed
  await Future.delayed(Duration(milliseconds: 100));
  
  print('New provider start time: ${provider2.startTime?.hour}:${provider2.startTime?.minute.toString().padLeft(2, '0')}');
  print('New provider end time: ${provider2.endTime?.hour}:${provider2.endTime?.minute.toString().padLeft(2, '0')}');
  print('New provider has schedule: ${provider2.hasSchedule}');
  
  // Test 4: Test overnight schedule
  print('\n4. Testing overnight schedule...');
  await provider2.clearSchedule();
  await provider2.setStartTime(TimeOfDay(hour: 22, minute: 0));
  await provider2.setEndTime(TimeOfDay(hour: 8, minute: 0));
  
  print('Overnight schedule: ${provider2.schedulePreview}');
  print('Duration: ${provider2.getDurationHours()} hours');
  
  // Test 5: Final persistence test
  print('\n5. Final persistence test...');
  final provider3 = ScheduleProvider();
  await Future.delayed(Duration(milliseconds: 100));
  
  print('Final provider start time: ${provider3.startTime?.hour}:${provider3.startTime?.minute.toString().padLeft(2, '0')}');
  print('Final provider end time: ${provider3.endTime?.hour}:${provider3.endTime?.minute.toString().padLeft(2, '0')}');
  print('Final provider has schedule: ${provider3.hasSchedule}');
  print('Final schedule preview: ${provider3.schedulePreview}');
  
  // Test results
  print('\n=== Test Results ===');
  if (provider3.hasSchedule && 
      provider3.startTime?.hour == 22 && 
      provider3.startTime?.minute == 0 &&
      provider3.endTime?.hour == 8 && 
      provider3.endTime?.minute == 0) {
    print('✅ SUCCESS: Schedule saving and persistence works correctly!');
  } else {
    print('❌ FAILURE: Schedule saving or persistence failed.');
  }
  
  // Cleanup
  print('\n6. Cleaning up...');
  await StorageService.clearSchedule();
  print('Test completed!');
}