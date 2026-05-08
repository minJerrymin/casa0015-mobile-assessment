import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;

import '../data/external_sports_venue_data.dart';
import '../data/mock_data.dart';
import '../data/team_data.dart';
import '../models/match_fixture.dart';
import '../models/pub_spot.dart';

class LiveFixtureResult {
  const LiveFixtureResult({
    required this.fixtures,
    required this.live,
    required this.message,
  });

  final List<MatchFixture> fixtures;
  final bool live;
  final String message;
}

class LivePubResult {
  const LivePubResult({
    required this.pubs,
    required this.live,
    required this.message,
  });

  final List<PubSpot> pubs;
  final bool live;
  final String message;
}

class MatchPintLiveDataService {
  static const double defaultLatitude = 51.5202;
  static const double defaultLongitude = -0.1053;
  static const int defaultRadiusMeters = 2800;

  final http.Client _client;

  MatchPintLiveDataService({http.Client? client}) : _client = client ?? http.Client();

  static const String fixtureBackendUrl = String.fromEnvironment(
    'MATCHPINT_FIXTURE_BACKEND_URL',
    defaultValue: '',
  );

  Future<LiveFixtureResult> fetchFootballFixtures() async {
    final endpoint = fixtureBackendUrl.trim();
    if (endpoint.isNotEmpty) {
      try {
        final result = await _fetchFixturesFromMatchPintBackend(Uri.parse(endpoint));
        if (result.fixtures.isNotEmpty) return result;
      } catch (_) {
        // Do not expose developer-style API errors in the customer UI.
        // Fall back to the latest available public/fallback data below.
      }
    }

    final fallback = await _fetchFallbackFootballFixtures();
    return LiveFixtureResult(
      fixtures: fallback.fixtures,
      live: fallback.live,
      message: endpoint.isEmpty
          ? 'Showing latest available fixtures.'
          : 'Showing latest available fixtures.',
    );
  }

  Future<LiveFixtureResult> _fetchFixturesFromMatchPintBackend(Uri uri) async {
    final response = await _client.get(uri).timeout(const Duration(seconds: 6));
    if (response.statusCode != 200) {
      throw Exception('MatchPint backend HTTP ${response.statusCode}');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) throw Exception('Invalid backend payload');
    final rawFixtures = decoded['fixtures'];
    if (rawFixtures is! List) throw Exception('Backend fixtures missing');

    final fixtures = <MatchFixture>[];
    for (final item in rawFixtures) {
      if (item is Map<String, dynamic>) {
        final fixture = _fixtureFromBackendJson(item);
        if (fixture != null) fixtures.add(fixture);
      }
    }

    final filteredFixtures = _nextThreeDayFixtures(fixtures);
    final generatedAt = (decoded['generatedAt'] ?? '').toString();
    final rangeLabel = (decoded['rangeLabel'] ?? 'next 3 days').toString();
    final source = (decoded['source'] ?? 'MatchPint Firebase backend').toString();
    final counts = decoded['competitionCounts'];
    final countMessage = counts is Map<String, dynamic>
        ? counts.entries.map((entry) => '${entry.key}: ${entry.value}').join(' • ')
        : '${filteredFixtures.length} fixtures';

    return LiveFixtureResult(
      fixtures: filteredFixtures,
      live: true,
      message: 'Live fixtures loaded from $source for $rangeLabel. $countMessage${generatedAt.isEmpty ? '' : ' • Updated $generatedAt'}',
    );
  }

  MatchFixture? _fixtureFromBackendJson(Map<String, dynamic> item) {
    final id = (item['id'] ?? '').toString();
    final home = _cleanTeamName((item['homeTeam'] ?? '').toString());
    final away = _cleanTeamName((item['awayTeam'] ?? '').toString());
    final competition = (item['competition'] ?? '').toString();
    final kickoffRaw = (item['kickoff'] ?? '').toString();
    if (id.isEmpty || home.isEmpty || away.isEmpty || competition.isEmpty || kickoffRaw.isEmpty) {
      return null;
    }
    final kickoff = DateTime.tryParse(kickoffRaw)?.toLocal();
    if (kickoff == null) return null;
    final venue = (item['venue'] ?? 'Venue TBC').toString();
    final importanceRaw = item['importance'];
    final importance = importanceRaw is num ? importanceRaw.toInt() : _fixtureImportance(competition, home, away);

    return MatchFixture(
      id: id,
      homeTeam: home,
      awayTeam: away,
      competition: competition,
      kickoff: kickoff,
      venue: venue,
      importance: importance.clamp(0, 100).toInt(),
    );
  }

