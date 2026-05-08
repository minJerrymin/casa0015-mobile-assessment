import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;

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
          ? 'Showing latest available fixtures. MatchPint backend URL will be bundled into the release APK.'
          : 'Showing latest available fixtures while MatchPint refreshes the live service.',
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
        message: 'Live fixture API unavailable. Using the built-in prototype fixtures.',
      );
    }

    final skipped = failures.isEmpty ? '' : ' Partial fallback: ${failures.join('; ')}.';
    return LiveFixtureResult(
      fixtures: deduped,
      live: true,
      message: 'Showing the latest available next-3-day fixtures from fallback public feeds while MatchPint refreshes the live backend.$skipped',
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
          message: 'Overpass returned HTTP ${response.statusCode}. Using prototype pubs with live-distance ranking.',
        );
      }

      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final elements = decoded['elements'];
      if (elements is! List || elements.isEmpty) {
        return LivePubResult(
          pubs: _fallbackPubsWithDistance(latitude, longitude, fixtures),
          live: false,
          message: 'No OSM pubs or bars were returned nearby. Using prototype pubs with live-distance ranking.',
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

      final deduped = _dedupePubs(pubs).take(30).toList();
      if (deduped.isEmpty) {
        return LivePubResult(
          pubs: _fallbackPubsWithDistance(latitude, longitude, fixtures),
          live: false,
          message: 'Nearby OSM venues lacked usable names/locations. Using prototype pubs with live-distance ranking.',
        );
      }

      return LivePubResult(
        pubs: deduped,
        live: true,
        message: 'Live pubs loaded from OpenStreetMap/Overpass around your selected area. Broadcast status is estimated from fixture and venue signals.',
      );
    } catch (error) {
      return LivePubResult(
        pubs: _fallbackPubsWithDistance(latitude, longitude, fixtures),
        live: false,
        message: 'Could not reach any Overpass endpoint (${error.runtimeType}). Using prototype pubs with live-distance ranking.',
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
                'User-Agent': 'MatchPint CASA0015 student prototype',
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
    final hasSportsSignals = _hasSportsSignals(name, tags);
    final screenQuality = (hasSportsSignals ? 75 : 58) + seed % 18;
    final crowdLevel = 38 + seed % 49;
    final noiseDb = 52 + seed % 29;
    final foodScore = 58 + (seed ~/ 7) % 35;
    final soloFriendly = noiseDb < 69 || crowdLevel < 62;
    final fixtureIds = _estimatedBroadcastFixtures(seed, fixtures, hasSportsSignals: hasSportsSignals);

    return PubSpot(
      id: 'osm_${element['type']}_${element['id']}',
      name: name,
      area: area,
      distanceKm: distance,
      vibe: hasSportsSignals ? 'Live sport venue signal' : amenity == 'bar' ? 'Bar with possible screens' : 'Local pub, broadcast unconfirmed',
      noiseDb: noiseDb.clamp(45, 88).toInt(),
      crowdLevel: crowdLevel.clamp(25, 95).toInt(),
      screenQuality: screenQuality.clamp(45, 96).toInt(),
      soloFriendly: soloFriendly,
      foodScore: foodScore.clamp(40, 95).toInt(),
      priceLevel: 2 + seed % 2,
      features: _featuresFromTags(tags, hasSportsSignals: hasSportsSignals, amenity: amenity),
      supportedTeams: _estimatedSupportedTeams(seed, fixtures),
      broadcastingFixtureIds: fixtureIds,
      broadcastConfidence: hasSportsSignals ? 72 + seed % 18 : 48 + seed % 22,
      latitude: lat,
      longitude: lon,
      description: _descriptionForLiveVenue(name, tags, hasSportsSignals: hasSportsSignals),
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

  List<String> _featuresFromTags(Map<String, dynamic> tags, {required bool hasSportsSignals, required String amenity}) {
    final features = <String>[];
    if (hasSportsSignals) features.add('sports signal');
    if ((tags['outdoor_seating'] ?? '').toString() == 'yes') features.add('outdoor seating');
    if ((tags['food'] ?? '').toString() == 'yes' || (tags['restaurant'] ?? '').toString().isNotEmpty) features.add('food available');
    if ((tags['opening_hours'] ?? '').toString().isNotEmpty) features.add('opening hours listed');
    if ((tags['website'] ?? '').toString().isNotEmpty) features.add('website listed');
    if (amenity == 'bar') features.add('bar');
    if (features.isEmpty) features.add('local venue');
    if (features.length < 3) features.add('matchday option');
    return features.take(6).toList();
  }

  String _descriptionForLiveVenue(String name, Map<String, dynamic> tags, {required bool hasSportsSignals}) {
    final hours = (tags['opening_hours'] ?? '').toString().trim();
    final amenity = (tags['amenity'] ?? 'pub').toString();
    final venueType = amenity == 'bar' ? 'bar' : 'pub';
    final seating = (tags['outdoor_seating'] ?? '').toString() == 'yes' ? ' It also lists outdoor seating, which can help on busy match nights.' : '';
    if (hasSportsSignals) {
      return '$name is a $venueType with signs of a sport-friendly setup, making it a stronger candidate for watching high-profile fixtures.$seating';
    }
    if (hours.isNotEmpty) {
      return '$name is a nearby $venueType with listed opening hours. It may work well as a convenient matchday option, although the exact broadcast should still be confirmed.$seating';
    }
    return '$name is a nearby $venueType that MatchPint ranks by distance, comfort, and matchday suitability. Check the venue before travelling for a specific fixture.$seating';
  }

  String _areaFromTags(Map<String, dynamic> tags) {
    for (final key in ['addr:suburb', 'addr:neighbourhood', 'addr:city', 'addr:street']) {
      final value = (tags[key] ?? '').toString().trim();
      if (value.isNotEmpty) return value;
    }
    return 'Nearby';
  }

  bool _hasSportsSignals(String name, Map<String, dynamic> tags) {
    final joined = ([name, ...tags.entries.map((e) => '${e.key}:${e.value}')]).join(' ').toLowerCase();
    return joined.contains('sport') || joined.contains('football') || joined.contains('screen') || joined.contains('tv') || joined.contains('pub');
  }

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

class _LeagueSource {
  const _LeagueSource({required this.id, required this.fallbackName});
  final String id;
  final String fallbackName;
}
