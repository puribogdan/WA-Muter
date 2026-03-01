import 'dart:convert';

class DetectedGroupRecord {
  final String name;
  final DateTime lastSeenAt;
  final String source;

  const DetectedGroupRecord({
    required this.name,
    required this.lastSeenAt,
    this.source = 'notification',
  });

  DetectedGroupRecord copyWith({
    String? name,
    DateTime? lastSeenAt,
    String? source,
  }) {
    return DetectedGroupRecord(
      name: name ?? this.name,
      lastSeenAt: lastSeenAt ?? this.lastSeenAt,
      source: source ?? this.source,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'lastSeenAt': lastSeenAt.toIso8601String(),
      'source': source,
    };
  }

  factory DetectedGroupRecord.fromJson(Map<String, dynamic> json) {
    final rawName = (json['name'] as String? ?? '').trim();
    final rawSource = (json['source'] as String? ?? '').trim();
    return DetectedGroupRecord(
      name: rawName,
      lastSeenAt: DateTime.tryParse(json['lastSeenAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      source: rawSource.isNotEmpty ? rawSource : 'notification',
    );
  }

  String encode() => jsonEncode(toJson());

  static DetectedGroupRecord decode(String source) {
    return DetectedGroupRecord.fromJson(
      jsonDecode(source) as Map<String, dynamic>,
    );
  }
}