  List<MatchFixture> _nextThreeDayFixtures(List<MatchFixture> fixtures) {
    final now = DateTime.now();
    final start = now.subtract(const Duration(hours: 2));
    final end = DateTime(now.year, now.month, now.day).add(const Duration(days: 4));
    final filtered = fixtures
        .where((fixture) => fixture.kickoff.isAfter(start) && fixture.kickoff.isBefore(end))
        .toList()
      ..sort((a, b) => a.kickoff.compareTo(b.kickoff));
    return filtered;
  }

  Future<LiveFixtureResult> _fetchFallbackFootballFixtures() async {
    final List<_LeagueSource> leagues = const [
      _LeagueSource(id: '4480', fallbackName: 'UEFA Champions League'),
      _LeagueSource(id: '4481', fallbackName: 'UEFA Europa League'),
    ];

    final List<MatchFixture> fixtures = [];
    final List<String> failures = [];
    final seasons = _seasonCandidates();

    try {
      final eplFixtures = await _fetchFixtureDownloadFixtures(
        Uri.parse('https://fixturedownload.com/feed/json/epl-2025'),
        competition: 'English Premier League',
        idPrefix: 'fd_epl',
      );
      fixtures.addAll(eplFixtures);
      if (eplFixtures.isEmpty) failures.add('Premier League FixtureDownload: no events returned');
    } catch (error) {
      failures.add('Premier League FixtureDownload: ${error.runtimeType}');
      try {
        final events = await _fetchSportsDbEvents(Uri.parse('https://www.thesportsdb.com/api/v1/json/3/eventsnextleague.php?id=4328'));
        for (final raw in events) {
          final fixture = _fixtureFromSportsDbEvent(raw, fallbackCompetition: 'English Premier League');
          if (fixture != null) fixtures.add(fixture);
        }
      } catch (_) {}
    }

    for (final league in leagues) {
      var leagueLoaded = 0;
      try {
        final events = await _fetchSportsDbEvents(Uri.parse('https://www.thesportsdb.com/api/v1/json/3/eventsnextleague.php?id=${league.id}'));
        for (final raw in events) {
          final fixture = _fixtureFromSportsDbEvent(raw, fallbackCompetition: league.fallbackName);
          if (fixture != null) {
            fixtures.add(fixture);
            leagueLoaded++;
          }
        }
      } catch (error) {
        failures.add('${league.fallbackName} next: ${error.runtimeType}');
      }

      for (final season in seasons) {
        try {
          final events = await _fetchSportsDbEvents(Uri.parse('https://www.thesportsdb.com/api/v1/json/3/eventsseason.php?id=${league.id}&s=$season'));
          for (final raw in events) {
            final fixture = _fixtureFromSportsDbEvent(raw, fallbackCompetition: league.fallbackName);
            if (fixture != null) {
              fixtures.add(fixture);
              leagueLoaded++;
            }
          }
        } catch (_) {
          // The free endpoint can be sparse for some leagues/seasons; next-league data above is still useful.
        }
      }

      if (leagueLoaded == 0) failures.add('${league.fallbackName}: no events returned');
    }

    fixtures.sort((a, b) => a.kickoff.compareTo(b.kickoff));
    final deduped = _nextThreeDayFixtures(_dedupeFixtures(fixtures));

    if (deduped.isEmpty) {
      return LiveFixtureResult(
        fixtures: mockFixtures,
        live: false,
        message: 'Showing saved fixtures while the live service reconnects.',
      );
    }

    return LiveFixtureResult(
      fixtures: deduped,
      live: true,
      message: 'Showing latest available fixtures.',
    );
  }

