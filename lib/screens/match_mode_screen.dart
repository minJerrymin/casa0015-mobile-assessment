import 'package:flutter/material.dart';
import '../models/check_in.dart';
import '../models/match_fixture.dart';
import '../models/pub_spot.dart';
import '../services/live_audio_service.dart';
import '../theme/app_theme.dart';
import '../widgets/metric_bar.dart';

class MatchModeScreen extends StatefulWidget {
  const MatchModeScreen({
    super.key,
    required this.pub,
    required this.fixture,
    required this.onSave,
  });

  final PubSpot pub;
  final MatchFixture fixture;
  final Future<void> Function(CheckIn entry) onSave;

  @override
  State<MatchModeScreen> createState() => _MatchModeScreenState();
}

class _MatchModeScreenState extends State<MatchModeScreen> {
  final LiveAudioService _audioService = LiveAudioService();
  int _noiseDb = 0;
  bool _sampling = false;
  String _sampleMessage = 'Tap the microphone button to take a live dB sample. No audio is saved.';
  final Set<String> _selectedTags = {'Good atmosphere'};
  final TextEditingController _noteController = TextEditingController();

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

  Future<void> _save() async {
    await widget.onSave(CheckIn(
      pubName: widget.pub.name,
      matchTitle: widget.fixture.title,
      timestamp: DateTime.now(),
      mood: _selectedTags.isEmpty ? 'No tags selected' : _selectedTags.join(', '),
      noiseDb: _noiseDb == 0 ? widget.pub.noiseDb : _noiseDb,
      note: _noteController.text.trim().isEmpty ? 'No note added.' : _noteController.text.trim(),
    ));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Match night saved to My Nights')));
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
          FilledButton.icon(icon: const Icon(Icons.bookmark_add), label: const Text('Save match night'), onPressed: _save),
          const SizedBox(height: 8),
          Text('Privacy note: MatchPint uses the microphone only for a short amplitude sample. It deletes the temporary recording and saves only the dB estimate with your match-night note.', style: TextStyle(color: muted, fontSize: 12, height: 1.35)),
        ],
      ),
    );
  }
}
