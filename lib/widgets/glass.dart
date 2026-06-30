import 'dart:ui';

import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_theme.dart';

/// بطاقة/حاوية زجاجية (glassmorphism) متوافقة مع الثيم الحالي.
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final double blur;
  final VoidCallback? onTap;
  final bool strong;
  final Gradient? glowBorder;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.radius = AppRadii.lg,
    this.blur = 18,
    this.onTap,
    this.strong = false,
    this.glowBorder,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final border = glowBorder;
    final content = ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: strong ? p.glassStrong : p.glass,
            borderRadius: BorderRadius.circular(radius),
            border: border == null
                ? Border.all(color: p.border, width: 1)
                : null,
          ),
          child: child,
        ),
      ),
    );

    final wrapped = border == null
        ? content
        : Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(radius),
              gradient: border,
            ),
            padding: const EdgeInsets.all(1.2),
            child: content,
          );

    final card = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: p.isDark
            ? null
            : [
                BoxShadow(
                  color: const Color(0xFF101935).withValues(alpha: 0.06),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
      ),
      child: wrapped,
    );

    if (onTap == null) return card;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(radius),
      child: card,
    );
  }
}

/// خلفية متدرّجة داكنة مع توهّجات نيون خفيفة (مشهد المستقبل).
class AuroraBackground extends StatelessWidget {
  final Widget child;
  const AuroraBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Stack(
      children: [
        Positioned.fill(child: ColoredBox(color: p.bg)),
        if (p.isDark) ...[
          _blob(const Alignment(-1.1, -1.0), AppColors.violet, 320, 0.30),
          _blob(const Alignment(1.2, -0.6), AppColors.cyan, 300, 0.22),
          _blob(const Alignment(0.9, 1.1), AppColors.magenta, 320, 0.20),
        ] else ...[
          _blob(const Alignment(-1.1, -1.0), AppColors.cyan, 300, 0.16),
          _blob(const Alignment(1.2, -0.7), AppColors.violet, 280, 0.14),
        ],
        Positioned.fill(child: child),
      ],
    );
  }

  Widget _blob(Alignment a, Color c, double size, double opacity) {
    return Align(
      alignment: a,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [c.withValues(alpha: opacity), c.withValues(alpha: 0)],
          ),
        ),
      ),
    );
  }
}