  Future<LivePubResult> fetchNearbyPubs({
    required double latitude,
    required double longitude,
    required List<MatchFixture> fixtures,
    int radiusMeters = defaultRadiusMeters,
  }) async {
    final query = '''
[out:json][timeout:12];
(
  node["amenity"="pub"](around:$radiusMeters,$latitude,$longitude);
  node["amenity"="bar"](around:$radiusMeters,$latitude,$longitude);
  way["amenity"="pub"](around:$radiusMeters,$latitude,$longitude);
  way["amenity"="bar"](around:$radiusMeters,$latitude,$longitude);
  relation["amenity"="pub"](around:$radiusMeters,$latitude,$longitude);
  relation["amenity"="bar"](around:$radiusMeters,$latitude,$longitude);
);
out center tags 80;
''';

    try {
      final response = await _postOverpassQuery(query).timeout(const Duration(seconds: 9));

      if (response.statusCode != 200) {
        return LivePubResult(
          pubs: _fallbackPubsWithDistance(latitude, longitude, fixtures),
          live: false,
          message: 'Showing saved pubs while the map service reconnects.',
        );
      }

      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final elements = decoded['elements'];
      if (elements is! List || elements.isEmpty) {
        return LivePubResult(
          pubs: _fallbackPubsWithDistance(latitude, longitude, fixtures),
          live: false,
          message: 'No nearby pubs were returned for this area. Showing recommended MatchPint venues.',
        );
      }

      final pubs = <PubSpot>[];
      for (final element in elements) {
        if (element is Map<String, dynamic>) {
          final pub = _pubFromOverpassElement(
            element,
            latitude: latitude,
            longitude: longitude,
            fixtures: fixtures.isEmpty ? mockFixtures : fixtures,
          );
          if (pub != null) pubs.add(pub);
        }
      }

      final deduped = _dedupePubs(pubs);
      final footballFriendly = _sportsFriendlyPubs(deduped).take(30).toList();
      if (footballFriendly.isEmpty) {
        return LivePubResult(
          pubs: _fallbackPubsWithDistance(latitude, longitude, fixtures),
          live: false,
          message: 'Showing recommended football-friendly venues for this area.',
        );
      }

      return LivePubResult(
        pubs: footballFriendly,
        live: true,
        message: 'Recommended pubs are ready.',
      );
    } catch (error) {
      return LivePubResult(
        pubs: _fallbackPubsWithDistance(latitude, longitude, fixtures),
        live: false,
        message: 'Showing saved pubs while the map service reconnects.',
      );
    }
  }



  Future<http.Response> _postOverpassQuery(String query) async {
    final endpoints = [
      Uri.parse('https://overpass-api.de/api/interpreter'),
      Uri.parse('https://overpass.kumi.systems/api/interpreter'),
      Uri.parse('https://overpass.openstreetmap.ru/api/interpreter'),
    ];
    Object? lastError;
    for (final endpoint in endpoints) {
      try {
        final response = await _client
            .post(
              endpoint,
              headers: const {
                'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8',
                'User-Agent': 'MatchPint',
              },
              body: {'data': query},
            )
            .timeout(const Duration(seconds: 7));
        if (response.statusCode == 200) return response;
        lastError = 'HTTP ${response.statusCode}';
      } catch (error) {
        lastError = error;
      }
    }
    throw Exception('All Overpass endpoints failed: $lastError');
  }


  Future<List<MatchFixture>> _fetchFixtureDownloadFixtures(Uri uri, {required String competition, required String idPrefix}) async {
    final response = await _client.get(uri).timeout(const Duration(seconds: 7));
    if (response.statusCode != 200) throw Exception('HTTP ${response.statusCode}');
    final decoded = jsonDecode(response.body);
    if (decoded is! List) return const [];
    final fixtures = <MatchFixture>[];
    for (final item in decoded) {
      if (item is Map<String, dynamic>) {
        final fixture = _fixtureFromFixtureDownload(item, competition: competition, idPrefix: idPrefix);
        if (fixture != null) fixtures.add(fixture);
      }
    }
    return fixtures;
  }

