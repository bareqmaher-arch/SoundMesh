import 'dart:io';

import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

/// أفاتار دائري يدعم صورة محلية أو أفاتار افتراضي (تدرّج لوني + حرف).
class AppAvatar extends StatelessWidget {
  final String? imagePath;
  final int defaultAvatar;
  final String name;
  final double size;
  final bool ring;
  final Color ringColor;

  const AppAvatar({
    super.key,
    this.imagePath,
    this.defaultAvatar = 0,
    this.name = '',
    this.size = 56,
    this.ring = false,
    this.ringColor = AppColors.cyan,
  });

  static const List<List<Color>> _palettes = [
    [Color(0xFF22D3EE), Color(0xFF6366F1)],
    [Color(0xFF8B5CF6), Color(0xFFD946EF)],
    [Color(0xFF34D399), Color(0xFF06B6D4)],
    [Color(0xFFF472B6), Color(0xFF8B5CF6)],
    [Color(0xFF38BDF8), Color(0xFF818CF8)],
  ];

  @override
  Widget build(BuildContext context) {
    final hasImage = imagePath != null &&
        imagePath!.isNotEmpty &&
        File(imagePath!).existsSync();

    final palette = _palettes[defaultAvatar % _palettes.length];
    final initial = name.isNotEmpty ? name.characters.first.toUpperCase() : '?';

    Widget inner;
    if (hasImage) {
      inner = ClipOval(
        child: Image.file(
          File(imagePath!),
          width: size,
          height: size,
          fit: BoxFit.cover,
        ),
      );
    } else {
      inner = Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: palette,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          initial,
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.4,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    }

    if (!ring) return inner;

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: ringColor, width: 2.5),
      ),
      child: inner,
    );
  }
}
