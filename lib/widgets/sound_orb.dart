import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

/// كرة صوتية متوهّجة متحركة — تتفاعل مع مستوى الصوت وحالة التحدّث.
/// تظهر نفس الحركة لدى الجميع عبر تمرير [active] و[level].
class SoundOrb extends StatefulWidget {
  final double size;
  final bool active; // يتحدّث أحدٌ ما الآن
  final double level; // 0..1 مستوى الصوت

  const SoundOrb({
    super.key,
    this.size = 220,
    this.active = false,
    this.level = 0,
  });

  @override
  State<SoundOrb> createState() => _SoundOrbState();
}

class _SoundOrbState extends State<SoundOrb> with TickerProviderStateMixin {
  late final AnimationController _spin;
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _spin = AnimationController(
        vsync: this, duration: const Duration(seconds: 12))
      ..repeat();
    _pulse = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2600))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _spin.dispose();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.size;
    return SizedBox(
      width: s * 1.5,
      height: s * 1.5,
      child: AnimatedBuilder(
        animation: Listenable.merge([_spin, _pulse]),
        builder: (context, _) {
          final breathe = 0.96 + _pulse.value * 0.04;
          final lvl = widget.active ? (0.25 + widget.level) : 0.0;
          return Stack(
            alignment: Alignment.center,
            children: [
              // حلقات نبض خارجية عند التحدّث.
              if (widget.active)
                for (int i = 0; i < 3; i++)
                  _ring(s, (_pulse.value + i / 3) % 1.0, lvl),
              // الهالة.
              Container(
                width: s * (1.05 + lvl * 0.15),
                height: s * (1.05 + lvl * 0.15),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.violet
                          .withValues(alpha: 0.35 + lvl * 0.35),
                      blurRadius: 60,
                      spreadRadius: 6 + lvl * 14,
                    ),
                    BoxShadow(
                      color: AppColors.cyan.withValues(alpha: 0.18 + lvl * 0.2),
                      blurRadius: 40,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
              // الكرة الأساسية.
              Transform.scale(
                scale: breathe * (1 + lvl * 0.05),
                child: Container(
                  width: s,
                  height: s,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppColors.orb,
                  ),
                  child: CustomPaint(
                    painter: _OrbPainter(_spin.value, lvl),
                  ),
                ),
              ),
              // لمعة علوية.
              Align(
                alignment: const Alignment(-0.35, -0.4),
                child: Container(
                  width: s * 0.3,
                  height: s * 0.22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(colors: [
                      Colors.white.withValues(alpha: 0.5),
                      Colors.white.withValues(alpha: 0),
                    ]),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _ring(double s, double t, double lvl) {
    return Container(
      width: s * (1.0 + t * (0.6 + lvl)),
      height: s * (1.0 + t * (0.6 + lvl)),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.cyan.withValues(alpha: (1 - t) * 0.5),
          width: 1.5,
        ),
      ),
    );
  }
}

class _OrbPainter extends CustomPainter {
  final double spin;
  final double level;
  _OrbPainter(this.spin, this.level);

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final r = size.width / 2;
    // خطوط طاقة منحنية داخل الكرة.
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < 5; i++) {
      final phase = spin * 2 * math.pi + i * 0.8;
      paint.color = (i.isEven ? AppColors.cyan : AppColors.magenta)
          .withValues(alpha: 0.35 + level * 0.3);
      final path = Path();
      for (double a = 0; a <= math.pi * 2; a += 0.18) {
        final wobble = math.sin(a * 3 + phase) * (0.12 + level * 0.18);
        final rr = r * (0.55 + wobble) * (0.7 + i * 0.07);
        final x = center.dx + rr * math.cos(a);
        final y = center.dy + rr * math.sin(a) * 0.6;
        if (a == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      path.close();
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _OrbPainter old) =>
      old.spin != spin || old.level != level;
}
