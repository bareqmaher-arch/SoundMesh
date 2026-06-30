import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:uuid/uuid.dart';

import '../data/message_store.dart';
import '../data/profile_repository.dart';
import '../models/chat_message.dart';
import '../models/peer.dart';
import '../models/user_profile.dart';
import 'audio/audio_service.dart';
import 'background/foreground.dart';
import 'call/call_service.dart';
import 'call/call_task_handler.dart';
import 'network/transport_service.dart';

/// مزوّد المستودع (يُهيّأ في main).
final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  throw UnimplementedError('init in main');
});

/// الحالة العامة للجلسة.
class SessionState {
  final UserProfile? profile;
  final List<Peer> peers;
  final List<ChatMessage> messages;
  final bool connected;
  final bool talking; // المايك مضغوط الآن
  final bool openMic; // وضع "الجميع يتحدث"
  final Set<String> activeSpeakers;
  final double inputLevel;
  final bool micGranted;

  const SessionState({
    this.profile,
    this.peers = const [],
    this.messages = const [],
    this.connected = false,
    this.talking = false,
    this.openMic = false,
    this.activeSpeakers = const {},
    this.inputLevel = 0,
    this.micGranted = false,
  });

  int get onlineCount => peers.where((p) => p.isOnline).length;

  /// هل هناك نشاط صوتي الآن (أنا أتحدّث أو أحدٌ يتحدّث إليّ).
  bool get audioActive => talking || openMic || activeSpeakers.isNotEmpty;

  SessionState copyWith({
    UserProfile? profile,
    List<Peer>? peers,
    List<ChatMessage>? messages,
    bool? connected,
    bool? talking,
    bool? openMic,
    Set<String>? activeSpeakers,
    double? inputLevel,
    bool? micGranted,
  }) =>
      SessionState(
        profile: profile ?? this.profile,
        peers: peers ?? this.peers,
        messages: messages ?? this.messages,
        connected: connected ?? this.connected,
        talking: talking ?? this.talking,
        openMic: openMic ?? this.openMic,
        activeSpeakers: activeSpeakers ?? this.activeSpeakers,
        inputLevel: inputLevel ?? this.inputLevel,
        micGranted: micGranted ?? this.micGranted,
      );
}

class SessionController extends StateNotifier<SessionState> {
  final ProfileRepository repo;
  final TransportService transport = TransportService();
  final AudioService audio = AudioService();
  final MessageStore store = MessageStore();
  final CallService call = CallService();

  int _audioSeq = 0;
  bool _callInited = false;

  /// يُستدعى عند قبول مكالمة واردة لينتقل التطبيق للشاشة الرئيسية.
  void Function()? onNavigateHome;

  SessionController(this.repo)
      : super(SessionState(profile: repo.current)) {
    audio.inputLevel.addListener(() {
      state = state.copyWith(inputLevel: audio.inputLevel.value);
    });
    audio.activeSpeakers.addListener(() {
      // وسم الأقران المتحدثين.
      final speakers = audio.activeSpeakers.value;
      for (final p in state.peers) {
        p.speaking = speakers.contains(p.id);
      }
      state = state.copyWith(activeSpeakers: speakers, peers: [...state.peers]);
    });
  }

  // ---------------- الحساب ----------------

  Future<void> createAccount({
    required String name,
    required String phone,
    String? avatarPath,
    int defaultAvatar = 0,
  }) async {
    final p = await repo.create(
      name: name,
      phone: phone,
      avatarPath: avatarPath,
      defaultAvatar: defaultAvatar,
    );
    state = state.copyWith(profile: p);
  }

  Future<void> updateAccount({
    String? name,
    String? phone,
    String? avatarPath,
    int? defaultAvatar,
    String? about,
  }) async {
    final p = await repo.update(
      name: name,
      phone: phone,
      avatarPath: avatarPath,
      defaultAvatar: defaultAvatar,
      about: about,
    );
    state = state.copyWith(profile: p);
    await Foreground.saveProfile(p.toJson());
    transport.updateSelf(name: p.name);
    // إعادة بثّ الأفاتار الجديد لكل الأقران المتصلين.
    if (avatarPath != null) {
      _avatarSentTo.clear();
      _sendMyAvatarTo(_tcpTargets());
    }
  }

