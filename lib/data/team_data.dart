const List<String> premierLeagueTeams = [
  'Arsenal',
  'Aston Villa',
  'Bournemouth',
  'Brentford',
  'Brighton & Hove Albion',
  'Burnley',
  'Chelsea',
  'Crystal Palace',
  'Everton',
  'Fulham',
  'Leeds United',
  'Liverpool',
  'Manchester City',
  'Manchester United',
  'Newcastle United',
  'Nottingham Forest',
  'Sunderland',
  'Tottenham Hotspur',
  'West Ham United',
  'Wolverhampton Wanderers',
];

String normaliseTeamName(String team) {
  return team
      .toLowerCase()
      .replaceAll('afc ', '')
      .replaceAll(' fc', '')
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
