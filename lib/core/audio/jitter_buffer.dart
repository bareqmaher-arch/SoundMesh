import 'dart:typed_data';

/// مخزن صغير لكل متحدث لتعويض تذبذب الشبكة وإعادة ترتيب الحِزَم.
///
/// يحتفظ بإطارات PCM16 مرتّبة حسب التسلسل ويُخرجها بثبات.
class JitterBuffer {
  final int maxFrames;
  final _frames = <int, Int16List>{};
  int? _nextSeq;
  DateTime lastActivity = DateTime.now();

  JitterBuffer({this.maxFrames = 12});

  void push(int sequence, Int16List samples) {
    lastActivity = DateTime.now();
    _nextSeq ??= sequence;
    // تجاهل الحِزَم القديمة جداً.
    if (sequence < (_nextSeq! - maxFrames)) return;
    _frames[sequence] = samples;
    // قصّ المخزن لو تضخّم.
    if (_frames.length > maxFrames * 2) {
      final keys = _frames.keys.toList()..sort();
      for (final k in keys.take(_frames.length - maxFrames)) {
        _frames.remove(k);
      }
      _nextSeq = (_frames.keys.toList()..sort()).first;
    }
  }

  /// يسحب الإطار التالي، أو null عند عدم توفّر بيانات بعد.
  Int16List? pop() {
    if (_nextSeq == null || _frames.isEmpty) return null;
    final frame = _frames.remove(_nextSeq);
    if (frame != null) {
      _nextSeq = _nextSeq! + 1;
      return frame;
    }
    // فقدان حزمة: تخطٍّ بعد امتلاء كافٍ للحفاظ على التدفّق.
    if (_frames.length > 1) {
      _nextSeq = _nextSeq! + 1;
      return Int16List(0); // صمت قصير
    }
    return null;
  }

  bool get isActive =>
      DateTime.now().difference(lastActivity) < const Duration(milliseconds: 800);

  bool get isEmpty => _frames.isEmpty;
}