  MatchFixture? _fixtureFromFixtureDownload(Map<String, dynamic> item, {required String competition, required String idPrefix}) {
    final matchNumber = (item['MatchNumber'] ?? '').toString();
    final home = _normaliseFixtureDownloadTeam((item['HomeTeam'] ?? '').toString());
    final away = _normaliseFixtureDownloadTeam((item['AwayTeam'] ?? '').toString());
    final dateRaw = (item['DateUtc'] ?? '').toString().trim();
    if (matchNumber.isEmpty || home.isEmpty || away.isEmpty || dateRaw.isEmpty) return null;
    final kickoff = DateTime.tryParse(dateRaw.replaceFirst(' ', 'T'))?.toLocal() ?? DateTime.now().add(const Duration(days: 7));
    final venue = (item['Location'] ?? 'Venue TBC').toString();
    return MatchFixture(
      id: '${idPrefix}_$matchNumber',
      homeTeam: home,
      awayTeam: away,
      competition: competition,
      kickoff: kickoff,
      venue: venue,
      importance: _fixtureImportance(competition, home, away),
    );
  }

  String _normaliseFixtureDownloadTeam(String raw) {
    final cleaned = raw.trim();
    const names = {
      'Spurs': 'Tottenham Hotspur',
      'Wolves': 'Wolverhampton Wanderers',
      'Man City': 'Manchester City',
      'Man Utd': 'Manchester United',
      'Nott\'m Forest': 'Nottingham Forest',
      'Brighton': 'Brighton and Hove Albion',
      'Newcastle': 'Newcastle United',
      'West Ham': 'West Ham United',
      'Leeds': 'Leeds United',
      'Burnley': 'Burnley',
    };
    return names[cleaned] ?? cleaned;
  }

  Future<List<Map<String, dynamic>>> _fetchSportsDbEvents(Uri uri) async {
    final response = await _client.get(uri).timeout(const Duration(seconds: 7));
    if (response.statusCode != 200) {
      throw Exception('HTTP ${response.statusCode}');
    }
    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final events = decoded['events'];
    if (events is! List) return const [];
    return events.whereType<Map<String, dynamic>>().toList();
  }

  List<String> _seasonCandidates() {
    final now = DateTime.now();
    final startYear = now.month >= 7 ? now.year : now.year - 1;
    return ['${startYear}-${startYear + 1}', '${startYear + 1}-${startYear + 2}'];
  }

  MatchFixture? _fixtureFromSportsDbEvent(Map<String, dynamic> event, {required String fallbackCompetition}) {
    final id = (event['idEvent'] ?? '').toString();
    final home = _cleanTeamName((event['strHomeTeam'] ?? '').toString());
    final away = _cleanTeamName((event['strAwayTeam'] ?? '').toString());
    if (id.isEmpty || home.isEmpty || away.isEmpty) return null;

    final competition = (event['strLeague'] ?? fallbackCompetition).toString();
    final venue = (event['strVenue'] ?? '').toString().trim().isEmpty ? 'Venue TBC' : (event['strVenue'] ?? '').toString().trim();
    final kickoff = _parseSportsDbDateTime(event['dateEvent']?.toString(), event['strTime']?.toString());

    return MatchFixture(
      id: 'tsdb_$id',
      homeTeam: home,
      awayTeam: away,
      competition: competition,
      kickoff: kickoff,
      venue: venue,
      importance: _fixtureImportance(competition, home, away),
    );
  }

  DateTime _parseSportsDbDateTime(String? date, String? time) {
    final cleanDate = (date ?? '').trim();
    final cleanTime = (time ?? '').replaceAll('Z', '').trim();
    if (cleanDate.isEmpty) return DateTime.now().add(const Duration(days: 7));
    final candidate = cleanTime.isEmpty ? '${cleanDate}T19:45:00Z' : '${cleanDate}T$cleanTime${cleanTime.contains('+') ? '' : 'Z'}';
    return DateTime.tryParse(candidate)?.toLocal() ?? DateTime.tryParse(cleanDate) ?? DateTime.now().add(const Duration(days: 7));
  }

