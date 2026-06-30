import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import 'app_avatar.dart';

/// أفاتار مع حلقات نبض متحركة عند التحدّث + اسم أسفله.
/// تظهر نفس الحالة لدى الجميع (يُمرَّر [speaking] حسب من يتكلّم فعلاً).
class SpeakingAvatar extends StatefulWidget {
  final String? imagePath;
  final int defaultAvatar;
  final String name;
  final double size;
  final bool speaking;
  final bool isMe;
  final bool showName;

  const SpeakingAvatar({
    super.key,
    this.imagePath,
    this.defaultAvatar = 0,
    required this.name,
    this.size = 56,
    this.speaking = false,
    this.isMe = false,
    this.showName = true,
  });

  @override
  State<SpeakingAvatar> createState() => _SpeakingAvatarState();
}

class _SpeakingAvatarState extends State<SpeakingAvatar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1400));
    if (widget.speaking) _c.repeat();
  }

  @override
  void didUpdateWidget(covariant SpeakingAvatar old) {
    super.didUpdateWidget(old);
    if (widget.speaking && !_c.isAnimating) {
      _c.repeat();
    } else if (!widget.speaking && _c.isAnimating) {
      _c.stop();
      _c.value = 0;
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size;
    final p = context.palette;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size * 1.55,
          height: size * 1.55,
          child: AnimatedBuilder(
            animation: _c,
            builder: (context, child) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  if (widget.speaking) ..._rings(size),
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: widget.speaking
                          ? [
                              BoxShadow(
                                color:
                                    AppColors.cyan.withValues(alpha: 0.6),
                                blurRadius: 22,
                                spreadRadius: 2,
                              ),
                            ]
                          : null,
                    ),
                    child: child,
                  ),
                ],
              );
            },
            child: AppAvatar(
              imagePath: widget.imagePath,
              defaultAvatar: widget.defaultAvatar,
              name: widget.name,
              size: size,
              ring: widget.speaking,
              ringColor: AppColors.cyan,
            ),
          ),
        ),
        if (widget.showName)
          SizedBox(
            width: size * 1.55,
            child: Text(
              widget.isMe ? widget.name : widget.name,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight:
                    widget.speaking ? FontWeight.w700 : FontWeight.w500,
                color: widget.speaking ? AppColors.cyan : p.textDim,
              ),
            ),
          ),
      ],
    );
  }

  List<Widget> _rings(double size) {
    final rings = <Widget>[];
    for (int i = 0; i < 3; i++) {
      final t = (_c.value + i / 3) % 1.0;
      final scale = 1.0 + t * 0.55;
      final opacity = (1.0 - t) * 0.5;
      rings.add(
        Container(
          width: size * scale,
          height: size * scale,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.cyan.withValues(alpha: opacity.clamp(0, 1)),
              width: 1.5,
            ),
          ),
        ),
      );
    }
    return rings;
  }
}
