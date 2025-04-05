import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animations/models/model_glow_points.dart';

class ScreenGlowEffect extends StatefulWidget {
  const ScreenGlowEffect({super.key});

  @override
  State<ScreenGlowEffect> createState() => _ScreenGlowEffectState();
}

class _ScreenGlowEffectState extends State<ScreenGlowEffect> {
  List<ModelGlowPoints> points = [];
  late Timer timer;
  double time = 0;

  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(Duration(milliseconds: 16), (timer) {
      setState(() {
        time = DateTime.now().millisecondsSinceEpoch / 1000.0;
        points.removeWhere((point) => time - point.creationTime > 3);
      });
    });
  }

  @override
  void dispose() {
    timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: (details) {
        setState(() {
          points.add(ModelGlowPoints(details.localPosition, time));
          if (points.length > 100) {
            points.removeAt(0);
          }
        });
      },
      child: Scaffold(body: CustomPaint(painter: GlowPointer(points, time), size: Size.infinite)),
    );
  }
}

class GlowPointer extends CustomPainter {
  GlowPointer(this.points, this.time);

  final List<ModelGlowPoints> points;
  final double time;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..maskFilter = MaskFilter.blur(BlurStyle.normal, 30);

    for (var point in points) {
      double age = time - point.creationTime;
      double opacity = (1 - age / 3).clamp(0, 1);
      double radius = (40 - age * 10).clamp(1, 40);

      paint.color = HSVColor.fromAHSV(1, (age * 360) % 360, 1, 1).toColor().withValues(alpha: opacity);
      canvas.drawCircle(point.position, radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
