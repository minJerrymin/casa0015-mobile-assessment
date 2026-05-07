class PubSpot {
  const PubSpot({
    required this.id,
    required this.name,
    required this.area,
    required this.distanceKm,
    required this.vibe,
    required this.noiseDb,
    required this.crowdLevel,
    required this.screenQuality,
    required this.soloFriendly,
    required this.foodScore,
    required this.priceLevel,
    required this.features,
    required this.supportedTeams,
    required this.latitude,
    required this.longitude,
    required this.description,
  });

  final String id;
  final String name;
  final String area;
  final double distanceKm;
  final String vibe;
  final int noiseDb;
  final int crowdLevel;
  final int screenQuality;
  final bool soloFriendly;
  final int foodScore;
  final int priceLevel;
  final List<String> features;
  final List<String> supportedTeams;
  final double latitude;
  final double longitude;
  final String description;

  int comfortScore({required bool prefersCalm, required bool soloMode}) {
    final noiseScore = prefersCalm ? (100 - noiseDb).clamp(0, 100) : noiseDb.clamp(0, 100);
    final crowdScore = prefersCalm ? (100 - crowdLevel).clamp(0, 100) : crowdLevel.clamp(0, 100);
    final soloScore = soloMode ? (soloFriendly ? 100 : 45) : 70;
    return ((noiseScore * 0.28) +
            (crowdScore * 0.22) +
            (screenQuality * 0.22) +
            (foodScore * 0.12) +
            (soloScore * 0.16))
        .round();
  }
}
