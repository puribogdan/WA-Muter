import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/services/notification_service.dart';
import 'core/services/permission_service.dart';
import 'core/services/storage_service.dart';
import 'core/services/time_check_service.dart';
import 'core/models/mute_schedule.dart';
import 'core/constants.dart';
import 'screens/app_shell_screen.dart';
import 'screens/schedule_screen.dart';
import 'screens/permissions_screen.dart';
import 'providers/groups_provider.dart';
import 'providers/schedule_provider.dart';

void main() {
  runApp(const WhatsAppSchedulerApp());
}

class WhatsAppSchedulerApp extends StatelessWidget {
  const WhatsAppSchedulerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => GroupsProvider()),
        ChangeNotifierProvider(create: (_) => ScheduleProvider()),
      ],
      child: MaterialApp(
        title: 'ChatMuter',
        theme: ThemeData(
          primarySwatch: Colors.green,
          useMaterial3: true,
        ),
        home: const MonitoringScreen(),
        routes: {
          '/groups': (context) => const AppShellScreen(),
          '/schedule': (context) => const ScheduleScreen(),
          '/permissions': (context) => PermissionsScreen(onFinish: () {}),
        },
        builder: (context, child) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(
                MediaQuery.of(context).textScaleFactor.clamp(0.8, 1.2)
              ),
            ),
            child: child!,
          );
        },
      ),
    );
  }
}

class MonitoringScreen extends StatefulWidget {
  const MonitoringScreen({super.key});

  @override
  State<MonitoringScreen> createState() => _MonitoringScreenState();
}

class _MonitoringScreenState extends State<MonitoringScreen> {
  bool _isServiceRunning = false;
  String _serviceUptime = 'Not running';
  DateTime? _serviceStartTime;
  List<String> _selectedGroups = [];
  Timer? _statusUpdateTimer;
  bool _isLoading = false;

  // Enhanced logging function
  void _enhancedLog(String message, {String level = 'INFO'}) {
    final timestamp = DateTime.now().toIso8601String();
    final logMessage = '[$timestamp] [$level] [UI] $message';
    developer.log(logMessage);
    print(logMessage);
  }

  @override
  void initState() {
    super.initState();
    _enhancedLog('🏠 MonitoringScreen initialized');
    
    _loadCurrentState();
    _startStatusUpdates();
  }

  @override
  void dispose() {
    _enhancedLog('🏠 MonitoringScreen disposing...');
    _statusUpdateTimer?.cancel();
    super.dispose();
  }

  // Load current app state
  Future<void> _loadCurrentState() async {
    setState(() {
      _isLoading = true;
    });

    try {
      _enhancedLog('📊 Loading current app state...');
      
      final selectedGroups = await StorageService.getSelectedGroups();
      
      setState(() {
        _selectedGroups = selectedGroups;
      });

      _enhancedLog('✅ State loaded: ${selectedGroups.length} groups');
    } catch (e) {
      _enhancedLog('❌ Error loading state: $e', level: 'ERROR');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Start periodic status updates
  void _startStatusUpdates() {
    _statusUpdateTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      _updateServiceStatus();
    });
  }

  // Update service status display
  void _updateServiceStatus() {
    final serviceRunning = NotificationService.isListening;
    final uptime = NotificationService.serviceUptime;
    final startTime = NotificationService.serviceStartTime;

    if (serviceRunning != _isServiceRunning ||
        uptime != _serviceUptime ||
        startTime != _serviceStartTime) {
      
      setState(() {
        _isServiceRunning = serviceRunning;
        _serviceUptime = uptime;
        _serviceStartTime = startTime;
      });

      _enhancedLog('🔄 Service status updated: Running=$serviceRunning, Uptime=$uptime');
    }
  }

  // Toggle foreground service start/stop
  Future<void> _toggleForegroundService() async {
    if (_isServiceRunning) {
      _enhancedLog('🛑 Stopping foreground service...');
      
      try {
        await NotificationService.stopForegroundService();
        _enhancedLog('✅ Foreground service stopped successfully');
        
        // Force immediate status update
        _updateServiceStatus();
      } catch (e) {
        _enhancedLog('❌ Failed to stop foreground service: $e', level: 'ERROR');
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to stop service: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } else {
      _enhancedLog('🚀 Starting foreground service...');
      
      try {
        await NotificationService.startListening();
        _enhancedLog('✅ Foreground service started successfully');
        
        // Force immediate status update
        _updateServiceStatus();
      } catch (e) {
        _enhancedLog('❌ Failed to start foreground service: $e', level: 'ERROR');
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to start service: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ScheduleProvider>(
      builder: (context, scheduleProvider, child) {
        print('[MonitoringScreen] Building with schedule: ${scheduleProvider.hasSchedule}');
        return Scaffold(
          appBar: AppBar(
            title: const Text('ChatMuter'),
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
          ),
          body: RefreshIndicator(
            onRefresh: _loadCurrentState,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Service Status Card
                  _buildServiceStatusCard(),
                  
                  const SizedBox(height: 20),
                  
                  // Groups Status Card
                  _buildGroupsStatusCard(),
                  
                  const SizedBox(height: 20),
                  
                  // Schedule Status Card - NOW USES SCHEDULEPROVIDER
                  _buildScheduleStatusCard(scheduleProvider),
                  
                  const SizedBox(height: 20),
                  
                  // Quick Actions Card
                  _buildQuickActionsCard(),
                  
                  const SizedBox(height: 20),
                  
                  // Debug Information Card
                  _buildDebugInfoCard(scheduleProvider),
                ],
              ),
            ),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: _toggleForegroundService,
            backgroundColor: _isServiceRunning ? Colors.red : Colors.green,
            child: Icon(
              _isServiceRunning ? Icons.stop : Icons.play_arrow,
              color: Colors.white,
            ),
          ),
        );
      },
    );
  }

