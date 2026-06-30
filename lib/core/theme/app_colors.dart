import 'package:flutter/material.dart';

/// هوية لونية مستقبلية: خلفيات داكنة عميقة + تدرّجات سماوي→بنفسجي نيون.
/// مستوحاة من مرجع التصميم (Aiva/SoundMesh) — زجاجية وأنيقة.
class AppColors {
  AppColors._();

  // ===== التدرّجات النيون (الهوية الأساسية) =====
  static const Color cyan = Color(0xFF22D3EE);
  static const Color sky = Color(0xFF3B82F6);
  static const Color violet = Color(0xFF8B5CF6);
  static const Color magenta = Color(0xFFD946EF);
  static const Color pink = Color(0xFFEC4899);

  static const LinearGradient brand = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [cyan, violet, magenta],
  );

  static const LinearGradient brandSoft = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFF38BDF8), Color(0xFF818CF8)],
  );

  static const RadialGradient orb = RadialGradient(
    colors: [Color(0xFF60A5FA), Color(0xFF8B5CF6), Color(0xFFD946EF)],
    stops: [0.0, 0.55, 1.0],
  );

  // ===== الوضع الداكن =====
  static const Color dBg = Color(0xFF080912);
  static const Color dBgElevated = Color(0xFF0F1120);
  static const Color dGlass = Color(0x14FFFFFF); // أبيض 8%
  static const Color dGlassStrong = Color(0x1FFFFFFF); // أبيض 12%
  static const Color dBorder = Color(0x24FFFFFF);
  static const Color dText = Color(0xFFF4F6FF);
  static const Color dTextDim = Color(0xFF9AA0C0);

  // ===== الوضع الفاتح =====
  static const Color lBg = Color(0xFFF3F5FC);
  static const Color lBgElevated = Color(0xFFFFFFFF);
  static const Color lGlass = Color(0xFFFFFFFF);
  static const Color lGlassStrong = Color(0xFFFFFFFF);
  static const Color lBorder = Color(0x14101935);
  static const Color lText = Color(0xFF141833);
  static const Color lTextDim = Color(0xFF6B7194);

  // ===== حالات =====
  static const Color online = Color(0xFF34D399);
  static const Color danger = Color(0xFFFB5E6B);
  static const Color amber = Color(0xFFFBBF24);
}

/// ألوان تابعة للثيم الحالي (تُقرأ من Theme.of(context).extension).
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  final Color bg;
  final Color bgElevated;
  final Color glass;
  final Color glassStrong;
  final Color border;
  final Color text;
  final Color textDim;
  final bool isDark;

  const AppPalette({
    required this.bg,
    required this.bgElevated,
    required this.glass,
    required this.glassStrong,
    required this.border,
    required this.text,
    required this.textDim,
    required this.isDark,
  });

  static const dark = AppPalette(
    bg: AppColors.dBg,
    bgElevated: AppColors.dBgElevated,
    glass: AppColors.dGlass,
    glassStrong: AppColors.dGlassStrong,
    border: AppColors.dBorder,
    text: AppColors.dText,
    textDim: AppColors.dTextDim,
    isDark: true,
  );

  static const light = AppPalette(
    bg: AppColors.lBg,
    bgElevated: AppColors.lBgElevated,
    glass: AppColors.lGlass,
    glassStrong: AppColors.lGlassStrong,
    border: AppColors.lBorder,
    text: AppColors.lText,
    textDim: AppColors.lTextDim,
    isDark: false,
  );

  @override
  AppPalette copyWith({
    Color? bg,
    Color? bgElevated,
    Color? glass,
    Color? glassStrong,
    Color? border,
    Color? text,
    Color? textDim,
    bool? isDark,
  }) =>
      AppPalette(
        bg: bg ?? this.bg,
        bgElevated: bgElevated ?? this.bgElevated,
        glass: glass ?? this.glass,
        glassStrong: glassStrong ?? this.glassStrong,
        border: border ?? this.border,
        text: text ?? this.text,
        textDim: textDim ?? this.textDim,
        isDark: isDark ?? this.isDark,
      );

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    return AppPalette(
      bg: Color.lerp(bg, other.bg, t)!,
      bgElevated: Color.lerp(bgElevated, other.bgElevated, t)!,
      glass: Color.lerp(glass, other.glass, t)!,
      glassStrong: Color.lerp(glassStrong, other.glassStrong, t)!,
      border: Color.lerp(border, other.border, t)!,
      text: Color.lerp(text, other.text, t)!,
      textDim: Color.lerp(textDim, other.textDim, t)!,
      isDark: t < 0.5 ? isDark : other.isDark,
    );
  }
}

/// اختصار للوصول للوحة الألوان الحالية.
extension PaletteX on BuildContext {
  AppPalette get palette =>
      Theme.of(this).extension<AppPalette>() ?? AppPalette.dark;
}
