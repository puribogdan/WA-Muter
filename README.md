# WhatsApp Group Scheduler

A Flutter Android app that monitors WhatsApp notifications and mutes selected group notifications during configured schedules.

## Features

- Monitor WhatsApp and WhatsApp Business notifications
- Maintain a muted-groups list
- Apply daily mute schedule windows (including overnight ranges)
- Run a foreground listener service with lifecycle recovery

## Requirements

- Android 5.0+ (API 21)
- Flutter SDK 3.x
- Android SDK 34

## Setup

1. Install Flutter and Android SDK
2. Run `flutter pub get`
3. Run `flutter run`

## Required Permissions

- Notification listener access
- Foreground service permissions (Android)
- Boot completed receiver (for restart behavior)

## Project Structure

```text
lib/
|- main.dart
|- core/
|  |- constants.dart
|  |- models/
|  |  |- mute_schedule.dart
|  |- services/
|     |- native_bridge.dart
|     |- notification_service.dart
|     |- permission_service.dart
|     |- storage_service.dart
|     |- time_check_service.dart
|- providers/
|  |- groups_provider.dart
|  |- schedule_provider.dart
|- screens/
   |- add_group_screen.dart
   |- groups_screen.dart
   |- permission_screen.dart
   |- schedule_screen.dart
```

## Dependencies

- `flutter_notification_listener: ^1.3.4`
- `shared_preferences: 2.2.3`
- `provider: 6.1.2`
- `intl: 0.19.0`

## Notes

- Notification access must be granted manually in Android settings.
- Data is stored locally.
- This app is intended for personal/educational use.