  int _fixtureImportance(String competition, String home, String away) {
    var score = 72;
    final lower = competition.toLowerCase();
    if (lower.contains('champions')) score += 26;
    if (lower.contains('europa')) score += 20;
    if (lower.contains('premier')) score += 18;
    if (lower.contains('women')) score += 12;
    const majorTeams = ['arsenal', 'chelsea', 'liverpool', 'tottenham', 'west ham', 'manchester city', 'manchester united', 'newcastle'];
    if (majorTeams.any((team) => home.toLowerCase().contains(team))) score += 4;
    if (majorTeams.any((team) => away.toLowerCase().contains(team))) score += 4;
    return score.clamp(0, 100).toInt();
  }

  PubSpot? _pubFromOverpassElement(
    Map<String, dynamic> element, {
    required double latitude,
    required double longitude,
    required List<MatchFixture> fixtures,
  }) {
    final tags = element['tags'];
    if (tags is! Map<String, dynamic>) return null;
    final name = (tags['name'] ?? '').toString().trim();
    if (name.isEmpty) return null;

    final center = element['center'];
    final lat = _readDouble(element['lat']) ?? (center is Map ? _readDouble(center['lat']) : null);
    final lon = _readDouble(element['lon']) ?? (center is Map ? _readDouble(center['lon']) : null);
    if (lat == null || lon == null) return null;

    final seed = name.hashCode.abs() + element['id'].hashCode.abs();
    final amenity = (tags['amenity'] ?? 'pub').toString();
    final area = _areaFromTags(tags);
    final distance = _distanceKm(latitude, longitude, lat, lon);
    final sportsEvidence = _sportsEvidenceForVenue(name, tags);
    final hasSportsSignals = sportsEvidence.score >= 45;
    final evidenceLift = (sportsEvidence.score / 3).round();
    final screenQuality = 48 + evidenceLift + seed % 14;
    final crowdLevel = 34 + seed % 44 + (hasSportsSignals ? 8 : 0);
    final noiseDb = 50 + seed % 27 + (hasSportsSignals ? 3 : 0);
    final foodScore = 58 + (seed ~/ 7) % 35;
    final soloFriendly = noiseDb < 70 || crowdLevel < 65;
    final fixtureIds = _estimatedBroadcastFixtures(seed, fixtures, hasSportsSignals: hasSportsSignals);

    return PubSpot(
      id: 'osm_${element['type']}_${element['id']}',
      name: name,
      area: area,
      distanceKm: distance,
      vibe: sportsEvidence.score >= 70 ? 'Verified football-friendly' : hasSportsSignals ? 'Likely football-friendly' : amenity == 'bar' ? 'Nearby bar, unverified' : 'Nearby pub, unverified',
      noiseDb: noiseDb.clamp(45, 88).toInt(),
      crowdLevel: crowdLevel.clamp(25, 95).toInt(),
      screenQuality: screenQuality.clamp(45, 96).toInt(),
      soloFriendly: soloFriendly,
      foodScore: foodScore.clamp(40, 95).toInt(),
      priceLevel: 2 + seed % 2,
      features: _featuresFromTags(tags, sportsEvidence: sportsEvidence, amenity: amenity),
      supportedTeams: _estimatedSupportedTeams(seed, fixtures),
      broadcastingFixtureIds: fixtureIds,
      broadcastConfidence: (48 + (sportsEvidence.score * 0.45).round() + seed % 16).clamp(35, 95).toInt(),
      latitude: lat,
      longitude: lon,
      description: _descriptionForLiveVenue(name, tags, sportsEvidence: sportsEvidence),
      sportsEvidenceScore: sportsEvidence.score,
      sportsEvidenceReasons: sportsEvidence.reasons,
    );
  }