  // Service Status Card
  Widget _buildServiceStatusCard() {
    return Card(
      elevation: 8,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _isServiceRunning ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                  color: _isServiceRunning ? Colors.green : Colors.red,
                  size: 32,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isServiceRunning ? 'Service Running ✅' : 'Service Stopped ❌',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _isServiceRunning ? Colors.green : Colors.red,
                        ),
                      ),
                      if (_isServiceRunning)
                        Text(
                          'Uptime: $_serviceUptime',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            if (_isServiceRunning) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green[300]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '🔔 Foreground Service Active',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green[800],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '• Runs 24/7 in background\n• Survives app closure\n• Continuous notification blocking',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green[700],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Groups Status Card
  Widget _buildGroupsStatusCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.group,
                  color: _selectedGroups.isNotEmpty ? Colors.blue : Colors.grey,
                ),
                const SizedBox(width: 8),
                Text(
                  'Muted Groups (${_selectedGroups.length})',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_selectedGroups.isEmpty)
              const Text(
                'No groups configured yet. Add groups to start muting.',
                style: TextStyle(color: Colors.grey),
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: _selectedGroups.map((group) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      const Icon(Icons.volume_off, size: 16, color: Colors.red),
                      const SizedBox(width: 8),
                      Expanded(child: Text(group)),
                    ],
                  ),
                )).toList(),
              ),
          ],
        ),
      ),
    );
  }

  // Schedule Status Card - FIXED TO USE SCHEDULEPROVIDER
  Widget _buildScheduleStatusCard(ScheduleProvider scheduleProvider) {
    print('[MonitoringScreen] _buildScheduleStatusCard - hasSchedule: ${scheduleProvider.hasSchedule}');
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  scheduleProvider.hasSchedule ? Icons.schedule : Icons.schedule_outlined,
                  color: scheduleProvider.hasSchedule ? Colors.orange : Colors.grey,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Mute Schedule',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (!scheduleProvider.hasSchedule)
              const Text(
                'No schedule set. Notifications will be blocked only when service is running.',
                style: TextStyle(color: Colors.grey),
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '⏰ ${scheduleProvider.schedulePreview}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: scheduleProvider.isWithinSchedule() ? Colors.green : Colors.orange,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    scheduleProvider.isWithinSchedule() 
                        ? '🟢 Schedule is ACTIVE (muting enabled)'
                        : '🟡 Schedule is INACTIVE (notifications allowed)',
                    style: TextStyle(
                      color: scheduleProvider.isWithinSchedule() ? Colors.green : Colors.orange,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Text(
                      'Duration: ${scheduleProvider.getDurationHours()} hours per day',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue[700],
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  // Quick Actions Card - ADDED REFRESH CALLBACK
  Widget _buildQuickActionsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _toggleForegroundService,
                    icon: Icon(_isServiceRunning ? Icons.stop : Icons.play_arrow),
                    label: Text(_isServiceRunning ? 'Stop Service' : 'Start Service'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isServiceRunning ? Colors.red : Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pushNamed('/groups');
                    },
                    icon: const Icon(Icons.group),
                    label: const Text('Manage Groups'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).pushNamed('/schedule').then((_) {
                    print('[MonitoringScreen] Returning from schedule screen, refreshing...');
                    _loadCurrentState(); // Refresh when returning from schedule screen
                  });
                },
                icon: const Icon(Icons.schedule),
                label: const Text('Set Schedule'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Debug Information Card - UPDATED TO USE SCHEDULEPROVIDER
  Widget _buildDebugInfoCard(ScheduleProvider scheduleProvider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.bug_report, color: Colors.orange),
                SizedBox(width: 8),
                Text(
                  'Debug Information',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Service Mode: ${NotificationService.isForegroundMode ? 'Foreground' : 'Background'}'),
                  Text('Service Start Time: ${_serviceStartTime != null ? _serviceStartTime!.toIso8601String() : 'N/A'}'),
                  Text('UI Monitoring: ${NotificationService.isListening ? 'Active' : 'Inactive'}'),
                  Text('Selected Groups: ${_selectedGroups.length}'),
                  Text('Schedule Active: ${scheduleProvider.isWithinSchedule()}'),
                  Text('Schedule Set: ${scheduleProvider.hasSchedule}'),
                  Text('App State: ${_isLoading ? 'Loading' : 'Ready'}'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
