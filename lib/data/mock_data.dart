import '../models/match_fixture.dart';
import '../models/pub_spot.dart';
import '../models/user_preferences.dart';
import 'team_data.dart';

final List<MatchFixture> mockFixtures = [
  MatchFixture(
    id: 'm1',
    homeTeam: 'Arsenal',
    awayTeam: 'Chelsea',
    competition: 'Premier League',
    kickoff: DateTime(2026, 5, 10, 16, 30),
    venue: 'Emirates Stadium',
    importance: 95,
  ),
  MatchFixture(
    id: 'm2',
    homeTeam: 'England Women',
    awayTeam: 'Spain Women',
    competition: 'International Friendly',
    kickoff: DateTime(2026, 5, 11, 19, 45),
    venue: 'Wembley Stadium',
    importance: 90,
  ),
  MatchFixture(
    id: 'm3',
    homeTeam: 'Tottenham',
    awayTeam: 'Liverpool',
    competition: 'Premier League',
    kickoff: DateTime(2026, 5, 12, 20, 0),
    venue: 'Tottenham Hotspur Stadium',
    importance: 88,
  ),
  MatchFixture(
    id: 'm4',
    homeTeam: 'West Ham',
    awayTeam: 'Aston Villa',
    competition: 'Premier League',
    kickoff: DateTime(2026, 5, 13, 17, 30),
    venue: 'London Stadium',
    importance: 78,
  ),
];

final List<PubSpot> mockPubs = [
  PubSpot(
    id: 'p1',
    name: 'The Full Time Arms',
    area: 'Farringdon',
    distanceKm: 0.7,
    vibe: 'Big-match atmosphere',
    noiseDb: 78,
    crowdLevel: 86,
    screenQuality: 94,
    soloFriendly: false,
    foodScore: 75,
    priceLevel: 3,
    features: ['8 screens', 'standing crowd', 'late kitchen', 'chants likely'],
    supportedTeams: ['Arsenal', 'England Women', 'Liverpool'],
    broadcastingFixtureIds: ['m1', 'm2', 'm3'],
    broadcastConfidence: 92,
    latitude: 51.5202,
    longitude: -0.1053,
    description: 'A loud, high-energy football pub for fans who want the match to feel like a mini stadium.',
    sportsEvidenceScore: 96,
    sportsEvidenceReasons: ['8 screens', 'football identity', 'crowd atmosphere'],
  ),
  PubSpot(
    id: 'p2',
    name: 'The Quiet Half',
    area: 'Bloomsbury',
    distanceKm: 1.1,
    vibe: 'Calm screens and tables',
    noiseDb: 55,
    crowdLevel: 42,
    screenQuality: 78,
    soloFriendly: true,
    foodScore: 82,
    priceLevel: 2,
    features: ['bookable tables', 'solo-friendly', 'food focus', 'lower noise'],
    supportedTeams: ['England Women', 'Arsenal', 'Chelsea'],
    broadcastingFixtureIds: ['m2', 'm1'],
    broadcastConfidence: 78,
    latitude: 51.5224,
    longitude: -0.1300,
    description: 'A relaxed match spot for people who want to follow the game without being swallowed by the crowd.',
    sportsEvidenceScore: 82,
    sportsEvidenceReasons: ['screen signal', 'bookable tables', 'football-friendly'],
  ),
  PubSpot(
    id: 'p3',
    name: 'North Stand Social',
    area: 'Islington',
    distanceKm: 2.4,
    vibe: 'Home fans and local regulars',
    noiseDb: 70,
    crowdLevel: 74,
    screenQuality: 86,
    soloFriendly: true,
    foodScore: 69,
    priceLevel: 2,
    features: ['home fans', 'good sightlines', 'community feel', 'safe walk route'],
    supportedTeams: ['Arsenal', 'England Women'],
    broadcastingFixtureIds: ['m1', 'm2'],
    broadcastConfidence: 86,
    latitude: 51.5465,
    longitude: -0.1027,
    description: 'A local pub with a strong football identity and a friendly crowd that still leaves room to breathe.',
    sportsEvidenceScore: 88,
    sportsEvidenceReasons: ['football identity', 'home fans', 'good sightlines'],
  ),
  PubSpot(
    id: 'p4',
    name: 'The Neutral Corner',
    area: 'Shoreditch',
    distanceKm: 1.8,
    vibe: 'Mixed fans and casual viewers',
    noiseDb: 64,
    crowdLevel: 61,
    screenQuality: 81,
    soloFriendly: true,
    foodScore: 88,
    priceLevel: 3,
    features: ['mixed fans', 'craft beer', 'great food', 'good for groups'],
    supportedTeams: ['Chelsea', 'Liverpool', 'Tottenham', 'West Ham'],
    broadcastingFixtureIds: ['m3', 'm4', 'm1'],
    broadcastConfidence: 74,
    latitude: 51.5260,
    longitude: -0.0800,
    description: 'A balanced option for groups with mixed loyalties or newer fans who want atmosphere without hostility.',
    sportsEvidenceScore: 76,
    sportsEvidenceReasons: ['mixed fans', 'screen signal', 'groups'],
  ),
  PubSpot(
    id: 'p5',
    name: 'The Late Kickoff',
    area: 'King’s Cross',
    distanceKm: 1.5,
    vibe: 'Convenient transport hub',
    noiseDb: 68,
    crowdLevel: 69,
    screenQuality: 84,
    soloFriendly: true,
    foodScore: 72,
    priceLevel: 2,
    features: ['near station', 'easy exit', 'walk-ins', 'post-match trains'],
    supportedTeams: ['Arsenal', 'Chelsea', 'Tottenham', 'Liverpool', 'England Women'],
    broadcastingFixtureIds: ['m1', 'm2', 'm3', 'm4'],
    broadcastConfidence: 69,
    latitude: 51.5308,
    longitude: -0.1238,
    description: 'A practical matchday spot for fans who care as much about getting home smoothly as seeing the match.',
    sportsEvidenceScore: 70,
    sportsEvidenceReasons: ['near station', 'walk-ins', 'screen signal'],
  ),
];


