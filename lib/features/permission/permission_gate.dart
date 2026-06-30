import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/i18n/app_text.dart';
import '../../core/settings_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/glass.dart';
import '../../widgets/gradient_button.dart';

enum _Perm { mic, notif, overlay, battery }

/// بوابة الأذونات — تبقى تطلب الأذونات الناقصة مع إرشاد حتى تكتمل.
class PermissionGate extends ConsumerStatefulWidget {
  const PermissionGate({super.key});

  @override
  ConsumerState<PermissionGate> createState() => _PermissionGateState();
}

class _PermissionGateState extends ConsumerState<PermissionGate>
    with WidgetsBindingObserver {
  final Map<_Perm, bool> _status = {
    _Perm.mic: false,
    _Perm.notif: false,
    _Perm.overlay: false,
    _Perm.battery: false,
  };
  bool _checked = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh();
  }

  Future<void> _refresh() async {
    final mic = await Permission.microphone.isGranted;
    final notif = await Permission.notification.isGranted;
    final overlay = await Permission.systemAlertWindow.isGranted;
    final battery = await FlutterForegroundTask.isIgnoringBatteryOptimizations;
    if (!mounted) return;
    setState(() {
      _status[_Perm.mic] = mic;
      _status[_Perm.notif] = notif;
      _status[_Perm.overlay] = overlay;
      _status[_Perm.battery] = battery;
      _checked = true;
    });
  }

  Future<void> _request(_Perm perm) async {
    switch (perm) {
      case _Perm.mic:
        await Permission.microphone.request();
        break;
      case _Perm.notif:
        await Permission.notification.request();
        break;
      case _Perm.overlay:
        await Permission.systemAlertWindow.request();
        break;
      case _Perm.battery:
        await FlutterForegroundTask.requestIgnoreBatteryOptimization();
        break;
    }
    await _refresh();
  }

  bool get _coreReady => _status[_Perm.mic]! && _status[_Perm.notif]!;
  bool get _allReady => _status.values.every((v) => v);

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(appTextProvider);
    final p = context.palette;
    return Scaffold(
      body: AuroraBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 18, 22, 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 8),
                Container(
                  width: 64,
                  height: 64,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: AppColors.brand,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                          color: AppColors.violet.withValues(alpha: 0.5),
                          blurRadius: 24)
                    ],
                  ),
                  child: const Icon(Icons.shield_moon_rounded,
                      color: Colors.white, size: 32),
                ),
                const SizedBox(height: 18),
                Text(_allReady ? t.permAllSet : t.permGateTitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: p.text)),
                const SizedBox(height: 8),
                Text(t.permGateBody,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: p.textDim, height: 1.5)),
                const SizedBox(height: 20),
                Expanded(
                  child: !_checked
                      ? const Center(child: CircularProgressIndicator())
                      : ListView(
                          children: [
                            _tile(t, _Perm.mic, Icons.mic_rounded,
                                t.permMicTitle, t.permMicBody),
                            _tile(t, _Perm.notif, Icons.notifications_rounded,
                                t.permNotifTitle, t.permNotifBody),
                            _tile(t, _Perm.overlay, Icons.layers_rounded,
                                t.permOverlayTitle, t.permOverlayBody),
                            _tile(t, _Perm.battery, Icons.battery_charging_full_rounded,
                                t.permBatteryTitle, t.permBatteryBody),
                          ],
                        ),
                ),
                const SizedBox(height: 8),
                GradientButton(
                  label: t.permEnterApp,
                  onPressed: _coreReady ? () => context.go('/home') : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _tile(AppText t, _Perm perm, IconData icon, String title, String body) {
    final granted = _status[perm]!;
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: (granted ? AppColors.online : AppColors.violet)
                    .withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon,
                  color: granted ? AppColors.online : AppColors.cyan, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          fontWeight: FontWeight.w700, color: p.text)),
                  const SizedBox(height: 3),
                  Text(body,
                      style: TextStyle(
                          fontSize: 12, color: p.textDim, height: 1.4)),
                ],
              ),
            ),
            const SizedBox(width: 10),
            granted
                ? const Icon(Icons.check_circle_rounded,
                    color: AppColors.online, size: 26)
                : TextButton(
                    onPressed: () => _request(perm),
                    style: TextButton.styleFrom(
                      backgroundColor: AppColors.violet.withValues(alpha: 0.18),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(t.permGrant,
                        style: const TextStyle(
                            color: AppColors.cyan,
                            fontWeight: FontWeight.w700)),
                  ),
          ],
        ),
      ),
    );
  }
}
