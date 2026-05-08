import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../models/app_user.dart';
import '../models/match_fixture.dart';
import '../models/pub_spot.dart';
import '../models/user_preferences.dart';
import '../models/venue_report.dart';
import '../services/venue_report_service.dart';
import '../theme/app_theme.dart';
import '../widgets/metric_bar.dart';
import '../widgets/pub_map_card.dart';
import '../widgets/score_pill.dart';

class PubDetailScreen extends StatefulWidget {
  const PubDetailScreen({
    super.key,
    required this.pub,
    required this.preferences,
    required this.onStartMatchMode,
    this.fixture,
    this.currentUser,
    this.userLatitude,
    this.userLongitude,
  });

  final PubSpot pub;
  final UserPreferences preferences;
  final MatchFixture? fixture;
  final AppUser? currentUser;
  final double? userLatitude;
  final double? userLongitude;
  final VoidCallback onStartMatchMode;

  @override
  State<PubDetailScreen> createState() => _PubDetailScreenState();
}

class _PubDetailScreenState extends State<PubDetailScreen> {
  final VenueReportService _reportService = VenueReportService();
  VenueReportAggregate? _aggregate;
  bool _loadingReports = false;
  String? _reportMessage;

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  @override
  void didUpdateWidget(covariant PubDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pub.id != widget.pub.id || oldWidget.fixture?.id != widget.fixture?.id) {
      _loadReports();
    }
  }

  Future<void> _loadReports() async {
    final fixture = widget.fixture;
    if (fixture == null) return;
    setState(() => _loadingReports = true);
    final result = await _reportService.loadAggregate(
      pubId: widget.pub.id,
      pubName: widget.pub.name,
      fixtureId: fixture.id,
      fixtureTitle: fixture.title,
    );
    if (!mounted) return;
    setState(() {
      _loadingReports = false;
      _aggregate = result.value;
      _reportMessage = result.error;
    });
  }

  Future<void> _openReportSheet() async {
    final fixture = widget.fixture;
    final user = widget.currentUser;
    if (fixture == null) return;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sign in to comment on a venue.')));
      return;
    }

    final result = await showModalBottomSheet<VenueReport>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _ReportSheet(pub: widget.pub, fixture: fixture, user: user),
    );
    if (result == null) return;

    setState(() {
      _loadingReports = true;
      _reportMessage = 'Saving your comment...';
    });
    final saveResult = await _reportService.submitReport(result);
    if (!mounted) return;
    setState(() {
      _loadingReports = false;
      if (saveResult.value != null) _aggregate = saveResult.value;
      _reportMessage = saveResult.error ?? saveResult.message;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(saveResult.error ?? saveResult.message ?? 'Comment saved.')),
    );
  }

  bool _isEvidenceTag(String tag) {
    final value = tag.toLowerCase();
    return value.contains('external sports-pub') ||
        value.contains('guide') ||
        value.contains('source') ||
        value.contains('verified') ||
        value.contains('osm ') ||
        value.contains('evidence') ||
        value.contains('metadata') ||
        value.contains('user-confirmed') ||
        value.contains('comment confirmed');
  }

  List<String> _visibleFeatureTags() {
    final tags = widget.pub.features.where((feature) => !_isEvidenceTag(feature)).toSet().toList();
    return tags.take(8).toList();
  }

  @override
  Widget build(BuildContext context) {
    final muted = AppTheme.subtleText(context);
    final score = widget.pub.comfortScore(
      prefersCalm: widget.preferences.prefersCalm,
      soloMode: widget.preferences.soloMode,
      wantsFood: widget.preferences.wantsFood,
    );
    final aggregate = _aggregate;
    final screenQuality = aggregate?.hasReports == true ? aggregate!.averageScreenQuality : widget.pub.screenQuality;
    final crowdLevel = aggregate?.hasReports == true ? aggregate!.averageCrowdLevel : widget.pub.crowdLevel;
    final noiseDb = aggregate?.hasReports == true ? aggregate!.averageNoiseDb : widget.pub.noiseDb;
    final foodScore = aggregate?.hasReports == true ? aggregate!.averageFoodScore : widget.pub.foodScore;
    final baseBroadcastScore = widget.fixture == null ? null : fixtureBroadcastScore(widget.pub, widget.fixture!);
    final broadcastScore = baseBroadcastScore == null ? null : (baseBroadcastScore + (aggregate?.confidenceBoost ?? 0)).clamp(0, 100);
    final visibleFeatureTags = _visibleFeatureTags();

    return Scaffold(
      appBar: AppBar(title: Text(widget.pub.name)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 120),
        children: [
          PubMapCard(
            pub: widget.pub,
            initialUserLatitude: widget.userLatitude,
            initialUserLongitude: widget.userLongitude,
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(child: Text(widget.pub.name, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900))),
              ScorePill(score: score, label: 'fit'),
            ],
          ),
          const SizedBox(height: 6),
          Text('${widget.pub.area} • ${widget.pub.distanceKm.toStringAsFixed(1)} km away', style: TextStyle(color: muted)),
          if (visibleFeatureTags.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text('Features', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: visibleFeatureTags.map((feature) => Chip(label: Text(feature))).toList(),
            ),
          ],
          if (widget.fixture != null) ...[
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(aggregate?.isUserConfirmed == true ? Icons.verified : Icons.live_tv, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Predicted best match', style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w900)),
                          const SizedBox(height: 4),
                          Text(widget.fixture!.title, style: const TextStyle(fontWeight: FontWeight.w800)),
                          Text(
                            aggregate?.isUserConfirmed == true
                                ? 'Confirmed by ${aggregate!.confirmedCount} comment${aggregate.confirmedCount == 1 ? '' : 's'}'
                                : 'Match fit: $broadcastScore%',
                            style: TextStyle(color: muted, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 18),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Experience', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 12),
                  MetricBar(label: 'Screen quality', value: screenQuality, trailing: '$screenQuality%'),
                  MetricBar(label: 'Crowd level', value: crowdLevel, trailing: '$crowdLevel%'),
                  MetricBar(label: 'Typical noise', value: noiseDb, trailing: '$noiseDb dB'),
                  MetricBar(label: 'Food rating', value: foodScore, trailing: '$foodScore%'),
                ],
              ),
            ),
          ),
          if (widget.fixture != null) ...[
            const SizedBox(height: 18),
            _ReportSummaryCard(
              aggregate: aggregate,
              loading: _loadingReports,
              message: _reportMessage,
              onReport: _openReportSheet,
            ),
          ],
          const SizedBox(height: 28),
          FilledButton.icon(
            icon: const Icon(Icons.bookmark_add_outlined),
            label: Text(widget.fixture == null ? 'Add to My Nights' : 'Add ${widget.fixture!.title} to My Nights'),
            onPressed: widget.onStartMatchMode,
          ),
        ],
      ),
    );
  }
}

