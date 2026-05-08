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
    required this.broadcastingFixtureIds,
    required this.broadcastConfidence,
    required this.latitude,
    required this.longitude,
    required this.description,
    this.sportsEvidenceScore = 0,
    this.sportsEvidenceReasons = const [],
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
  final List<String> broadcastingFixtureIds;
  final int broadcastConfidence;
  final double latitude;
  final double longitude;
  final String description;
  final int sportsEvidenceScore;
  final List<String> sportsEvidenceReasons;

  String get _joinedReasons => sportsEvidenceReasons.join(' ').toLowerCase();

  bool get hasExternalSportsEvidence =>
      _joinedReasons.contains('external') ||
      _joinedReasons.contains('official venue') ||
      _joinedReasons.contains('directory') ||
      _joinedReasons.contains('sports tv provider');

  bool get hasOsmSportsEvidence =>
      _joinedReasons.contains('osm television') ||
      _joinedReasons.contains('osm tv') ||
      _joinedReasons.contains('osm live_sport') ||
      _joinedReasons.contains('osm sport=') ||
      _joinedReasons.contains('osm sports') ||
      _joinedReasons.contains('osm screen');

  bool get hasUserConfirmedEvidence =>
      _joinedReasons.contains('user-confirmed') ||
      _joinedReasons.contains('comment confirmed');

  bool get verifiedFootballFriendly =>
      sportsEvidenceScore >= 70 && (hasExternalSportsEvidence || hasOsmSportsEvidence || hasUserConfirmedEvidence);

  bool get likelyFootballFriendly =>
      !verifiedFootballFriendly && sportsEvidenceScore >= 45;

  bool get unverifiedFootballVenue => !verifiedFootballFriendly && !likelyFootballFriendly;

  String get evidenceTierLabel {
    if (verifiedFootballFriendly) return 'Verified football-friendly';
    if (likelyFootballFriendly) return 'Likely football-friendly';
    return 'Nearby pub, unverified';
  }

  String get evidenceTierShortLabel {
    if (verifiedFootballFriendly) return 'Verified';
    if (likelyFootballFriendly) return 'Likely';
    return 'Unverified';
  }

  String get evidenceTierDescription {
    if (verifiedFootballFriendly) {
      return 'This venue has credible external, OSM, or user evidence for screens or live sport.';
    }
    if (likelyFootballFriendly) {
      return 'This venue has some sports-friendly signals, but it has not been externally verified yet.';
    }
    return 'This venue is a nearby pub/bar from map data, but MatchPint has not found reliable football-screening evidence yet.';
  }

  int comfortScore({required bool prefersCalm, required bool soloMode, bool wantsFood = true}) {
    final noiseScore = prefersCalm ? (100 - noiseDb).clamp(0, 100) : noiseDb.clamp(0, 100);
    final crowdScore = prefersCalm ? (100 - crowdLevel).clamp(0, 100) : crowdLevel.clamp(0, 100);
    final soloScore = soloMode ? (soloFriendly ? 100 : 45) : 70;
    final foodComponent = wantsFood ? foodScore : 70;
    return ((noiseScore * 0.28) +
            (crowdScore * 0.22) +
            (screenQuality * 0.22) +
            (foodComponent * 0.12) +
            (soloScore * 0.16))
        .round();
  }
}
