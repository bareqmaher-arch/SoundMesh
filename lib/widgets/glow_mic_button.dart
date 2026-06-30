import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

/// زر المايك الكبير المتوهّج (اضغط للتحدّث) مع حلقات نبض عند التحدّث.
class GlowMicButton extends StatefulWidget {
  final bool active;
  final double level;
  final VoidCallback? onTapDown;
  final VoidCallback? onTapUp;
  final double size;

  const GlowMicButton({
    super.key,
    required this.active,
    this.level = 0,
    this.onTapDown,
    this.onTapUp,
    this.size = 86,
  });

  @override
  State<GlowMicButton> createState() => _GlowMicButtonState();
}

class _GlowMicButtonState extends State<GlowMicButton>
    with TickerProviderStateMixin {
  late final AnimationController _pulse;
  late final AnimationController _press;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1500))
      ..repeat();
    _press = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 160),
      lowerBound: 0.9,
      upperBound: 1.0,
      value: 1.0,
    );
  }

  @override
  void dispose() {
    _pulse.dispose();
    _press.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size;
    return GestureDetector(
      onTapDown: (_) {
        _press.animateTo(0.9);
        widget.onTapDown?.call();
      },
      onTapUp: (_) {
        _press.animateTo(1.0);
        widget.onTapUp?.call();
      },
      onTapCancel: () {
        _press.animateTo(1.0);
        widget.onTapUp?.call();
      },
      child: SizedBox(
        width: size * 1.9,
        height: size * 1.9,
        child: AnimatedBuilder(
          animation: Listenable.merge([_pulse, _press]),
          builder: (context, child) {
            return Stack(
              alignment: Alignment.center,
              children: [
                if (widget.active) ..._rings(size),
                Transform.scale(scale: _press.value, child: child),
              ],
            );
          },
          child: _core(size),
        ),
      ),
    );
  }

  List<Widget> _rings(double size) {
    final rings = <Widget>[];
    for (int i = 0; i < 3; i++) {
      final t = (_pulse.value + i / 3) % 1.0;
      final scale = 1.0 + t * 0.9 + widget.level * 0.4;
      final opacity = (1.0 - t) * 0.4;
      rings.add(Container(
        width: size * scale,
        height: size * scale,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.violet.withValues(alpha: opacity.clamp(0, 1)),
        ),
      ));
    }
    return rings;
  }

  Widget _core(double size) {
    final glow = widget.active ? 0.6 + widget.level * 0.4 : 0.4;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: AppColors.brand,
        boxShadow: [
          BoxShadow(
            color: AppColors.violet.withValues(alpha: glow.clamp(0, 1)),
            blurRadius: 30 + widget.level * 26,
            spreadRadius: 2 + widget.level * 6,
          ),
        ],
      ),
      child: Icon(Icons.mic_rounded, color: Colors.white, size: size * 0.42),
    );
  }
}