  Future<String?> pickAvatar() => repo.pickAvatar();

  // ---------------- الاتصال ----------------

  Future<void> connect() async {
    final profile = state.profile;
    if (profile == null || state.connected) return;

    try {
      // 1) طلب أذونات الميكروفون والإشعارات أولاً (ضروري قبل خدمة الميكروفون).
      final micStatus = await Permission.microphone.request();
      await Foreground.requestPermissions();
      // إذن "الظهور فوق التطبيقات" — يمنح استثناءً من قيود فتح التطبيق من
      // الخلفية، وهو ضروري لإيقاظ الأجهزة المتشدّدة (سامسونج) للبثّ المباشر.
      if (!await Permission.systemAlertWindow.isGranted) {
        await Permission.systemAlertWindow.request();
      }
      final micGranted = micStatus.isGranted;

      // حفظ الملف الشخصي لتبثّه عزلة الخلفية كحضور دائم.
      await Foreground.saveProfile(profile.toJson());
      // استقبال قائمة المتصلين من عزلة الخلفية.
      FlutterForegroundTask.removeTaskDataCallback(_onTaskData);
      FlutterForegroundTask.addTaskDataCallback(_onTaskData);

      // خدمة المقدمة: لا تُبدأ إلا عند منح إذن الميكروفون، لأن خدمة من نوع
      // microphone بدون RECORD_AUDIO تُسبّب انهياراً أصلياً غير قابل للالتقاط.
      if (micGranted) {
        Foreground.init();
        await Foreground.start();
        await audio.init();
        audio.receiveEnabled = true;
        audio.onCapturedFrame = _onCapturedFrame;
      } else {
        lastError = 'إذن الميكروفون مطلوب للتحدّث. الرسائل تعمل بدونه.';
      }

      // النقل: استقبال الصوت والرسائل والأفاتارات.
      transport.onImageBytes = _onIncomingImage;
      transport.onAvatarBytes = _onAvatarBytes;
      await transport.start(selfId: profile.id, selfName: profile.name);
      transport.incomingAudio.listen((pkt) {
        audio.enqueueIncoming(pkt.senderId, pkt.sequence, pkt.pcm);
      });
      transport.incomingMessages.listen(_onIncomingMessage);

      // خدمة الاتصال (الرنين عند الجميع).
      await _initCall();

      state = state.copyWith(connected: true, micGranted: micGranted);
    } catch (e, st) {
      debugPrint('TakiWaki connect error: $e\n$st');
      lastError = 'تعذّر بدء الاتصال: $e';
      state = state.copyWith(connected: false);
    }
  }

  /// آخر خطأ للعرض في الواجهة.
  String? lastError;

  Future<void> disconnect() async {
    await audio.stopCapture();
    await transport.stop();
    FlutterForegroundTask.removeTaskDataCallback(_onTaskData);
    await Foreground.stop();
    state = state.copyWith(connected: false, talking: false, openMic: false);
  }

  // ---------------- قائمة المتصلين من عزلة الخلفية ----------------

