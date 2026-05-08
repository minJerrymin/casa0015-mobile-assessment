class TeamProfile {
  const TeamProfile({
    required this.name,
    required this.shortName,
    required this.apiFootballId,
    required this.logoUrl,
  });

  final String name;
  final String shortName;
  final int apiFootballId;
  final String logoUrl;
}

// Team logos are loaded from the API-Sports/API-Football media CDN.
// They are remote images rather than bundled assets so the app can stay light and
// badge updates can be handled by the data provider.
const List<TeamProfile> premierLeagueTeamProfiles = [
  TeamProfile(name: 'Arsenal', shortName: 'ARS', apiFootballId: 42, logoUrl: 'https://media.api-sports.io/football/teams/42.png'),
  TeamProfile(name: 'Aston Villa', shortName: 'AVL', apiFootballId: 66, logoUrl: 'https://media.api-sports.io/football/teams/66.png'),
  TeamProfile(name: 'Bournemouth', shortName: 'BOU', apiFootballId: 35, logoUrl: 'https://media.api-sports.io/football/teams/35.png'),
  TeamProfile(name: 'Brentford', shortName: 'BRE', apiFootballId: 55, logoUrl: 'https://media.api-sports.io/football/teams/55.png'),
  TeamProfile(name: 'Brighton & Hove Albion', shortName: 'BHA', apiFootballId: 51, logoUrl: 'https://media.api-sports.io/football/teams/51.png'),
  TeamProfile(name: 'Burnley', shortName: 'BUR', apiFootballId: 44, logoUrl: 'https://media.api-sports.io/football/teams/44.png'),
  TeamProfile(name: 'Chelsea', shortName: 'CHE', apiFootballId: 49, logoUrl: 'https://media.api-sports.io/football/teams/49.png'),
  TeamProfile(name: 'Crystal Palace', shortName: 'CRY', apiFootballId: 52, logoUrl: 'https://media.api-sports.io/football/teams/52.png'),
  TeamProfile(name: 'Everton', shortName: 'EVE', apiFootballId: 45, logoUrl: 'https://media.api-sports.io/football/teams/45.png'),
  TeamProfile(name: 'Fulham', shortName: 'FUL', apiFootballId: 36, logoUrl: 'https://media.api-sports.io/football/teams/36.png'),
  TeamProfile(name: 'Leeds United', shortName: 'LEE', apiFootballId: 63, logoUrl: 'https://media.api-sports.io/football/teams/63.png'),
  TeamProfile(name: 'Liverpool', shortName: 'LIV', apiFootballId: 40, logoUrl: 'https://media.api-sports.io/football/teams/40.png'),
  TeamProfile(name: 'Manchester City', shortName: 'MCI', apiFootballId: 50, logoUrl: 'https://media.api-sports.io/football/teams/50.png'),
  TeamProfile(name: 'Manchester United', shortName: 'MUN', apiFootballId: 33, logoUrl: 'https://media.api-sports.io/football/teams/33.png'),
  TeamProfile(name: 'Newcastle United', shortName: 'NEW', apiFootballId: 34, logoUrl: 'https://media.api-sports.io/football/teams/34.png'),
  TeamProfile(name: 'Nottingham Forest', shortName: 'NFO', apiFootballId: 65, logoUrl: 'https://media.api-sports.io/football/teams/65.png'),
  TeamProfile(name: 'Sunderland', shortName: 'SUN', apiFootballId: 746, logoUrl: 'https://media.api-sports.io/football/teams/746.png'),
  TeamProfile(name: 'Tottenham Hotspur', shortName: 'TOT', apiFootballId: 47, logoUrl: 'https://media.api-sports.io/football/teams/47.png'),
  TeamProfile(name: 'West Ham United', shortName: 'WHU', apiFootballId: 48, logoUrl: 'https://media.api-sports.io/football/teams/48.png'),
  TeamProfile(name: 'Wolverhampton Wanderers', shortName: 'WOL', apiFootballId: 39, logoUrl: 'https://media.api-sports.io/football/teams/39.png'),
];

List<String> get premierLeagueTeams => premierLeagueTeamProfiles.map((team) => team.name).toList(growable: false);

TeamProfile? teamProfileFor(String team) {
  final needle = normaliseTeamName(team);
  for (final profile in premierLeagueTeamProfiles) {
    if (normaliseTeamName(profile.name) == needle || normaliseTeamName(profile.shortName) == needle) {
      return profile;
    }
  }
  for (final profile in premierLeagueTeamProfiles) {
    final name = normaliseTeamName(profile.name);
    if (name.contains(needle) || needle.contains(name)) {
      return profile;
    }
  }
  return null;
}

String? teamLogoUrl(String team) => teamProfileFor(team)?.logoUrl;
String teamShortName(String team) => teamProfileFor(team)?.shortName ?? _fallbackInitials(team);

String normaliseTeamName(String team) {
  return team
      .toLowerCase()
      .replaceAll('afc ', '')
      .replaceAll(' fc', '')
      .replaceAll('hotspur', '')
      .replaceAll('wanderers', 'wolves')
      .replaceAll('wolverhampton', 'wolves')
      .replaceAll('united', 'utd')
      .replaceAll('&', 'and')
      .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
      .trim();
}

bool teamNamesMatch(String a, String b) {
  final left = normaliseTeamName(a);
  final right = normaliseTeamName(b);
  return left == right || left.contains(right) || right.contains(left);
}

String _fallbackInitials(String team) {
  return team
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .take(3)
      .map((part) => part[0])
      .join()
      .toUpperCase();
}
