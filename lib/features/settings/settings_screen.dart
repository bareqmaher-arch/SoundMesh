import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/i18n/app_text.dart';
import '../../core/settings_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/glass.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  static const _githubUrl = 'https://github.com/bareqmaher-arch';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(appTextProvider);
    final settings = ref.watch(settingsControllerProvider);
    final ctrl = ref.read(settingsControllerProvider.notifier);
    final p = context.palette;

    return Scaffold(
      appBar: AppBar(title: Text(t.settings)),
      body: AuroraBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
            children: [
              _section(p, t.appearance),
              GlassCard(
                child: Column(
                  children: [
                    _rowLabel(p, Icons.brightness_6_rounded, t.theme),
                    const SizedBox(height: 12),
                    _segmented(
                      context: context,
                      options: [
                        (_ThemeOpt.dark, Icons.dark_mode_rounded, t.darkMode),
                        (_ThemeOpt.light, Icons.light_mode_rounded, t.lightMode),
                        (_ThemeOpt.system, Icons.smartphone_rounded, t.systemMode),
                      ],
                      selected: _ThemeOpt.fromMode(settings.themeMode),
                      onSelect: (o) => ctrl.setTheme(o.toMode()),
                    ),
                    const Divider(height: 28),
                    _rowLabel(p, Icons.translate_rounded, t.language),
                    const SizedBox(height: 12),
                    _segmented(
                      context: context,
                      options: [
                        ('en', Icons.abc_rounded, t.english),
                        ('ar', Icons.language_rounded, t.arabic),
                      ],
                      selected: settings.localeCode,
                      onSelect: (c) => ctrl.setLocale(c),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _section(p, t.permissionsTitle),
              GlassCard(
                onTap: () => context.push('/gate'),
                child: Row(
                  children: [
                    const _IconBadge(
                        icon: Icons.verified_user_rounded,
                        color: AppColors.online),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(t.openPermissions,
                          style: TextStyle(
                              color: p.text, fontWeight: FontWeight.w600)),
                    ),
                    Icon(Icons.chevron_right_rounded, color: p.textDim),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _section(p, t.aboutApp),
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const _IconBadge(
                            icon: Icons.graphic_eq_rounded,
                            color: AppColors.cyan),
                        const SizedBox(width: 14),
                        ShaderMask(
                          shaderCallback: (r) =>
                              AppColors.brand.createShader(r),
                          child: const Text('SoundMesh',
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(t.aboutAppBody,
                        style: TextStyle(
                            color: p.textDim, height: 1.5, fontSize: 13)),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _credits(context, t, p),
            ],
          ),
        ),
      ),
    );
  }

  Widget _credits(BuildContext context, AppText t, AppPalette p) {
    return Center(
      child: Column(
        children: [
          Text(t.designedBy,
              style: TextStyle(color: p.textDim, fontSize: 12)),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: () async {
              final uri = Uri.parse(_githubUrl);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            },
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(colors: [
                  AppColors.cyan.withValues(alpha: 0.18),
                  AppColors.magenta.withValues(alpha: 0.18),
                ]),
                border: Border.all(color: p.border),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.code_rounded,
                      color: AppColors.cyan, size: 18),
                  const SizedBox(width: 8),
                  ShaderMask(
                    shaderCallback: (r) => AppColors.brand.createShader(r),
                    child: Text(t.designerName,
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Colors.white)),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.open_in_new_rounded,
                      color: AppColors.magenta, size: 15),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(_githubUrl,
              style: TextStyle(color: p.textDim, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _section(AppPalette p, String title) => Padding(
        padding: const EdgeInsetsDirectional.only(start: 6, bottom: 10, top: 4),
        child: Align(
          alignment: AlignmentDirectional.centerStart,
          child: Text(title,
              style: TextStyle(
                  color: p.textDim,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  letterSpacing: 0.5)),
        ),
      );

  Widget _rowLabel(AppPalette p, IconData icon, String label) => Row(
        children: [
          Icon(icon, color: p.textDim, size: 20),
          const SizedBox(width: 10),
          Text(label,
              style: TextStyle(color: p.text, fontWeight: FontWeight.w600)),
        ],
      );

  Widget _segmented<T>({
    required BuildContext context,
    required List<(T, IconData, String)> options,
    required T selected,
    required ValueChanged<T> onSelect,
  }) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: p.glass,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: p.border),
      ),
      child: Row(
        children: options.map((o) {
          final sel = o.$1 == selected;
          return Expanded(
            child: GestureDetector(
              onTap: () => onSelect(o.$1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  gradient: sel ? AppColors.brand : null,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Icon(o.$2,
                        size: 20,
                        color: sel ? Colors.white : p.textDim),
                    const SizedBox(height: 4),
                    Text(o.$3,
                        style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: sel ? Colors.white : p.textDim)),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

enum _ThemeOpt {
  dark,
  light,
  system;

  static _ThemeOpt fromMode(ThemeMode m) => switch (m) {
        ThemeMode.light => _ThemeOpt.light,
        ThemeMode.system => _ThemeOpt.system,
        _ => _ThemeOpt.dark,
      };

  ThemeMode toMode() => switch (this) {
        _ThemeOpt.light => ThemeMode.light,
        _ThemeOpt.system => ThemeMode.system,
        _ThemeOpt.dark => ThemeMode.dark,
      };
}

class _IconBadge extends StatelessWidget {
  final IconData icon;
  final Color color;
  const _IconBadge({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(
          color: color.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(14)),
      child: Icon(icon, color: color, size: 22),
    );
  }
}
