import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../models/check_in.dart';
import '../models/match_fixture.dart';
import '../models/pub_spot.dart';
import '../models/venue_report.dart';
import '../services/live_audio_service.dart';
import '../services/venue_report_service.dart';
import '../theme/app_theme.dart';
import '../widgets/metric_bar.dart';

class MatchModeScreen extends StatefulWidget {
  const MatchModeScreen({
    super.key,
    required this.pub,
    required this.fixture,
    required this.onSave,
    this.currentUser,
  });

  final PubSpot pub;
  final MatchFixture fixture;
  final AppUser? currentUser;
  final Future<void> Function(CheckIn entry) onSave;

  @override
  State<MatchModeScreen> createState() => _MatchModeScreenState();
}

class _MatchModeScreenState extends State<MatchModeScreen> {
  final LiveAudioService _audioService = LiveAudioService();
  final VenueReportService _reportService = VenueReportService();
  int _noiseDb = 0;
  bool _sampling = false;
  bool _saving = false;
  String _sampleMessage = 'Tap the microphone button to take a live dB sample. No audio is saved.';
  final Set<String> _selectedTags = {'Good atmosphere'};
  final TextEditingController _noteController = TextEditingController();
  double _screenQuality = 80;
  double _crowdLevel = 60;
  double _foodScore = 70;
  bool _isShowingMatch = true;

  @override
  void initState() {
    super.initState();
    _screenQuality = widget.pub.screenQuality.toDouble();
    _crowdLevel = widget.pub.crowdLevel.toDouble();
    _foodScore = widget.pub.foodScore.toDouble();
  }

  Future<void> _sampleNoise() async {
    setState(() {
      _sampling = true;
      _sampleMessage = 'Listening for a short live atmosphere sample...';
    });
    final sample = await _audioService.sampleNoiseDb(fallback: widget.pub.noiseDb);
    if (!mounted) return;
    setState(() {
      _noiseDb = sample.db;
      _sampleMessage = sample.message;
      _sampling = false;
    });
  }

  VenueReport? _buildVenueReport() {
    final user = widget.currentUser;
    if (user == null) return null;
    return VenueReport(
      userId: user.id,
      userDisplayName: user.displayName,
      pubId: widget.pub.id,
      pubName: widget.pub.name,
      fixtureId: widget.fixture.id,
      fixtureTitle: widget.fixture.title,
      isShowingMatch: _isShowingMatch,
      screenQuality: _screenQuality.round(),
      crowdLevel: _crowdLevel.round(),
      noiseDb: _noiseDb == 0 ? widget.pub.noiseDb : _noiseDb,
      foodScore: _foodScore.round(),
      tags: _selectedTags.toList(),
      note: _noteController.text.trim(),
      createdAt: DateTime.now(),
    );
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    final note = _noteController.text.trim();
    await widget.onSave(CheckIn(
      pubName: widget.pub.name,
      matchTitle: widget.fixture.title,
      timestamp: DateTime.now(),
      mood: _selectedTags.isEmpty ? 'No tags selected' : _selectedTags.join(', '),
      noiseDb: _noiseDb == 0 ? widget.pub.noiseDb : _noiseDb,
      note: note.isEmpty ? 'No note added.' : note,
    ));

    final report = _buildVenueReport();
    var reportMessage = 'Match night saved to My Nights.';
    if (report != null) {
      final result = await _reportService.submitReport(report);
      reportMessage = result.error ?? result.message ?? 'Match night saved and comment submitted.';
    }

    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(reportMessage)));
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _noteController.dispose();
    _audioService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final muted = AppTheme.subtleText(context);
    final liveNoise = _noiseDb == 0 ? widget.pub.noiseDb : _noiseDb;
    return Scaffold(
      appBar: AppBar(title: const Text('Match mode')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 120),
        children: [
          Text(widget.fixture.title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text(widget.pub.name, style: TextStyle(color: muted)),
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                children: [
                  Icon(Icons.graphic_eq, size: 54, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(height: 12),
                  Text('$liveNoise dB', style: Theme.of(context).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 6),
                  Text(_noiseDb == 0 ? 'Typical venue noise estimate' : 'Latest live microphone sample', style: TextStyle(color: muted)),
                  const SizedBox(height: 18),
                  MetricBar(label: 'Atmosphere intensity', value: liveNoise, trailing: liveNoise > 72 ? 'loud' : 'comfortable'),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      icon: _sampling ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.mic),
                      label: Text(_sampling ? 'Sampling atmosphere...' : 'Sample live noise'),
                      onPressed: _sampling ? null : _sampleNoise,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(_sampleMessage, textAlign: TextAlign.center, style: TextStyle(color: muted, fontSize: 12, height: 1.35)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 22),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _isShowingMatch,
            onChanged: (value) => setState(() => _isShowingMatch = value),
            title: const Text('This pub is showing this match'),
            subtitle: const Text('Your confirmation helps the next fan choose with confidence.'),
          ),
          const SizedBox(height: 10),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Quick comment', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 10),
                  _SliderRow(label: 'Screen quality', value: _screenQuality, suffix: '%', onChanged: (value) => setState(() => _screenQuality = value)),
                  _SliderRow(label: 'Crowd level', value: _crowdLevel, suffix: '%', onChanged: (value) => setState(() => _crowdLevel = value)),
                  _SliderRow(label: 'Food rating', value: _foodScore, suffix: '%', onChanged: (value) => setState(() => _foodScore = value)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 22),
          Text('How does it feel?', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: ['Great crowd', 'Good atmosphere', 'Too loud', 'Perfect for solo', 'Would return'].map((tag) {
              final selected = _selectedTags.contains(tag);
              return FilterChip(
                label: Text(tag),
                selected: selected,
                onSelected: (value) => setState(() {
                  if (value) {
                    _selectedTags.add(tag);
                  } else {
                    _selectedTags.remove(tag);
                  }
                }),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _noteController,
            minLines: 3,
            maxLines: 5,
            decoration: const InputDecoration(
              hintText: 'Add a quick note about screens, crowd, food, or comfort...',
            ),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            icon: _saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.bookmark_add),
            label: Text(_saving ? 'Saving...' : 'Save match night and comment'),
            onPressed: _saving ? null : _save,
          ),
          const SizedBox(height: 8),
          Text('Privacy note: MatchPint saves your venue comment, match-night tags, and dB estimate. It does not save raw audio.', style: TextStyle(color: muted, fontSize: 12, height: 1.35)),
        ],
      ),
    );
  }
}

class _SliderRow extends StatelessWidget {
  const _SliderRow({required this.label, required this.value, required this.suffix, required this.onChanged});

  final String label;
  final double value;
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
        Slider(value: value, min: 0, max: 100, divisions: 100, onChanged: onChanged),
      ],
    );
  }
}
