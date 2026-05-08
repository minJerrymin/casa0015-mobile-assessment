import 'package:flutter/material.dart';

import '../data/team_data.dart';

class TeamBadge extends StatelessWidget {
  const TeamBadge({super.key, required this.team, this.size = 30, this.showBackground = true});

  final String team;
  final double size;
  final bool showBackground;

  @override
  Widget build(BuildContext context) {
    final url = teamLogoUrl(team);
    final fallback = _FallbackBadge(team: team, size: size, showBackground: showBackground);
    final image = url == null
        ? fallback
        : Image.network(
            url,
            width: size,
            height: size,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => fallback,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return fallback;
            },
          );

    if (!showBackground) return image;
    return Container(
      width: size + 10,
      height: size + 10,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        shape: BoxShape.circle,
        border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.35)),
      ),
      child: image,
    );
  }
}

class _FallbackBadge extends StatelessWidget {
  const _FallbackBadge({required this.team, required this.size, required this.showBackground});

  final String team;
  final double size;
  final bool showBackground;

  @override
  Widget build(BuildContext context) {
    final colour = _teamColour(team);
    final initials = teamShortName(team);
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(Icons.shield, size: size, color: colour),
          Text(
            initials,
            style: TextStyle(
              color: Colors.white,
              fontSize: size * 0.28,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.4,
            ),
          ),
        ],
      ),
    );
  }
}

Color _teamColour(String team) {
  const colours = {
    'Arsenal': Color(0xFFEF0107),
    'Aston Villa': Color(0xFF670E36),
    'Bournemouth': Color(0xFFDA291C),
    'Brentford': Color(0xFFE30613),
    'Brighton & Hove Albion': Color(0xFF0057B8),
    'Burnley': Color(0xFF6C1D45),
    'Chelsea': Color(0xFF034694),
    'Crystal Palace': Color(0xFF1B458F),
    'Everton': Color(0xFF003399),
    'Fulham': Color(0xFF222222),
    'Leeds United': Color(0xFFFFCD00),
    'Liverpool': Color(0xFFC8102E),
    'Manchester City': Color(0xFF6CABDD),
    'Manchester United': Color(0xFFDA291C),
    'Newcastle United': Color(0xFF241F20),
    'Nottingham Forest': Color(0xFFE53233),
    'Sunderland': Color(0xFFEB172B),
    'Tottenham Hotspur': Color(0xFF132257),
    'West Ham United': Color(0xFF7A263A),
    'Wolverhampton Wanderers': Color(0xFFFDB913),
  };
  return colours[team] ?? Colors.teal;
}
