import 'dart:typed_data';

import 'jitter_buffer.dart';

/// يمزج إطارات PCM16 من عدة متحدثين في إطار واحد (الجميع يتحدثون معاً).
///
/// لكل متحدث jitter buffer مستقل؛ يُجمع الإطار التالي من كلٍّ منهم
/// مع clamp لتفادي التشويه (clipping).
class AudioMixer {
  /// عدد العيّنات في الإطار الواحد (20ms عند 16kHz = 320 عيّنة).
  final int frameSamples;

  final Map<String, JitterBuffer> _buffers = {};

  AudioMixer({this.frameSamples = 320});

  void addFrame(String senderId, int sequence, Int16List samples) {
    final buf = _buffers.putIfAbsent(senderId, () => JitterBuffer());
    buf.push(sequence, samples);
  }

  /// أسماء المتحدثين النشطين الآن (لإضاءة الواجهة).
  Set<String> get activeSpeakers =>
      _buffers.entries.where((e) => e.value.isActive).map((e) => e.key).toSet();

  /// يُخرج إطاراً ممزوجاً واحداً؛ null لو لا يوجد صوت.
  Int16List? mixNextFrame() {
    if (_buffers.isEmpty) return null;

    final accumulator = Int32List(frameSamples);
    bool any = false;

    final dead = <String>[];
    _buffers.forEach((id, buf) {
      final frame = buf.pop();
      if (frame == null) {
        if (!buf.isActive && buf.isEmpty) dead.add(id);
        return;
      }
      any = true;
      final n = frame.length < frameSamples ? frame.length : frameSamples;
      for (int i = 0; i < n; i++) {
        accumulator[i] += frame[i];
      }
    });

    for (final id in dead) {
      _buffers.remove(id);
    }

    if (!any) return null;

    final out = Int16List(frameSamples);
    for (int i = 0; i < frameSamples; i++) {
      final v = accumulator[i];
      out[i] = v > 32767 ? 32767 : (v < -32768 ? -32768 : v);
    }
    return out;
  }

  void clear() => _buffers.clear();
}