class _ReportSummaryCard extends StatelessWidget {
  const _ReportSummaryCard({required this.aggregate, required this.loading, required this.message, required this.onReport});

  final VenueReportAggregate? aggregate;
  final bool loading;
  final String? message;
  final VoidCallback onReport;

  @override
  Widget build(BuildContext context) {
    final muted = AppTheme.subtleText(context);
    final count = aggregate?.reportCount ?? 0;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.how_to_vote, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 10),
                Expanded(child: Text('Comments', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900))),
                if (loading) const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              count == 0
                  ? 'No comments yet. Be the first to confirm what this pub is showing.'
                  : '${aggregate!.statusLabel} • $count comment${count == 1 ? '' : 's'}',
              style: TextStyle(color: muted, height: 1.35),
            ),
            if ((aggregate?.latestNote ?? '').trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Latest note: “${aggregate!.latestNote}”', style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.add_comment),
                label: const Text('Add comment'),
                onPressed: onReport,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReportSheet extends StatefulWidget {
  const _ReportSheet({required this.pub, required this.fixture, required this.user});

  final PubSpot pub;
  final MatchFixture fixture;
  final AppUser user;

  @override
  State<_ReportSheet> createState() => _ReportSheetState();
}

class _ReportSheetState extends State<_ReportSheet> {
  bool _isShowing = true;
  double _screenQuality = 80;
  double _crowdLevel = 60;
  double _noiseDb = 65;
  double _foodScore = 70;
  final Set<String> _tags = {'Would return'};
  final TextEditingController _noteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _screenQuality = widget.pub.screenQuality.toDouble();
    _crowdLevel = widget.pub.crowdLevel.toDouble();
    _noiseDb = widget.pub.noiseDb.toDouble();
    _foodScore = widget.pub.foodScore.toDouble();
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  VenueReport _buildReport() {
    return VenueReport(
      userId: widget.user.id,
      userDisplayName: widget.user.displayName,
      pubId: widget.pub.id,
      pubName: widget.pub.name,
      fixtureId: widget.fixture.id,
      fixtureTitle: widget.fixture.title,
      isShowingMatch: _isShowing,
      screenQuality: _screenQuality.round(),
      crowdLevel: _crowdLevel.round(),
      noiseDb: _noiseDb.round(),
      foodScore: _foodScore.round(),
      tags: _tags.toList(),
      note: _noteController.text.trim(),
      createdAt: DateTime.now(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final muted = AppTheme.subtleText(context);
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 18,
          right: 18,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 18,
        ),
        child: ListView(
          shrinkWrap: true,
          children: [
            Text('Add comment', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 6),
            Text('${widget.pub.name} • ${widget.fixture.title}', style: TextStyle(color: muted)),
            const SizedBox(height: 16),
            SwitchListTile(
              value: _isShowing,
              onChanged: (value) => setState(() => _isShowing = value),
              title: const Text('This pub is showing this match'),
              subtitle: const Text('Help other fans choose the right pub.'),
              contentPadding: EdgeInsets.zero,
            ),
            _SliderRow(label: 'Screen quality', value: _screenQuality, min: 0, max: 100, suffix: '%', onChanged: (value) => setState(() => _screenQuality = value)),
            _SliderRow(label: 'Crowd level', value: _crowdLevel, min: 0, max: 100, suffix: '%', onChanged: (value) => setState(() => _crowdLevel = value)),
            _SliderRow(label: 'Noise', value: _noiseDb, min: 40, max: 95, suffix: ' dB', onChanged: (value) => setState(() => _noiseDb = value)),
            _SliderRow(label: 'Food rating', value: _foodScore, min: 0, max: 100, suffix: '%', onChanged: (value) => setState(() => _foodScore = value)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ['Good atmosphere', 'Calm corner', 'Solo-friendly', 'Food first', 'Would return'].map((tag) {
                final selected = _tags.contains(tag);
                return FilterChip(
                  label: Text(tag),
                  selected: selected,
                  onSelected: (value) => setState(() {
                    if (value) {
                      _tags.add(tag);
                    } else {
                      _tags.remove(tag);
                    }
                  }),
                );
              }).toList(),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _noteController,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(hintText: 'Optional note: screens, crowd, queue, safety, food...'),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              icon: const Icon(Icons.send),
              label: const Text('Submit comment'),
              onPressed: () => Navigator.of(context).pop(_buildReport()),
            ),
          ],
        ),
      ),
    );
  }
}

class _SliderRow extends StatelessWidget {
  const _SliderRow({required this.label, required this.value, required this.min, required this.max, required this.suffix, required this.onChanged});

  final String label;
  final double value;
  final double min;
  final double max;
  final String suffix;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700))),
            Text('${value.round()}$suffix'),
          ],
        ),
        Slider(value: value, min: min, max: max, divisions: (max - min).round(), onChanged: onChanged),
      ],
    );
  }
}
