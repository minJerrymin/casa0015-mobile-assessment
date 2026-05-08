import 'package:flutter/material.dart';

import '../models/match_fixture.dart';
import '../theme/app_theme.dart';
import 'team_badge.dart';

class MatchCard extends StatelessWidget {
  const MatchCard({super.key, required this.fixture, required this.onTap});

  final MatchFixture fixture;
  final VoidCallback onTap;

  String _formatKickoff(DateTime dt) {
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '${dt.day}/${dt.month} $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final muted = AppTheme.subtleText(context);
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              SizedBox(
                height: 58,
                width: 66,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Positioned(left: 0, child: TeamBadge(team: fixture.homeTeam, size: 36)),
                    Positioned(right: 0, child: TeamBadge(team: fixture.awayTeam, size: 36)),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(fixture.title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    Text('${fixture.competition} • ${_formatKickoff(fixture.kickoff)}', style: TextStyle(color: muted)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: muted),
            ],
          ),
        ),
      ),
    );
  }
}