MatchFixture fixtureById(String id, {List<MatchFixture>? fixtures}) {
  final source = fixtures ?? mockFixtures;
  return source.firstWhere(
    (fixture) => fixture.id == id,
    orElse: () => source.isNotEmpty ? source.first : mockFixtures.first,
  );
}

bool pubIsShowingFixture(PubSpot pub, MatchFixture fixture) {
  if (pub.broadcastingFixtureIds.contains(fixture.id)) return true;
  final supported = pub.supportedTeams.map((team) => team.toLowerCase()).toSet();
  return supported.any((team) => teamNamesMatch(team, fixture.homeTeam) || teamNamesMatch(team, fixture.awayTeam)) ||
      pub.features.any((feature) => feature.toLowerCase().contains('mixed fans'));
}

int fixtureBroadcastScore(PubSpot pub, MatchFixture fixture) {
  var score = pub.broadcastingFixtureIds.contains(fixture.id) ? pub.broadcastConfidence : 44;
  final supported = pub.supportedTeams.map((team) => team.toLowerCase()).toSet();
  if (supported.any((team) => teamNamesMatch(team, fixture.homeTeam))) score += 10;
  if (supported.any((team) => teamNamesMatch(team, fixture.awayTeam))) score += 8;
  if (pub.features.any((feature) => feature.toLowerCase().contains('mixed fans'))) score += 4;
  return score.clamp(0, 100).toInt();
}

MatchFixture bestFixtureForPub(PubSpot pub, {UserPreferences? preferences, List<MatchFixture>? fixtures}) {
  final source = (fixtures == null || fixtures.isEmpty) ? mockFixtures : fixtures;
  final candidates = pub.broadcastingFixtureIds.isEmpty
      ? [...source]
      : pub.broadcastingFixtureIds.map((id) => fixtureById(id, fixtures: source)).toList();

  candidates.sort((a, b) {
    int score(MatchFixture fixture) {
      var value = fixtureBroadcastScore(pub, fixture) + (fixture.importance / 4).round();
      final team = preferences?.team.toLowerCase();
      if (team != null && (teamNamesMatch(fixture.homeTeam, team) || teamNamesMatch(fixture.awayTeam, team))) {
        value += 22;
      }
      return value;
    }

    final byScore = score(b).compareTo(score(a));
    if (byScore != 0) return byScore;
    return a.kickoff.compareTo(b.kickoff);
  });

  return candidates.isNotEmpty ? candidates.first : source.first;
}


int fixtureHeatScore(MatchFixture fixture) {
  var score = fixture.importance;
  final competition = fixture.competition.toLowerCase();
  if (competition.contains('champions')) score += 18;
  if (competition.contains('europa')) score += 12;
  if (competition.contains('premier')) score += 10;
  const globalDrawTeams = [
    'Arsenal',
    'Chelsea',
    'Liverpool',
    'Manchester City',
    'Manchester United',
    'Tottenham Hotspur',
  ];
  for (final team in globalDrawTeams) {
    if (teamNamesMatch(fixture.homeTeam, team) || teamNamesMatch(fixture.awayTeam, team)) {
      score += 6;
    }
  }
  final hoursUntilKickoff = fixture.kickoff.difference(DateTime.now()).inHours;
  if (hoursUntilKickoff >= 0 && hoursUntilKickoff <= 48) score += 8;
  return score.clamp(0, 160).toInt();
}

MatchFixture bestMatchForHome(UserPreferences preferences, List<MatchFixture> fixtures) {
  final source = fixtures.isEmpty ? mockFixtures : fixtures;
  final now = DateTime.now();
  final upcoming = source.where((fixture) => fixture.kickoff.isAfter(now.subtract(const Duration(hours: 6)))).toList()
    ..sort((a, b) => a.kickoff.compareTo(b.kickoff));
  final candidates = upcoming.isEmpty ? [...source] : upcoming;
  final favouriteWithinTwoDays = candidates.where((fixture) {
    final supportsFavourite = teamNamesMatch(fixture.homeTeam, preferences.team) || teamNamesMatch(fixture.awayTeam, preferences.team);
    final withinTwoDays = fixture.kickoff.difference(now).inHours <= 48;
    return supportsFavourite && withinTwoDays;
  }).toList();
  if (favouriteWithinTwoDays.isNotEmpty) return favouriteWithinTwoDays.first;

  final byHeat = [...candidates]..sort((a, b) {
    final byScore = fixtureHeatScore(b).compareTo(fixtureHeatScore(a));
    if (byScore != 0) return byScore;
    return a.kickoff.compareTo(b.kickoff);
  });
  return byHeat.first;
}
