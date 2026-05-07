import 'package:flutter/material.dart';
import '../models/check_in.dart';
import '../models/match_fixture.dart';
import '../models/pub_spot.dart';
import '../services/mock_sensor_service.dart';
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
  final ValueChanged<CheckIn> onSave;

  @override
  State<MatchModeScreen> createState() => _MatchModeScreenState();
}

class _MatchModeScreenState extends State<MatchModeScreen> {
  final MockSensorService _sensorService = MockSensorService();
  int _noiseDb = 0;
  bool _sampling = false;
  String _mood = 'Good atmosphere';
  final TextEditingController _noteController = TextEditingController();

  Future<void> _sampleNoise() async {
    setState(() => _sampling = true);
    final value = await _sensorService.sampleNoiseDb(baseline: widget.pub.noiseDb);
    if (!mounted) return;
    setState(() {
      _noiseDb = value;
      _sampling = false;
    });
  }

  void _save() {
    widget.onSave(CheckIn(
      pubName: widget.pub.name,
      matchTitle: widget.fixture.title,
      timestamp: DateTime.now(),
      mood: _mood,
      noiseDb: _noiseDb == 0 ? widget.pub.noiseDb : _noiseDb,
      note: _noteController.text.trim().isEmpty ? 'No note added.' : _noteController.text.trim(),
    ));
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Match night saved to My Nights')));
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _noteController.dispose();
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
                  Text(_noiseDb == 0 ? 'Typical venue noise estimate' : 'Latest match-mode sample', style: TextStyle(color: muted)),
                  const SizedBox(height: 18),
                  MetricBar(label: 'Atmosphere intensity', value: liveNoise, trailing: liveNoise > 72 ? 'loud' : 'comfortable'),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      icon: _sampling ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.mic),
                      label: Text(_sampling ? 'Sampling atmosphere...' : 'Sample noise level'),
                      onPressed: _sampling ? null : _sampleNoise,
                    ),
                  ),
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
            children: ['Great crowd', 'Good atmosphere', 'Too loud', 'Perfect for solo', 'Would return'].map((mood) {
              return ChoiceChip(label: Text(mood), selected: _mood == mood, onSelected: (_) => setState(() => _mood = mood));
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
          Text('V0.2 still uses a mock sensor sampler. V0.3 will replace this with Android microphone amplitude once device permissions are configured.', style: TextStyle(color: muted, fontSize: 12, height: 1.35)),
        ],
      ),
    );
  }
}
