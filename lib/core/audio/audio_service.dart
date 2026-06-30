import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter_sound/flutter_sound.dart';

import 'mixer.dart';

/// التقاط الميكروفون كتدفّق PCM16 وتشغيل الصوت الممزوج.
///
/// الإعدادات: 16kHz, mono, PCM16. حجم الإطار 20ms (320 عيّنة = 640 بايت).
class AudioService {
  static const int sampleRate = 16000;
  static const int frameSamples = 320; // 20ms
  static const int frameBytes = frameSamples * 2;

  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  final FlutterSoundPlayer _player = FlutterSoundPlayer();
  final AudioMixer mixer = AudioMixer(frameSamples: frameSamples);

  StreamSubscription? _recordSub;
  bool _pumpRunning = false;

  bool _recorderReady = false;
  bool _playerReady = false;
  bool _capturing = false;

  /// تُستدعى لكل إطار PCM ملتقَط (لإرساله عبر الشبكة).
  void Function(Uint8List pcm)? onCapturedFrame;

  /// مستوى الإدخال (0..1) لتأثير الموجة في الواجهة.
  final ValueNotifier<double> inputLevel = ValueNotifier(0);

  /// المتحدثون النشطون الآن (للإضاءة في الواجهة).
  final ValueNotifier<Set<String>> activeSpeakers = ValueNotifier({});

  Future<void> init() async {
    if (!_recorderReady) {
      await _recorder.openRecorder();
      _recorderReady = true;
    }
    if (!_playerReady) {
      await _player.openPlayer();
      _playerReady = true;
      await _startPlaybackLoop();
    }
  }

  Future<void> _startPlaybackLoop() async {
    await _player.startPlayerFromStream(
      codec: Codec.pcm16,
      numChannels: 1,
      sampleRate: sampleRate,
      interleaved: true,
      bufferSize: 2048,
    );
    _pumpRunning = true;
    unawaited(_playbackPump());
  }

  /// مضخّة تشغيل مستمرة: تغذّي المشغّل دائماً (صمت عند عدم وجود صوت) عبر
  /// backpressure من flutter_sound. هذا يمنع توقّف/تعطّل AudioTrack الذي كان
  /// يُسبّب انهياراً أصلياً (releaseBuffer على مؤشّر فارغ) على أجهزة سامسونج.
  Future<void> _playbackPump() async {
    final silence = Uint8List(frameBytes); // إطار صمت (640 بايت أصفار)
    while (_pumpRunning) {
      final frame = mixer.mixNextFrame();
      activeSpeakers.value = mixer.activeSpeakers;
      final bytes = (frame != null && frame.isNotEmpty)
          ? _int16ToBytes(frame)
          : silence;
      try {
        // ينتظر حتى يتوفّر مكان في المخزن (يضبط الإيقاع تلقائياً مع الزمن الحقيقي).
        await _player.feedUint8FromStream(bytes);
      } catch (e) {
        debugPrint('playback feed error: $e');
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }
    }
  }

  /// عند false يتجاهل الصوت الوارد (لميزة "مغادرة الصوت").
  bool receiveEnabled = true;

  /// إدخال إطار وارد من الشبكة إلى المازج.
  void enqueueIncoming(String senderId, int sequence, Uint8List pcm) {
    if (!receiveEnabled) return;
    mixer.addFrame(senderId, sequence, _bytesToInt16(pcm));
  }

  /// كتم الاستقبال وتفريغ المازج فوراً.
  void muteReceive() {
    receiveEnabled = false;
    mixer.clear();
    activeSpeakers.value = {};
  }

  /// بدء التقاط الميكروفون (PTT أو وضع المايك المفتوح).
  Future<void> startCapture() async {
    if (_capturing) return;
    await init();
    _capturing = true;

    final controller = StreamController<Uint8List>();
    _recordSub = controller.stream.listen((bytes) {
      _emitFrames(bytes);
    });

    await _recorder.startRecorder(
      toStream: controller.sink,
      codec: Codec.pcm16,
      numChannels: 1,
      sampleRate: sampleRate,
    );
  }

  final BytesBuilder _captureCarry = BytesBuilder();

  void _emitFrames(Uint8List bytes) {
    _captureCarry.add(bytes);
    var buffered = _captureCarry.toBytes();
    int offset = 0;
    double peak = 0;
    while (buffered.length - offset >= frameBytes) {
      final frame =
          Uint8List.sublistView(buffered, offset, offset + frameBytes);
      offset += frameBytes;
      // مستوى الإدخال للموجة.
      final samples = _bytesToInt16(frame);
      for (final s in samples) {
        final a = s.abs() / 32768.0;
        if (a > peak) peak = a;
      }
      onCapturedFrame?.call(Uint8List.fromList(frame));
    }
    inputLevel.value = peak;
    _captureCarry.clear();
    if (offset < buffered.length) {
      _captureCarry.add(Uint8List.sublistView(buffered, offset));
    }
  }

  Future<void> stopCapture() async {
    if (!_capturing) return;
    _capturing = false;
    inputLevel.value = 0;
    await _recorder.stopRecorder();
    await _recordSub?.cancel();
    _recordSub = null;
    _captureCarry.clear();
  }

  bool get isCapturing => _capturing;

  Uint8List _int16ToBytes(Int16List samples) {
    final out = Uint8List(samples.length * 2);
    final data = ByteData.view(out.buffer);
    for (int i = 0; i < samples.length; i++) {
      data.setInt16(i * 2, samples[i], Endian.little);
    }
    return out;
  }

  Int16List _bytesToInt16(Uint8List bytes) {
    final count = bytes.length ~/ 2;
    final out = Int16List(count);
    final data = ByteData.view(bytes.buffer, bytes.offsetInBytes);
    for (int i = 0; i < count; i++) {
      out[i] = data.getInt16(i * 2, Endian.little);
    }
    return out;
  }

  Future<void> dispose() async {
    _pumpRunning = false;
    await stopCapture();
    if (_playerReady) await _player.closePlayer();
    if (_recorderReady) await _recorder.closeRecorder();
  }
}
