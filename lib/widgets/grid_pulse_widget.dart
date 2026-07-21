import 'package:flutter/material.dart';
import 'package:zim_tracker/theme/volt_theme.dart';
import 'dart:math' as math;

class GridPulseWidget extends StatefulWidget {
  const GridPulseWidget({super.key});

  @override
  State<GridPulseWidget> createState() => _GridPulseWidgetState();
}

class _GridPulseWidgetState extends State<GridPulseWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 110, // Slightly reduced height
      width: double.infinity,
      decoration: VoltTheme.glassDecoration,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min, // Constrain height
              children: [
                Text(
                  'NATIONAL GRID PULSE',
                  style: VoltTheme.dataStyle.copyWith(fontSize: 8, letterSpacing: 2),
                ),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    '1,240 MW',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'LOAD SHEDDING STAGE 2',
                  style: VoltTheme.dataStyle.copyWith(
                    color: VoltTheme.neonGreen,
                    fontSize: 8,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 100,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return CustomPaint(
                  painter: _PulsePainter(_controller.value),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _PulsePainter extends CustomPainter {
  final double animationValue;
  _PulsePainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = VoltTheme.cyberBlue.withValues(alpha: 0.5)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(0, size.height / 2);

    for (double i = 0; i < size.width; i++) {
      final x = i;
      final y = size.height / 2 + 
          math.sin((i / size.width * 2 * math.pi) + (animationValue * 2 * math.pi)) * 15 * 
          (0.5 + 0.5 * math.sin(animationValue * math.pi));
      path.lineTo(x, y);
    }

    canvas.drawPath(path, paint);

    // Draw glowing point
    final glowPaint = Paint()
      ..color = VoltTheme.cyberBlue
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    
    final headX = size.width * animationValue;
    final headY = size.height / 2 + math.sin((headX / size.width * 2 * math.pi) + (animationValue * 2 * math.pi)) * 15;
    
    canvas.drawCircle(Offset(headX, headY), 4, glowPaint);
    canvas.drawCircle(Offset(headX, headY), 2, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant _PulsePainter oldDelegate) => true;
}
