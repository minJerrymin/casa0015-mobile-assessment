import 'package:flutter/material.dart';
import '../models/check_in.dart';
import '../theme/app_theme.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key, required this.checkIns});

  final List<CheckIn> checkIns;

  String _format(DateTime dt) {
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '${dt.day}/${dt.month}/${dt.year} $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 110),
      children: [
        Text('My Nights', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        const Text('Your personal football watching passport. Save where you watched, how it felt, and whether you would return.', style: TextStyle(color: AppTheme.muted)),
        const SizedBox(height: 20),
        if (checkIns.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(Icons.bookmark_border, size: 54, color: AppTheme.pitchGreen.withOpacity(0.8)),
                  const SizedBox(height: 14),
                  Text('No match nights yet', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 8),
                  const Text('Start match mode from any pub detail page, then save your first watching experience.', textAlign: TextAlign.center, style: TextStyle(color: AppTheme.muted)),
                ],
              ),
            ),
          )
        else
          ...checkIns.reversed.map((entry) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(entry.matchTitle, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
                        const SizedBox(height: 4),
                        Text('${entry.pubName} • ${_format(entry.timestamp)}', style: const TextStyle(color: AppTheme.muted)),
                        const SizedBox(height: 12),
                        Wrap(spacing: 8, children: [
                          Chip(label: Text(entry.mood)),
                          Chip(label: Text('${entry.noiseDb} dB')),
                        ]),
                        const SizedBox(height: 10),
                        Text(entry.note),
                      ],
                    ),
                  ),
                ),
              )),
      ],
    );
  }
}
