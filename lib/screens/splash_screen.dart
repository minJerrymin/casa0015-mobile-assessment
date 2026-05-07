import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/matchpint_logo.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, required this.onFinished});

  final VoidCallback onFinished;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600));
    _scale = CurvedAnimation(parent: _controller, curve: Curves.easeOutBack);
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();
    Future<void>.delayed(const Duration(milliseconds: 2200), widget.onFinished);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.pitchBlack,
      body: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: _PitchLinesPainter())),
          Center(
            child: FadeTransition(
              opacity: _fade,
              child: ScaleTransition(
                scale: _scale,
                child: const MatchPintLogo(size: 132),
              ),
            ),
          ),
          const Positioned(
            bottom: 44,
            left: 0,
            right: 0,
            child: Center(
              child: Text('match night starts here', style: TextStyle(color: AppTheme.muted, letterSpacing: 1.4)),
            ),
          ),
        ],
      ),
    );
  }
}

class _PitchLinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.pitchGreen.withOpacity(0.08)
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;
    canvas.drawRect(Rect.fromLTWH(28, 92, size.width - 56, size.height - 184), paint);
    canvas.drawLine(Offset(size.width / 2, 92), Offset(size.width / 2, size.height - 92), paint);
    canvas.drawCircle(Offset(size.width / 2, size.height / 2), 68, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
