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

  Future<LiveFixtureResult> fetchFootballFixtures() async {
    final List<_LeagueSource> leagues = const [
      _LeagueSource(id: '4328', fallbackName: 'English Premier League'),
      _LeagueSource(id: '4480', fallbackName: 'UEFA Champions League'),
      _LeagueSource(id: '4481', fallbackName: 'UEFA Europa League'),
    ];

    final List<MatchFixture> fixtures = [];
    final List<String> failures = [];
    final seasons = _seasonCandidates();

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

    final now = DateTime.now();
    fixtures.sort((a, b) => a.kickoff.compareTo(b.kickoff));
    final deduped = _dedupeFixtures(fixtures)
        .where((fixture) => fixture.kickoff.isAfter(now.subtract(const Duration(hours: 12))))
        .take(90)
        .toList();

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
      message: 'Live fixtures loaded from TheSportsDB: Premier League, Champions League, and Europa League.$skipped',
    );
  }

  Future<LivePubResult> fetchNearbyPubs({
    required double latitude,
    required double longitude,
    required List<MatchFixture> fixtures,
    int radiusMeters = defaultRadiusMeters,
  }) async {
    final query = '''
[out:json][timeout:30];
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
      final response = await _postOverpassQuery(query).timeout(const Duration(seconds: 24));

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
            .timeout(const Duration(seconds: 18));
        if (response.statusCode == 200) return response;
        lastError = 'HTTP ${response.statusCode}';
      } catch (error) {
        lastError = error;
      }
    }
    throw Exception('All Overpass endpoints failed: $lastError');
  }

  Future<List<Map<String, dynamic>>> _fetchSportsDbEvents(Uri uri) async {
    final response = await _client.get(uri).timeout(const Duration(seconds: 12));
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
    final features = <String>['live OSM venue'];
    if (hasSportsSignals) features.add('sports signal');
    if ((tags['outdoor_seating'] ?? '').toString() == 'yes') features.add('outdoor seating');
    if ((tags['food'] ?? '').toString() == 'yes' || (tags['restaurant'] ?? '').toString().isNotEmpty) features.add('food available');
    if ((tags['opening_hours'] ?? '').toString().isNotEmpty) features.add('opening hours listed');
    if ((tags['website'] ?? '').toString().isNotEmpty) features.add('website listed');
    if (amenity == 'bar') features.add('bar');
    if (features.length < 3) features.add('broadcast estimated');
    return features.take(6).toList();
  }

  String _descriptionForLiveVenue(String name, Map<String, dynamic> tags, {required bool hasSportsSignals}) {
    final hours = (tags['opening_hours'] ?? '').toString().trim();
    if (hasSportsSignals) {
      return '$name is a live OpenStreetMap venue with sports-related signals. MatchPint estimates fixture suitability from venue tags, distance, and match relevance.';
    }
    if (hours.isNotEmpty) {
      return '$name is a live OpenStreetMap venue with listed opening hours. Broadcast status is estimated until users or venues confirm the fixture.';
    }
    return '$name is a live OpenStreetMap venue nearby. MatchPint estimates whether it is suitable for this match from location and venue metadata.';
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
