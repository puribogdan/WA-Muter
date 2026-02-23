import 'dart:async';
import 'package:flutter/foundation.dart';
import '../core/models/mute_log_entry.dart';
import '../core/services/mute_log_service.dart';
import '../core/services/native_bridge.dart';

class MuteLogProvider extends ChangeNotifier {
  final MuteLogService _service;
  StreamSubscription<Map<String, dynamic>>? _eventsSub;
  Timer? _timer;
  bool _refreshInProgress = false;
  static const Duration _refreshInterval = Duration(minutes: 3);

  MuteLogProvider(this._service) {
    loadToday(initial: true);
    _eventsSub = NativeBridge.muteLogEvents().listen(
      (_) => loadToday(),
      onError: (_) {
        // Keep provider resilient if native stream disconnects.
      },
    );
    // Lightweight fallback in case event stream is disconnected.
    _timer = Timer.periodic(_refreshInterval, (_) {
      loadToday();
    });
  }

  bool _isLoading = true;
  List<MuteLogEntry> _todayEntries = const [];

  bool get isLoading => _isLoading;
  List<MuteLogEntry> get todayEntries => _todayEntries;

  Future<void> clearToday() async {
    await _service.clearToday();
    await loadToday();
  }

  Future<void> loadToday({bool initial = false}) async {
    if (_refreshInProgress && !initial) return;
    _refreshInProgress = true;

    if (initial) {
      _isLoading = true;
      notifyListeners();
    }

    try {
      final latest = await _service.getToday();
      final changed = _didEntriesChange(_todayEntries, latest);
      _todayEntries = latest;

      if (initial) {
        _isLoading = false;
        notifyListeners();
        return;
      }
      if (changed) {
        notifyListeners();
      }
    } finally {
      _refreshInProgress = false;
    }
  }

  bool _didEntriesChange(List<MuteLogEntry> a, List<MuteLogEntry> b) {
    if (a.length != b.length) return true;
    for (var i = 0; i < a.length; i++) {
      if (a[i].timestamp != b[i].timestamp ||
          a[i].groupName != b[i].groupName ||
          a[i].status != b[i].status ||
          a[i].messageText != b[i].messageText) {
        return true;
      }
    }
    return false;
  }

  @override
  void dispose() {
    _eventsSub?.cancel();
    _timer?.cancel();
    super.dispose();
  }
}
