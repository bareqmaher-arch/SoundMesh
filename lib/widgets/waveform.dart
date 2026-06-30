import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

/// أشرطة موجة صوت متحركة بتدرّج نيون.
class Waveform extends StatefulWidget {
  final bool animating;
  final double level; // 0..1
  final int bars;
  final double height;

  const Waveform({
    super.key,
    this.animating = true,
    this.level = 0.6,
    this.bars = 7,
    this.height = 28,
  });

  @override
  State<Waveform> createState() => _WaveformState();
}

class _WaveformState extends State<Waveform>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 850))
      ..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: List.generate(widget.bars, (i) {
            final phase = i / widget.bars * math.pi * 2;
            final base = widget.animating
                ? (0.35 +
                    0.65 *
                        (0.5 + 0.5 * math.sin(_c.value * 2 * math.pi + phase)))
                : 0.4;
            final h = widget.height * base * (0.55 + widget.level * 0.9);
            return Container(
              width: 4,
              height: h.clamp(5, widget.height),
              margin: const EdgeInsets.symmetric(horizontal: 2.4),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [AppColors.cyan, AppColors.magenta],
                ),
                borderRadius: BorderRadius.circular(4),
              ),
            );
          }),
        );
      },
    );
  }
}
