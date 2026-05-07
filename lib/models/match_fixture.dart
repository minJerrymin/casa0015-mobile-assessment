class MatchFixture {
  const MatchFixture({
    required this.id,
    required this.homeTeam,
    required this.awayTeam,
    required this.competition,
    required this.kickoff,
    required this.venue,
    required this.importance,
  });

  final String id;
  final String homeTeam;
  final String awayTeam;
  final String competition;
  final DateTime kickoff;
  final String venue;
  final int importance;

  String get title => '$homeTeam vs $awayTeam';
}