  /// تُستقبل قائمة المتصلين من معالج الخلفية وتُحدَّث الحالة.
  void _onTaskData(Object data) {
    if (data is! String) return;
    try {
      final obj = jsonDecode(data) as Map<String, dynamic>;

      // اتصال وارد من معالج الخلفية.
      if (obj['incomingCall'] is Map) {
        _presentIncoming(Map<String, dynamic>.from(obj['incomingCall'] as Map));
        return;
      }
      if (obj['callCancelled'] == true) {
        incomingCall = null;
        onCallCancelled?.call();
        return;
      }

      final roster = obj['roster'];
      if (roster is! List) return;
      final peers = roster
          .map((e) => _peerFromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      for (final p in peers) {
        p.avatarPath = _peerAvatars[p.id];
        p.speaking = state.activeSpeakers.contains(p.id);
      }
      _shareAvatarWithNewPeers(peers);
      state = state.copyWith(peers: peers);
      Foreground.updateText('${state.onlineCount} متصل');
    } catch (e) {
      debugPrint('roster parse error: $e');
    }
  }

  Peer _peerFromJson(Map<String, dynamic> j) => Peer(
        id: j['id'] as String,
        name: j['name'] as String? ?? 'مستخدم',
        phone: j['phone'] as String? ?? '',
        avatarHash: j['avatarHash'] as String? ?? 'def0',
        defaultAvatar: (j['defaultAvatar'] as int?) ?? 0,
        address: j['address'] as String? ?? '',
        tcpPort: (j['tcpPort'] as int?) ?? TransportService.tcpPort,
        lastSeen: DateTime.now(),
      );

  // ---------------- الصوت ----------------

  void _onCapturedFrame(Uint8List pcm) {
    final targets = state.peers
        .where((p) => p.isOnline)
        .map((p) =>
            (address: p.address, audioPort: TransportService.audioPort))
        .toList();
    transport.sendAudio(
      pcm: pcm,
      sequence: _audioSeq++,
      targets: targets,
    );
  }

  /// بدء الكلام (PTT).
  Future<void> startTalking() async {
    if (!state.connected) await connect();
    if (!state.micGranted) {
      lastError = 'إذن الميكروفون مطلوب للتحدّث.';
      return;
    }
    try {
      audio.receiveEnabled = true;
      await audio.startCapture();
      state = state.copyWith(talking: true);
    } catch (e) {
      debugPrint('startTalking error: $e');
    }
  }

  /// مغادرة الصوت: يوقف المايك ويكتم الاستقبال — متاح لأي مستخدم لإنهاء
  /// المكالمة/البثّ من جهته (لا يقتصر على من بدأ الصوت).
  Future<void> leaveAudio() async {
    audio.muteReceive();
    await audio.stopCapture();
    await endOutgoingCall();
    state = state.copyWith(
        talking: false, openMic: false, activeSpeakers: {}, peers: [
      for (final p in state.peers) p..speaking = false,
    ]);
  }

  Future<void> stopTalking() async {
    if (state.openMic) return; // يبقى المايك مفتوحاً
    await audio.stopCapture();
    state = state.copyWith(talking: false);
  }

  Future<void> toggleOpenMic() async {
    if (!state.connected) await connect();
    if (!state.micGranted) {
      lastError = 'إذن الميكروفون مطلوب للتحدّث.';
      return;
    }
    final next = !state.openMic;
    state = state.copyWith(openMic: next);
    try {
      if (next) {
        audio.receiveEnabled = true;
        // إيقاظ صامت للأجهزة المغلقة كي تسمع البثّ (بلا رنين).
        final profile = state.profile;
        if (profile != null) {
          call.sendWake(
            fromId: profile.id,
            fromName: profile.name,
            targetAddresses: _onlineAddresses(),
          );
        }
        await audio.startCapture();
        state = state.copyWith(talking: true);
      } else {
        await audio.stopCapture();
        state = state.copyWith(talking: false);
      }
    } catch (e) {
      debugPrint('toggleOpenMic error: $e');
    }
  }

  // ---------------- الاتصال (الرنين) ----------------

  String? _activeOutgoingCallId;

  Future<void> _initCall() async {
    if (_callInited) return;
    _callInited = true;
    await call.init();
    await checkPendingIncomingCall();
  }

  /// معلومات الاتصال الوارد الحالي (للعرض في شاشة الرنين).
  Map<String, dynamic>? incomingCall;

  /// يُستدعى عند وصول اتصال وارد لينتقل التطبيق لشاشة الرنين.
  void Function(Map<String, dynamic> info)? onIncomingCall;

  /// يُستدعى عند إلغاء المتصل للاتصال (لإغلاق شاشة الرنين).
  void Function()? onCallCancelled;

  /// فحص وجود اتصال وارد محفوظ (عند فتح التطبيق من الإشعار).
  Future<void> checkPendingIncomingCall() async {
    try {
      final raw = await FlutterForegroundTask.getData<String>(
          key: BackgroundHandler.incomingCallKey);
      if (raw == null) return;
      final info = jsonDecode(raw) as Map<String, dynamic>;
      final ts = info['ts'] as int? ?? 0;
      // تجاهل الاتصالات القديمة (أكثر من 60 ثانية).
      if (DateTime.now().millisecondsSinceEpoch - ts > 60000) {
        await FlutterForegroundTask.removeData(
            key: BackgroundHandler.incomingCallKey);
        return;
      }
      _presentIncoming(info);
    } catch (_) {}
  }

  void _presentIncoming(Map<String, dynamic> info) {
    incomingCall = info;
    onIncomingCall?.call(info);
  }

  /// قبول الاتصال الوارد: إيقاف الرنين + الاتصال + بدء السماع + الانتقال للرئيسية.
  Future<void> acceptIncomingCall() async {
    // إيقاف رنين الإشعار المتواصل.
    FlutterForegroundTask.sendDataToTask(jsonEncode({'cmd': 'endIncoming'}));
    await FlutterForegroundTask.removeData(
        key: BackgroundHandler.incomingCallKey);
    incomingCall = null;
    if (!state.connected) await connect();
    onNavigateHome?.call();
  }

  /// رفض الاتصال الوارد.
  Future<void> declineIncomingCall() async {
    await FlutterForegroundTask.removeData(
        key: BackgroundHandler.incomingCallKey);
    incomingCall = null;
    FlutterForegroundTask.sendDataToTask(jsonEncode({'cmd': 'endIncoming'}));
  }

  List<String> _onlineAddresses() =>
      state.peers.where((p) => p.isOnline).map((p) => p.address).toList();

  /// اتصال جماعي: يرنّ عند كل المتصلين.
  Future<void> startGroupCall() async {
    if (!state.connected) await connect();
    final profile = state.profile;
    if (profile == null) return;
    final addresses = _onlineAddresses();
    if (addresses.isEmpty) {
      lastError = 'لا يوجد أعضاء متصلون للاتصال بهم.';
      return;
    }
    _activeOutgoingCallId = call.startCall(
      fromId: profile.id,
      fromName: profile.name,
      fromDefaultAvatar: profile.defaultAvatar,
      group: true,
      targetAddresses: addresses,
    );
    // رنين فقط — لا يُفتح الميكروفون. التحدّث يكون عبر زر المايك بعد القبول.
  }

  /// اتصال فردي بعضو محدّد.
  Future<void> startIndividualCall(Peer peer) async {
    if (!state.connected) await connect();
    final profile = state.profile;
    if (profile == null) return;
    _activeOutgoingCallId = call.startCall(
      fromId: profile.id,
      fromName: profile.name,
      fromDefaultAvatar: profile.defaultAvatar,
      group: false,
      targetAddresses: [peer.address],
    );
    // رنين فقط — لا يُفتح الميكروفون.
  }

  /// إنهاء الاتصال الصادر (يلغي الرنين عند الطرف الآخر).
  Future<void> endOutgoingCall() async {
    final id = _activeOutgoingCallId;
    final profile = state.profile;
    if (id != null && profile != null) {
      call.cancelCall(
        callId: id,
        fromId: profile.id,
        targetAddresses: _onlineAddresses(),
      );
    }
    _activeOutgoingCallId = null;
    if (state.openMic) {
      await audio.stopCapture();
      state = state.copyWith(talking: false, openMic: false);
    }
  }

  // ---------------- الرسائل ----------------

  List<({String address, int tcpPort})> _tcpTargets() => state.peers
      .where((p) => p.isOnline)
      .map((p) => (address: p.address, tcpPort: p.tcpPort))
      .toList();

  Future<void> sendText(String text) async {
    if (text.trim().isEmpty) return;
    final profile = state.profile!;
    final msg = ChatMessage(
      id: const Uuid().v4(),
      senderId: profile.id,
      senderName: profile.name,
      kind: MessageKind.text,
      text: text.trim(),
      time: DateTime.now(),
      isMine: true,
    );
    store.add(msg);
    state = state.copyWith(messages: store.messages);
    await transport.sendText(text.trim(), msg.id, _tcpTargets());
  }

  Future<void> sendImageFromGallery() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1280,
      imageQuality: 80,
    );
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    final id = const Uuid().v4();
    final profile = state.profile!;
    final path = await store.saveIncomingImage(bytes, id);
    final msg = ChatMessage(
      id: id,
      senderId: profile.id,
      senderName: profile.name,
      kind: MessageKind.image,
      imagePath: path,
      time: DateTime.now(),
      isMine: true,
    );
    store.add(msg);
    state = state.copyWith(messages: store.messages);
    await transport.sendImage(bytes, id, _tcpTargets());
  }

  void _onIncomingMessage(ChatMessage msg) {
    store.add(msg);
    state = state.copyWith(messages: store.messages);
  }

  Future<void> _onIncomingImage(
      String id, String senderId, String senderName, Uint8List bytes) async {
    final path = await store.saveIncomingImage(bytes, id);
    final msg = ChatMessage(
      id: id,
      senderId: senderId,
      senderName: senderName,
      kind: MessageKind.image,
      imagePath: path,
      time: DateTime.now(),
      isMine: false,
    );
    _onIncomingMessage(msg);
  }

  // ---------------- الأفاتارات عبر الشبكة ----------------

  /// مسارات أفاتارات الأقران المخصّصة، مفتاحها معرّف الـ peer.
  final Map<String, String> _peerAvatars = {};

  /// معرّفات الأقران الذين أرسلنا لهم أفاتارنا مسبقاً (لتفادي التكرار).
  final Set<String> _avatarSentTo = {};

  /// عند استلام صورة أفاتار من peer: تُحفظ وتُطبّق على القائمة.
  Future<void> _onAvatarBytes(
      String peerId, String avatarHash, Uint8List bytes) async {
    try {
      final path = await store.savePeerAvatar(bytes, peerId, avatarHash);
      _peerAvatars[peerId] = path;
      for (final p in state.peers) {
        if (p.id == peerId) p.avatarPath = path;
      }
      state = state.copyWith(peers: [...state.peers]);
    } catch (e) {
      debugPrint('save peer avatar error: $e');
    }
  }

  /// إرسال أفاتاري (إن كان صورة مخصّصة) لقائمة أقران.
  Future<void> _sendMyAvatarTo(
      List<({String address, int tcpPort})> targets) async {
    final profile = state.profile;
    if (profile == null || !profile.hasCustomAvatar || targets.isEmpty) return;
    try {
      final bytes = await File(profile.avatarPath!).readAsBytes();
      await transport.sendAvatar(bytes, profile.avatarHash, targets);
    } catch (e) {
      debugPrint('send avatar error: $e');
    }
  }

  /// إرسال أفاتاري للأعضاء الجدد فقط.
  void _shareAvatarWithNewPeers(List<dynamic> peers) {
    final newTargets = <({String address, int tcpPort})>[];
    for (final p in peers) {
      if (p.isOnline && !_avatarSentTo.contains(p.id)) {
        _avatarSentTo.add(p.id);
        newTargets.add((address: p.address, tcpPort: p.tcpPort));
      }
    }
    if (newTargets.isNotEmpty) _sendMyAvatarTo(newTargets);
  }

  @override
  void dispose() {
    audio.dispose();
    FlutterForegroundTask.removeTaskDataCallback(_onTaskData);
    transport.dispose();
    call.dispose();
    super.dispose();
  }
}

final sessionControllerProvider =
    StateNotifierProvider<SessionController, SessionState>((ref) {
  final repo = ref.watch(profileRepositoryProvider);
  return SessionController(repo);
});