  List<PubSpot> _fallbackPubsWithDistance(double latitude, double longitude, List<MatchFixture> fixtures) {
    return mockPubs.map((pub) {
      final liveDistance = _distanceKm(latitude, longitude, pub.latitude, pub.longitude);
      final ids = pub.broadcastingFixtureIds.where((id) => (fixtures.isEmpty ? mockFixtures : fixtures).any((f) => f.id == id)).toList();
      final mappedIds = ids.isEmpty && fixtures.isNotEmpty ? [fixtures.first.id] : pub.broadcastingFixtureIds;
      return PubSpot(
        id: pub.id,
        name: pub.name,
        area: pub.area,
        distanceKm: liveDistance,
        vibe: pub.vibe,
        noiseDb: pub.noiseDb,
        crowdLevel: pub.crowdLevel,
        screenQuality: pub.screenQuality,
        soloFriendly: pub.soloFriendly,
        foodScore: pub.foodScore,
        priceLevel: pub.priceLevel,
        features: pub.features,
        supportedTeams: pub.supportedTeams,
        broadcastingFixtureIds: mappedIds,
        broadcastConfidence: pub.broadcastConfidence,
        latitude: pub.latitude,
        longitude: pub.longitude,
        description: pub.description,
        sportsEvidenceScore: pub.sportsEvidenceScore,
        sportsEvidenceReasons: pub.sportsEvidenceReasons,
      );
    }).toList();
  }

  List<String> _estimatedBroadcastFixtures(int seed, List<MatchFixture> fixtures, {required bool hasSportsSignals}) {
    if (fixtures.isEmpty) return const [];
    final count = min(fixtures.length, hasSportsSignals ? 4 : 2);
    final selected = <String>[];
    for (var i = 0; i < count; i++) {
      final index = (seed + i * 3) % fixtures.length;
      selected.add(fixtures[index].id);
    }
    return selected.toSet().toList();
  }

  List<String> _estimatedSupportedTeams(int seed, List<MatchFixture> fixtures) {
    if (fixtures.isEmpty) return const [];
    final teams = <String>[];
    final first = fixtures[seed % fixtures.length];
    teams.add(first.homeTeam);
    if (seed.isEven) teams.add(first.awayTeam);
    return teams.toSet().toList();
  }

  List<String> _featuresFromTags(Map<String, dynamic> tags, {required _SportsEvidence sportsEvidence, required String amenity}) {
    final features = <String>[];
    final joined = tags.entries.map((entry) => '${entry.key}:${entry.value}').join(' ').toLowerCase();

    if ((tags['outdoor_seating'] ?? '').toString() == 'yes') features.add('outdoor seating');
    if ((tags['food'] ?? '').toString() == 'yes' || (tags['restaurant'] ?? '').toString().isNotEmpty) features.add('food available');
    if ((tags['opening_hours'] ?? '').toString().isNotEmpty) features.add('opening hours listed');
    if ((tags['website'] ?? '').toString().isNotEmpty || (tags['contact:website'] ?? '').toString().isNotEmpty) features.add('website listed');
    if (amenity == 'bar') features.add('bar');
    if (_containsAny(joined, const ['sky sports'])) features.add('Sky Sports');
    if (_containsAny(joined, const ['tnt sports', 'bt sport'])) features.add('TNT Sports');
    if (_containsAny(joined, const ['big screen', 'screens', 'television', 'tv=yes', 'television=yes'])) features.add('screens');
    if ((tags['wheelchair'] ?? '').toString() == 'yes') features.add('step-free access');

    // Keep Features user-facing: no source names, evidence labels, or developer-style metadata.
    if (features.isEmpty && sportsEvidence.score >= 45) features.add('matchday atmosphere');
    if (features.isEmpty) features.add('nearby pub');
    return features.toSet().take(7).toList();
  }

