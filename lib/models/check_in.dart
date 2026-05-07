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
}
