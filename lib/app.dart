import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/session_controller.dart';
import 'core/settings_controller.dart';
import 'core/theme/app_theme.dart';
import 'features/call/incoming_call_screen.dart';
import 'features/chat/chat_screen.dart';
import 'features/home/home_screen.dart';
import 'features/onboarding/account_screen.dart';
import 'features/onboarding/welcome_screen.dart';
import 'features/permission/permission_gate.dart';
import 'features/profile/profile_screen.dart';
import 'features/settings/settings_screen.dart';

class SoundMeshApp extends ConsumerStatefulWidget {
  const SoundMeshApp({super.key});

  @override
  ConsumerState<SoundMeshApp> createState() => _SoundMeshAppState();
}

class _SoundMeshAppState extends ConsumerState<SoundMeshApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    final hasProfile = ref.read(sessionControllerProvider).profile != null;
    _router = GoRouter(
      // البداية على الرئيسية مباشرةً عند وجود حساب — كي يعمل الصوت فوراً عند
      // الإيقاظ للبثّ. الرئيسية تحوّل لبوابة الأذونات فقط إن كانت ناقصة.
      initialLocation: hasProfile ? '/home' : '/welcome',
      routes: [
        GoRoute(path: '/welcome', pageBuilder: (c, s) => _fade(const WelcomeScreen())),
        GoRoute(path: '/account', pageBuilder: (c, s) => _slide(const AccountScreen())),
        GoRoute(path: '/gate', pageBuilder: (c, s) => _fade(const PermissionGate())),
        GoRoute(path: '/home', pageBuilder: (c, s) => _fade(const HomeScreen())),
        GoRoute(path: '/profile', pageBuilder: (c, s) => _slide(const ProfileScreen())),
        GoRoute(path: '/settings', pageBuilder: (c, s) => _slide(const SettingsScreen())),
        GoRoute(path: '/chat', pageBuilder: (c, s) => _slide(const ChatScreen())),
        GoRoute(path: '/incoming-call', pageBuilder: (c, s) => _fade(const IncomingCallScreen())),
      ],
    );
    final ctrl = ref.read(sessionControllerProvider.notifier);
    ctrl.onNavigateHome = () => _router.go('/home');
    ctrl.onIncomingCall = (info) => _router.go('/incoming-call');
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsControllerProvider);
    return MaterialApp.router(
      title: 'SoundMesh',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: settings.themeMode,
      locale: Locale(settings.localeCode),
      supportedLocales: const [Locale('en'), Locale('ar')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: _router,
    );
  }

  static CustomTransitionPage _fade(Widget child) => CustomTransitionPage(
        child: child,
        transitionDuration: const Duration(milliseconds: 450),
        transitionsBuilder: (c, anim, sec, child) => FadeTransition(
          opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
          child: child,
        ),
      );

  static CustomTransitionPage _slide(Widget child) => CustomTransitionPage(
        child: child,
        transitionDuration: const Duration(milliseconds: 420),
        transitionsBuilder: (c, anim, sec, child) {
          final curved =
              CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
          return FadeTransition(
            opacity: curved,
            child: SlideTransition(
              position: Tween(begin: const Offset(0, 0.06), end: Offset.zero)
                  .animate(curved),
              child: child,
            ),
          );
        },
      );
}
