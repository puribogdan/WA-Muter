import 'dart:convert';

class MuteLogEntry {
  final DateTime timestamp;
  final String groupName;
  final String status; // Muted / Dismissed

  const MuteLogEntry({
    required this.timestamp,
    required this.groupName,
    required this.status,
  });

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'groupName': groupName,
      'status': status,
    };
  }

  factory MuteLogEntry.fromJson(Map<String, dynamic> json) {
    return MuteLogEntry(
      timestamp: DateTime.parse(json['timestamp'] as String),
      groupName: (json['groupName'] as String?) ?? 'Unknown',
      status: (json['status'] as String?) ?? 'Muted',
    );
  }

  String encode() => jsonEncode(toJson());

  static MuteLogEntry decode(String source) {
    return MuteLogEntry.fromJson(jsonDecode(source) as Map<String, dynamic>);
  }
}
