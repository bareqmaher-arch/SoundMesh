import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/settings_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/gradient_button.dart';
import '../../widgets/glass.dart';
import '../../widgets/sound_orb.dart';

/// شاشة الترحيب المستقبلية مع الكرة المتوهّجة وكاروسيل.
class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> {
  final _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(appTextProvider);
    final p = context.palette;
    final pages = [
      (t.welcomeTitle, t.welcomeBody),
      (t.feature1Title, t.feature1Body),
      (t.feature2Title, t.feature2Body),
    ];

    return Scaffold(
      body: AuroraBackground(
        child: SafeArea(
          child: Column(
            children: [
              const Spacer(flex: 2),
              const SoundOrb(size: 200, active: true, level: 0.35),
              const Spacer(flex: 1),
              Expanded(
                flex: 4,
                child: PageView.builder(
                  controller: _controller,
                  onPageChanged: (i) => setState(() => _page = i),
                  itemCount: pages.length,
                  itemBuilder: (context, i) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 34),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        ShaderMask(
                          shaderCallback: (r) =>
                              AppColors.brand.createShader(r),
                          child: Text(
                            pages[i].$1,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 34,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          pages[i].$2,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: p.textDim, fontSize: 15, height: 1.6),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              _Dots(count: pages.length, index: _page),
              const SizedBox(height: 22),
              Padding(
                padding: const EdgeInsets.fromLTRB(34, 0, 34, 28),
                child: GradientButton(
                  label: _page == pages.length - 1 ? t.start : t.next,
                  icon: _page == pages.length - 1
                      ? Icons.arrow_forward_rounded
                      : null,
                  onPressed: () {
                    if (_page == pages.length - 1) {
                      context.go('/account');
                    } else {
                      _controller.nextPage(
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeOutCubic);
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Dots extends StatelessWidget {
  final int count;
  final int index;
  const _Dots({required this.count, required this.index});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final active = i == index;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: active ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            gradient: active ? AppColors.brand : null,
            color: active ? null : context.palette.border,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}
