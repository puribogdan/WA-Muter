import 'package:flutter/material.dart';
import '../core/services/permission_service.dart';

class PermissionScreen extends StatefulWidget {
  const PermissionScreen({super.key});

  @override
  State<PermissionScreen> createState() => _PermissionScreenState();
}

class _PermissionScreenState extends State<PermissionScreen>
    with WidgetsBindingObserver {
  bool _hasPermission = false;
  bool _isLoading = true;
  String _statusMessage = 'Checking permissions...';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermission();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Check permission when app returns from background (e.g., after opening settings)
    if (state == AppLifecycleState.resumed) {
      _checkPermission();
    }
  }

  Future<void> _checkPermission() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Checking permissions...';
    });

    try {
      final hasPermission = await PermissionService.checkPermission();
      
      if (mounted) {
        setState(() {
          _hasPermission = hasPermission;
          _isLoading = false;
          _statusMessage = hasPermission
              ? 'Notification access granted successfully!'
              : 'Please grant notification access to continue.';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _statusMessage = 'Error checking permissions: $e';
        });
      }
    }
  }

  Future<void> _requestPermission() async {
    setState(() {
      _statusMessage = 'Opening notification access settings...';
    });

    // Open notification listener settings
    await PermissionService.requestPermission();
    
    // Don't check immediately, wait for app to resume from settings
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Permission'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isLoading)
                const CircularProgressIndicator()
              else
                Column(
                  children: [
                    Icon(
                      _hasPermission ? Icons.check_circle : Icons.warning,
                      size: 80,
                      color: _hasPermission ? Colors.green : Colors.orange,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      _hasPermission
                          ? 'Permission Granted ✅'
                          : 'Permission Required ⚠️',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _hasPermission
                          ? 'Notification access has been granted. The app can now monitor WhatsApp notifications.'
                          : 'This app needs notification access to monitor WhatsApp notifications. Please grant both permissions when prompted.',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _statusMessage,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.blue,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 40),
                    if (!_hasPermission)
                      ElevatedButton(
                        onPressed: _requestPermission,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              Theme.of(context).colorScheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 16,
                          ),
                          textStyle: const TextStyle(fontSize: 16),
                        ),
                        child: const Text('Grant Permissions'),
                      ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
