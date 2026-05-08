import 'dart:async';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

class NoiseSample {
  const NoiseSample({required this.db, required this.source, required this.message});

  final int db;
  final String source;
  final String message;
}

class LiveAudioService {
  final AudioRecorder _recorder = AudioRecorder();

  Future<NoiseSample> sampleNoiseDb({int fallback = 66}) async {
    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) {
      return NoiseSample(
        db: fallback,
        source: 'permission-denied',
        message: 'Microphone permission was not granted. MatchPint used this venue’s typical noise estimate instead.',
      );
    }

    final tempDir = await getTemporaryDirectory();
    final path = '${tempDir.path}/matchpint_noise_${DateTime.now().millisecondsSinceEpoch}.m4a';
    final values = <int>[];

    try {
      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          sampleRate: 22050,
          numChannels: 1,
          autoGain: false,
          echoCancel: false,
          noiseSuppress: false,
        ),
        path: path,
      );

      for (var i = 0; i < 6; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 220));
        final amplitude = await _recorder.getAmplitude();
        values.add(_amplitudeToApproxDb(amplitude.current));
      }
    } finally {
      if (await _recorder.isRecording()) {
        await _recorder.stop();
      }
      unawaited(_deleteQuietly(path));
    }

    if (values.isEmpty) {
      return NoiseSample(
        db: fallback,
        source: 'fallback',
        message: 'No microphone amplitude was captured. MatchPint used this venue’s typical noise estimate instead.',
      );
    }

    values.sort();
    final middle = values.length ~/ 2;
    final median = values.length.isOdd ? values[middle] : ((values[middle - 1] + values[middle]) / 2).round();
    return NoiseSample(
      db: median,
      source: 'microphone',
      message: 'Live microphone estimate. MatchPint deletes the temporary audio file and stores only this dB estimate.',
    );
  }

  int _amplitudeToApproxDb(double current) {
    if (!current.isFinite) return 60;
    // record returns a dBFS-style amplitude where very quiet values are far below 0.
    // This converts it into an approximate venue noise range for user feedback.
    final normalized = ((current + 55.0) / 55.0).clamp(0.0, 1.0);
    final db = (38 + normalized * 52).round();
    return db.clamp(35, 96).toInt();
  }

  Future<void> _deleteQuietly(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) await file.delete();
    } catch (_) {
      // Ignore temporary file cleanup failures.
    }
  }

  Future<void> dispose() => _recorder.dispose();
}
