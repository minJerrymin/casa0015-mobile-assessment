class CheckIn {
  const CheckIn({
    required this.pubName,
    required this.matchTitle,
    required this.timestamp,
    required this.mood,
    required this.noiseDb,
    required this.note,
  });

  final String pubName;
  final String matchTitle;
  final DateTime timestamp;
  final String mood;
  final int noiseDb;
  final String note;

  Map<String, dynamic> toJson() => {
        'pubName': pubName,
        'matchTitle': matchTitle,
        'timestamp': timestamp.toIso8601String(),
        'mood': mood,
        'noiseDb': noiseDb,
        'note': note,
      };

  factory CheckIn.fromJson(Map<String, dynamic> json) {
    return CheckIn(
      pubName: json['pubName'] as String? ?? 'Unknown pub',
      matchTitle: json['matchTitle'] as String? ?? 'Unknown match',
      timestamp: DateTime.tryParse(json['timestamp'] as String? ?? '') ?? DateTime.now(),
      mood: json['mood'] as String? ?? 'Good atmosphere',
      noiseDb: json['noiseDb'] as int? ?? 0,
      note: json['note'] as String? ?? 'No note added.',
    );
  }
}