  String _descriptionForLiveVenue(String name, Map<String, dynamic> tags, {required _SportsEvidence sportsEvidence}) {
    final amenity = (tags['amenity'] ?? 'pub').toString();
    final venueType = amenity == 'bar' ? 'bar' : 'pub';
    final seating = (tags['outdoor_seating'] ?? '').toString() == 'yes' ? ' It also lists outdoor seating, which can help on busy match nights.' : '';
    final externalLabel = sportsEvidence.externalEvidenceLabel;
    if (externalLabel != null && externalLabel.isNotEmpty) {
      return '$name is a nearby $venueType with verified football-friendly evidence. $externalLabel MatchPint still predicts the most suitable fixture rather than claiming a fixed broadcast schedule.$seating';
    }
    final evidence = sportsEvidence.reasons.isEmpty ? 'map data only' : sportsEvidence.reasons.take(2).join(' and ');
    if (sportsEvidence.score >= 70) {
      return '$name is a nearby $venueType with strong open-data evidence for live sport or televisions from $evidence. MatchPint predicts the best fixture for the venue.$seating';
    }
    if (sportsEvidence.score >= 45) {
      return '$name is a nearby $venueType with some football-friendly signals from $evidence. It is labelled as likely rather than verified until comments or stronger external data confirm screens.$seating';
    }
    return '$name is a nearby $venueType from map data, but MatchPint has not found reliable evidence that it has football screens yet. It is shown only as an unverified fallback.$seating';
  }

  String _areaFromTags(Map<String, dynamic> tags) {
    for (final key in ['addr:suburb', 'addr:neighbourhood', 'addr:city', 'addr:street']) {
      final value = (tags[key] ?? '').toString().trim();
      if (value.isNotEmpty) return value;
    }
    return 'Nearby';
  }

  List<PubSpot> _sportsFriendlyPubs(List<PubSpot> pubs) {
    int tierRank(PubSpot pub) {
      if (pub.verifiedFootballFriendly) return 0;
      if (pub.likelyFootballFriendly) return 1;
      return 2;
    }

    final sorted = pubs.toList()
      ..sort((a, b) {
        final tierCompare = tierRank(a).compareTo(tierRank(b));
        if (tierCompare != 0) return tierCompare;
        final scoreCompare = b.sportsEvidenceScore.compareTo(a.sportsEvidenceScore);
        if (scoreCompare != 0) return scoreCompare;
        return a.distanceKm.compareTo(b.distanceKm);
      });

    final verified = sorted.where((pub) => pub.verifiedFootballFriendly).toList();
    final likely = sorted.where((pub) => pub.likelyFootballFriendly).toList();
    final unverified = sorted.where((pub) => pub.unverifiedFootballVenue).toList();

    // Product rule: normal recommendations should be verified/likely first. Unverified
    // OSM pubs are only included when free/open data is too sparse around the user.
    final output = <PubSpot>[...verified, ...likely];
    if (output.length < 8) {
      output.addAll(unverified.take(8 - output.length));
    }
    return output.take(30).toList();
  }

