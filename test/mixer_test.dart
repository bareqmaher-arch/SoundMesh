import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:taki_waki/core/audio/mixer.dart';

void main() {
  group('AudioMixer', () {
    test('يمزج متحدثَين بجمع العيّنات', () {
      final mixer = AudioMixer(frameSamples: 4);
      mixer.addFrame('a', 0, Int16List.fromList([100, 200, 300, 400]));
      mixer.addFrame('b', 0, Int16List.fromList([50, 50, 50, 50]));

      final out = mixer.mixNextFrame();
      expect(out, isNotNull);
      expect(out![0], 150);
      expect(out[1], 250);
      expect(out[3], 450);
    });

    test('يطبّق clamp لتفادي التشويه', () {
      final mixer = AudioMixer(frameSamples: 2);
      mixer.addFrame('a', 0, Int16List.fromList([30000, -30000]));
      mixer.addFrame('b', 0, Int16List.fromList([30000, -30000]));

      final out = mixer.mixNextFrame()!;
      expect(out[0], 32767);
      expect(out[1], -32768);
    });

    test('يعيد null عند عدم وجود صوت', () {
      final mixer = AudioMixer(frameSamples: 2);
      expect(mixer.mixNextFrame(), isNull);
    });
  });
}
