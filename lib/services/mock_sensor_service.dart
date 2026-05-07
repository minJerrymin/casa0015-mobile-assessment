import 'dart:math';

class MockSensorService {
  final Random _random = Random();

  Future<int> sampleNoiseDb({int baseline = 66}) async {
    await Future<void>.delayed(const Duration(milliseconds: 450));
    final swing = _random.nextInt(22) - 9;
    return (baseline + swing).clamp(38, 95);
  }

  Future<String> estimateLocationLabel() async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return 'Central London';
  }
}