  _SportsEvidence _sportsEvidenceForVenue(String name, Map<String, dynamic> tags) {
    final externalEvidence = externalSportsVenueEvidenceForName(name);
    if (externalEvidence != null) {
      return _SportsEvidence(
        score: externalEvidence.score.clamp(70, 100).toInt(),
        reasons: [
          'external sports-pub source',
          externalEvidence.sourceName,
          ...externalEvidence.features.take(3),
        ].toSet().take(5).toList(),
        externalSourceName: externalEvidence.sourceName,
        externalSourceUrl: externalEvidence.sourceUrl,
        externalEvidenceLabel: externalEvidence.evidenceLabel,
      );
    }

    var score = 0;
    final reasons = <String>[];
    final values = tags.entries.map((entry) => '${entry.key}:${entry.value}').join(' ');
    final joined = '$name $values'.toLowerCase();
    final website = '${tags['website'] ?? ''} ${tags['contact:website'] ?? ''} ${tags['url'] ?? ''}'.toLowerCase();
    final brand = '${tags['brand'] ?? ''} ${tags['operator'] ?? ''}'.toLowerCase();

    void add(int points, String reason) {
      score += points;
      if (!reasons.contains(reason)) reasons.add(reason);
    }

    // Strong free/open-data evidence. These can make a venue "Verified" because they
    // come from explicit OSM metadata rather than just the venue name.
    final television = '${tags['television'] ?? ''}'.toLowerCase();
    final tv = '${tags['tv'] ?? ''}'.toLowerCase();
    final liveSport = '${tags['live_sport'] ?? tags['live_sports'] ?? ''}'.toLowerCase();
    final sport = '${tags['sport'] ?? ''}'.toLowerCase();
    final theme = '${tags['theme'] ?? ''}'.toLowerCase();

    if (['yes', 'true', '1'].contains(television)) add(82, 'OSM television=yes');
    if (['yes', 'true', '1'].contains(tv)) add(78, 'OSM tv=yes');
    if (['yes', 'true', '1'].contains(liveSport)) add(88, 'OSM live_sport=yes');
    if (sport.contains('football') || sport.contains('soccer')) add(70, 'OSM sport=football');
    if (theme.contains('sports') || theme.contains('sport')) add(72, 'OSM sports theme');
    if (_containsAny(joined, const ['screen:football=yes', 'screen:sport=yes', 'screens=yes'])) add(70, 'OSM screen evidence');

    final hasVerifiedOpenSignal = score >= 70;

    // Weak fallback signals. They support ranking, but cannot make a venue Verified alone.
    if (_containsAny(joined, const ['sports bar', 'sports pub', 'live sports', 'live sport'])) add(24, 'likely sports-bar metadata');
    if (_containsAny(joined, const ['sky sports', 'tnt sports', 'bt sport', 'premier sports'])) add(22, 'likely sports TV provider metadata');
    if (_containsAny(joined, const ['big screen', 'screens', 'screening', 'television', ' live tv'])) add(12, 'likely screen / TV metadata');
    if (_containsAny(website, const ['live-sport', 'sky-sports', 'tnt-sports'])) add(14, 'likely venue website sport path');
    if (_containsAny(brand, const ['belushi', 'walkabout', 'greenwood', 'rileys', 'sports bar'])) add(16, 'likely sports-pub brand');

    if (_containsAny(joined, const ['wine bar', 'cocktail', 'gin bar', 'fine dining', 'hotel bar', 'members club', 'lounge'])) {
      score -= 30;
      if (!reasons.contains('negative venue-style signal')) reasons.add('negative venue-style signal');
    }

    // Do not let weak keyword inference masquerade as verified data.
    final maxScore = hasVerifiedOpenSignal ? 100 : 64;
    final clamped = score.clamp(0, maxScore).toInt();
    return _SportsEvidence(score: clamped, reasons: reasons.take(5).toList());
  }

  bool _containsAny(String text, List<String> needles) => needles.any(text.contains);

  List<MatchFixture> _dedupeFixtures(List<MatchFixture> fixtures) {
    final seen = <String>{};
    final output = <MatchFixture>[];
    for (final fixture in fixtures) {
      final key = '${fixture.homeTeam}|${fixture.awayTeam}|${fixture.kickoff.toIso8601String().substring(0, 10)}';
      if (seen.add(key)) output.add(fixture);
    }
    return output;
  }

  List<PubSpot> _dedupePubs(List<PubSpot> pubs) {
    final seen = <String>{};
    final output = <PubSpot>[];
    pubs.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
    for (final pub in pubs) {
      final key = pub.name.toLowerCase();
      if (seen.add(key)) output.add(pub);
    }
    return output;
  }

  String _cleanTeamName(String raw) {
    return raw.replaceAll(' FC', '').replaceAll(' WFC', ' Women').replaceAll(' AFC', '').trim();
  }

  double? _readDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  double _distanceKm(double lat1, double lon1, double lat2, double lon2) {
    const earthRadiusKm = 6371.0;
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) + cos(_toRadians(lat1)) * cos(_toRadians(lat2)) * sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadiusKm * c;
  }

  double _toRadians(double degrees) => degrees * pi / 180.0;

  void dispose() => _client.close();
}

class _SportsEvidence {
  const _SportsEvidence({
    required this.score,
    required this.reasons,
    this.externalSourceName,
    this.externalSourceUrl,
    this.externalEvidenceLabel,
  });

  final int score;
  final List<String> reasons;
  final String? externalSourceName;
  final String? externalSourceUrl;
  final String? externalEvidenceLabel;
}

class _LeagueSource {
  const _LeagueSource({required this.id, required this.fallbackName});
  final String id;
  final String fallbackName;
}
