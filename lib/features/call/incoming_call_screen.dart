import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/session_controller.dart';
import '../../core/settings_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/sound_orb.dart';

/// شاشة الاتصال الوارد — كرة متوهّجة + قبول/رفض. الرنين من الإشعار المتواصل.
class IncomingCallScreen extends ConsumerStatefulWidget {
  const IncomingCallScreen({super.key});

  @override
  ConsumerState<IncomingCallScreen> createState() => _IncomingCallScreenState();
}

class _IncomingCallScreenState extends ConsumerState<IncomingCallScreen> {
  @override
  void initState() {
    super.initState();
    final ctrl = ref.read(sessionControllerProvider.notifier);
    ctrl.onCallCancelled = () {
      if (mounted) context.go('/home');
    };
  }

  Future<void> _accept() async {
    await ref.read(sessionControllerProvider.notifier).acceptIncomingCall();
    if (mounted) context.go('/home');
  }

  Future<void> _decline() async {
    await ref.read(sessionControllerProvider.notifier).declineIncomingCall();
    if (mounted) context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(appTextProvider);
    final info = ref.read(sessionControllerProvider.notifier).incomingCall;
    final name = info?['fromName'] as String? ?? 'SoundMesh';
    final group = info?['group'] as bool? ?? true;

    return Scaffold(
      backgroundColor: AppColors.dBg,
      body: Stack(
        children: [
          const Positioned.fill(child: _CallBackdrop()),
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 40),
                Text(group ? t.incomingGroupCall : t.incomingCall,
                    style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.5)),
                const Spacer(flex: 2),
                const SoundOrb(size: 180, active: true, level: 0.4),
                const SizedBox(height: 30),
                Text(name,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                Text(t.callingYou,
                    style:
                        const TextStyle(color: Colors.white60, fontSize: 14)),
                const Spacer(flex: 3),
                Padding(
                  padding: const EdgeInsets.only(bottom: 56),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _action(Icons.call_end_rounded, AppColors.danger,
                          t.decline, _decline),
                      _action(Icons.call_rounded, AppColors.online, t.accept,
                          _accept),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _action(
      IconData icon, Color color, String label, VoidCallback onTap) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                    color: color.withValues(alpha: 0.5),
                    blurRadius: 22,
                    spreadRadius: 2)
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 34),
          ),
        ),
        const SizedBox(height: 10),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 14)),
      ],
    );
  }
}

class _CallBackdrop extends StatelessWidget {
  const _CallBackdrop();
  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.center,
          radius: 1.1,
          colors: [Color(0xFF1A1140), AppColors.dBg],
        ),
      ),
    );
  }
}
