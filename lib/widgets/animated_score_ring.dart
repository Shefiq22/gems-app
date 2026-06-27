import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;

class AnimatedScoreRing extends StatefulWidget {
  final double score;
  final double size;
  const AnimatedScoreRing({super.key, required this.score, this.size = 120});

  @override
  State<AnimatedScoreRing> createState() => _AnimatedScoreRingState();
}

class _AnimatedScoreRingState extends State<AnimatedScoreRing>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1400));
    _anim = Tween<double>(begin: 0, end: widget.score / 100).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => SizedBox(
        width: widget.size,
        height: widget.size,
        child: CustomPaint(
          painter: _RingPainter(progress: _anim.value),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  (widget.score * _anim.value / (widget.score / 100 == 0 ? 1 : widget.score / 100))
                      .toStringAsFixed(0),
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: widget.size * 0.24,
                    fontWeight: FontWeight.w800,
                    height: 1,
                  ),
                ),
                Text('/ 100',
                    style: GoogleFonts.poppins(
                        color: Colors.white60,
                        fontSize: widget.size * 0.1)),
                Text('GHI',
                    style: GoogleFonts.poppins(
                        color: Colors.white38,
                        fontSize: widget.size * 0.09,
                        letterSpacing: 1.5)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  const _RingPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center  = Offset(size.width / 2, size.height / 2);
    final radius  = size.width * 0.44;
    final strokeW = size.width * 0.08;

    // Background ring
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = Colors.white.withOpacity(0.12)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeW,
    );

    // Progress arc
    final rect  = Rect.fromCircle(center: center, radius: radius);
    final paint = Paint()
      ..shader = const SweepGradient(
        startAngle: -math.pi / 2,
        endAngle:    3 * math.pi / 2,
        colors: [Color(0xFF69F0AE), Color(0xFF00BFA5)],
        stops: [0.0, 1.0],
      ).createShader(rect)
      ..style      = PaintingStyle.stroke
      ..strokeWidth = strokeW
      ..strokeCap  = StrokeCap.round;

    canvas.drawArc(
        rect, -math.pi / 2, progress * 2 * math.pi, false, paint);

    // Glowing dot at tip
    if (progress > 0.01) {
      final angle = -math.pi / 2 + progress * 2 * math.pi;
      final dotX  = center.dx + radius * math.cos(angle);
      final dotY  = center.dy + radius * math.sin(angle);
      canvas.drawCircle(
        Offset(dotX, dotY),
        strokeW / 2 + 1,
        Paint()
          ..color = const Color(0xFF69F0AE)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.progress != progress;
}