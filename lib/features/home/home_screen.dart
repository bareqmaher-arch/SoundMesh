import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/i18n/app_text.dart';
import '../../core/session_controller.dart';
import '../../core/settings_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../models/peer.dart';
import '../../widgets/glass.dart';
import '../../widgets/glow_mic_button.dart';
import '../../widgets/sound_orb.dart';
import '../../widgets/speaking_avatar.dart';
import '../../widgets/waveform.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // إن كانت الأذونات الأساسية ناقصة → بوابة الأذونات؛ وإلا اتصل مباشرةً
      // (يبدأ محرّك الصوت + يفحص أي مكالمة واردة معلّقة).
      final mic = await Permission.microphone.isGranted;
      final notif = await Permission.notification.isGranted;
      if (!mounted) return;
      if (!mic || !notif) {
        context.go('/gate');
        return;
      }
      ref.read(sessionControllerProvider.notifier).connect();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(sessionControllerProvider);
    final ctrl = ref.read(sessionControllerProvider.notifier);
    final t = ref.watch(appTextProvider);
    final p = context.palette;

    final online = state.peers.where((e) => e.isOnline).toList();
    final speakers = state.activeSpeakers;
    final anyoneSpeaking = state.talking || speakers.isNotEmpty;
    final activePeer =
        online.where((e) => speakers.contains(e.id)).firstOrNull;
    final speakerName = state.talking
        ? t.you
        : (activePeer?.name ?? t.channelName);
    final level = state.talking
        ? state.inputLevel
        : (speakers.isNotEmpty ? 0.5 : 0.0);

    return Scaffold(
      body: AuroraBackground(
        child: SafeArea(
          child: Column(
            children: [
              _topBar(context, t, state),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      const SizedBox(height: 8),
                      SoundOrb(size: 196, active: anyoneSpeaking, level: level),
                      const SizedBox(height: 18),
                      Text(speakerName,
                          style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: p.text)),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 26,
                        child: anyoneSpeaking
                            ? Waveform(level: 0.4 + level, bars: 9)
                            : Text(t.waitingToSpeak,
                                style: TextStyle(
                                    color: p.textDim, fontSize: 13)),
                      ),
                      const SizedBox(height: 22),
                      _membersStrip(context, state, online, speakers, ctrl),
                      const SizedBox(height: 16),
                      _stats(context, t, state),
                      const SizedBox(height: 120),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      bottomNavigationBar: _BottomBar(state: state, ctrl: ctrl, t: t),
    );
  }

  Widget _topBar(BuildContext context, AppText t, SessionState state) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 6, 14, 4),
      child: Row(
        children: [
          _iconBtn(context, Icons.settings_rounded,
              () => context.push('/settings')),
          const Spacer(),
          Column(
            children: [
              ShaderMask(
                shaderCallback: (r) => AppColors.brand.createShader(r),
                child: const Text('SoundMesh',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.white)),
              ),
              const SizedBox(height: 2),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                        color: state.connected
                            ? AppColors.online
                            : AppColors.amber,
                        shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 6),
                  Text(state.connected ? t.connected : t.connecting,
                      style: TextStyle(color: p.textDim, fontSize: 11.5)),
                ],
              ),
            ],
          ),
          const Spacer(),
          _iconBtn(context, Icons.person_rounded,
              () => context.push('/profile')),
        ],
      ),
    );
  }

  Widget _iconBtn(BuildContext context, IconData icon, VoidCallback onTap) {
    final p = context.palette;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: p.glass,
          shape: BoxShape.circle,
          border: Border.all(color: p.border),
        ),
        child: Icon(icon, color: p.text, size: 20),
      ),
    );
  }

  Widget _membersStrip(BuildContext context, SessionState state,
      List<Peer> online, Set<String> speakers, SessionController ctrl) {
    final me = state.profile;
    final items = <Widget>[
      SpeakingAvatar(
        imagePath: me?.avatarPath,
        defaultAvatar: me?.defaultAvatar ?? 0,
        name: me?.name ?? 'You',
        size: 52,
        speaking: state.talking,
        isMe: true,
      ),
      ...online.map((pr) => GestureDetector(
            onLongPress: () => _confirmIndividualCall(pr),
            child: SpeakingAvatar(
              imagePath: pr.avatarPath,
              defaultAvatar: pr.defaultAvatar,
              name: pr.name,
              size: 52,
              speaking: speakers.contains(pr.id),
            ),
          )),
    ];
    return SizedBox(
      height: 96,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, i) => items[i],
      ),
    );
  }

  Widget _stats(BuildContext context, AppText t, SessionState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _stat(context, '${state.peers.length + 1}', t.members),
            Container(width: 1, height: 30, color: context.palette.border),
            _stat(context, '${state.onlineCount + 1}', t.onlineNow),
          ],
        ),
      ),
    );
  }

  Widget _stat(BuildContext context, String value, String label) {
    final p = context.palette;
    return Column(
      children: [
        ShaderMask(
          shaderCallback: (r) => AppColors.brand.createShader(r),
          child: Text(value,
              style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Colors.white)),
        ),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(color: p.textDim, fontSize: 12)),
      ],
    );
  }

  void _confirmIndividualCall(Peer peer) {
    final ctrl = ref.read(sessionControllerProvider.notifier);
    final t = ref.read(appTextProvider);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => _Sheet(
        children: [
          Text('${t.callWithRing} · ${peer.name}',
              style: const TextStyle(
                  fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(sheetCtx),
                  child: Text(t.cancel),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.online,
                      foregroundColor: Colors.white),
                  onPressed: () {
                    Navigator.pop(sheetCtx);
                    ctrl.startIndividualCall(peer);
                  },
                  icon: const Icon(Icons.call_rounded),
                  label: Text(t.accept),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// شريط التحكم السفلي.
class _BottomBar extends ConsumerWidget {
  final SessionState state;
  final SessionController ctrl;
  final AppText t;
  const _BottomBar({required this.state, required this.ctrl, required this.t});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    return Container(
      decoration: BoxDecoration(
        color: p.bgElevated.withValues(alpha: p.isDark ? 0.7 : 0.92),
        border: Border(top: BorderSide(color: p.border)),
      ),
      padding: const EdgeInsets.fromLTRB(28, 12, 28, 0),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (state.audioActive)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: TextButton.icon(
                  onPressed: () => ctrl.leaveAudio(),
                  style: TextButton.styleFrom(
                    backgroundColor: AppColors.danger.withValues(alpha: 0.16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: const Icon(Icons.call_end_rounded,
                      color: AppColors.danger, size: 18),
                  label: Text(t.leaveAudio,
                      style: const TextStyle(
                          color: AppColors.danger,
                          fontWeight: FontWeight.w700)),
                ),
              ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _circle(context, Icons.call_rounded, AppColors.online,
                    () => _showCallOptions(context)),
                GlowMicButton(
                  active: state.talking,
                  level: state.inputLevel,
                  onTapDown: () => ctrl.startTalking(),
                  onTapUp: () => ctrl.stopTalking(),
                ),
                _circle(context, Icons.chat_bubble_rounded, AppColors.cyan,
                    () => context.push('/chat')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _circle(BuildContext context, IconData icon, Color color,
      VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.16),
          shape: BoxShape.circle,
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Icon(icon, color: color, size: 24),
      ),
    );
  }

  void _showCallOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => _Sheet(
        children: [
          _optionTile(
            sheetCtx,
            icon: Icons.call_rounded,
            color: AppColors.online,
            title: t.callWithRing,
            body: t.callWithRingDesc,
            onTap: () {
              Navigator.pop(sheetCtx);
              _startGroupCall(context);
            },
          ),
          const SizedBox(height: 10),
          _optionTile(
            sheetCtx,
            icon: state.openMic
                ? Icons.stop_rounded
                : Icons.graphic_eq_rounded,
            color: AppColors.violet,
            title: state.openMic ? t.stopBroadcast : t.transmitVoice,
            body: t.transmitVoiceDesc,
            onTap: () async {
              Navigator.pop(sheetCtx);
              await ctrl.toggleOpenMic();
              if (context.mounted && ctrl.lastError != null) {
                final e = ctrl.lastError!;
                ctrl.lastError = null;
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text(e)));
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _optionTile(BuildContext context,
      {required IconData icon,
      required Color color,
      required String title,
      required String body,
      required VoidCallback onTap}) {
    final p = context.palette;
    return GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
                color: color.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(14)),
            child: Icon(icon, color: color),
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
        ],
      ),
    );
  }

  Future<void> _startGroupCall(BuildContext context) async {
    await ctrl.startGroupCall();
    if (!context.mounted) return;
    if (ctrl.lastError != null) {
      final e = ctrl.lastError!;
      ctrl.lastError = null;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e)));
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.violet,
        content: Text(t.ringingMembers),
        action: SnackBarAction(
            label: t.cancel,
            textColor: Colors.white,
            onPressed: () => ctrl.endOutgoingCall()),
      ),
    );
  }
}

/// غلاف موحّد للنوافذ السفلية.
class _Sheet extends StatelessWidget {
  final List<Widget> children;
  const _Sheet({required this.children});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 20),
      decoration: BoxDecoration(
        color: p.bgElevated,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: p.border),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                    color: p.border,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            ...children,
          ],
        ),
      ),
    );
  }
}
