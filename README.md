# TakiWaki — جهاز مناداة لاسلكي عبر شبكة WiFi المحلية

تطبيق "ووكي توكي" (Push-to-Talk) لأندرويد يعمل **بدون إنترنت** عبر شبكة المنزل المحلية:

- إنشاء حساب بالاسم ورقم الهاتف فقط + صورة/أفاتار.
- **كلام صوتي جماعي متزامن** — الجميع يسمع الجميع في نفس الوقت.
- إرسال رسائل نصية وصور بين أفراد الشبكة.
- تعديل الاسم/الصورة/المعلومات في أي وقت.
- يعمل **في الخلفية** حتى أثناء السكون أو إغلاق التطبيق (Foreground Service).
- واجهة وأنميشن أنيق مستوحى من تصميم Vibra.

---

## المتطلبات

| الأداة | ملاحظة |
|-------|--------|
| **Flutter SDK** ‏(3.3+) | غير مثبّت حالياً — ثبّته أولاً |
| **JDK 17** | مطلوب لبناء أندرويد |
| **Android SDK** | موجود مسبقاً في `%LOCALAPPDATA%\Android\Sdk` |
| جهازا أندرويد على **نفس شبكة WiFi** | للاختبار الحقيقي للصوت |

### تثبيت Flutter (مختصر)
1. حمّل Flutter من: https://docs.flutter.dev/get-started/install/windows
2. فُكّ الضغط مثلاً إلى `C:\src\flutter` وأضف `C:\src\flutter\bin` إلى PATH.
3. ثبّت JDK 17 وأضفه إلى PATH.
4. تحقّق: `flutter doctor` ثم `flutter doctor --android-licenses`.

---

## الإعداد (مرة واحدة)

من داخل مجلد المشروع شغّل:

```powershell
./setup.ps1
```

السكربت يقوم تلقائياً بـ:
1. توليد منصة أندرويد عبر `flutter create` (دون المساس بالكود في `lib/`).
2. تطبيق `AndroidManifest.xml` المخصّص (الأذونات + الخدمة الأمامية).
3. ضبط `minSdkVersion = 24`.
4. جلب الحزم `flutter pub get`.

> إن فضّلت يدوياً: شغّل الأوامر داخل `setup.ps1` بالترتيب نفسه.

---

## التشغيل

```powershell
flutter run            # على جهاز واحد
flutter run -d <id>    # لجهاز محدّد (اعرف المعرّفات بـ flutter devices)
```

لتجربة الصوت الجماعي **شغّل التطبيق على جهازين** على نفس الراوتر.

### بناء APK للتوزيع
```powershell
flutter build apk --release
```

---

## كيف يعمل (المعمارية)

```
lib/
  core/
    network/
      discovery_service.dart   اكتشاف الأقران (UDP multicast beacon + roster)
      transport_service.dart   صوت UDP unicast + رسائل/صور TCP
      protocol/packet.dart     ترميز ثنائي للحِزَم
    audio/
      audio_service.dart       التقاط/تشغيل PCM (flutter_sound)
      jitter_buffer.dart       تعويض تذبذب الشبكة لكل متحدث
      mixer.dart               مزج عدة متحدثين معاً (الجميع يتكلم)
    background/foreground.dart  خدمة المقدمة (خلفية/سكون)
    session_controller.dart    العقل المدبّر (Riverpod) يربط كل شيء
  data/                        حفظ الحساب (Hive) + سجل الرسائل
  features/                    الشاشات: onboarding / home / profile / chat
  widgets/                     AppAvatar / GlowMicButton / Waveform
```

- **الصوت:** PCM16, ‏16kHz, mono, إطار 20ms. كل متحدث يرسل إطاراته عبر UDP لكل
  الأقران المتصلين؛ كل جهاز يمزج الإطارات الواردة في تيار واحد للتشغيل.
- **الاكتشاف:** كل جهاز يبثّ حضوره كل ثانيتين عبر `239.7.7.7:45454`.
- **الخلفية:** `flutter_foreground_task` بخدمة `microphone|dataSync` + قفل WiFi/Wake.

---

## ملاحظات وحل المشكلات

- **لا يكتشف الأجهزة بعضها؟** أوقف عزل العملاء (AP/Client Isolation) في إعدادات
  الراوتر، وتأكد أن الجهازين على نفس الشبكة (وليس شبكة الضيوف).
- **لا يوجد صوت؟** امنح إذن الميكروفون وإذن الإشعارات، واستثنِ التطبيق من تحسين
  البطارية (يطلبها التطبيق تلقائياً عند أول اتصال).
- **زمن استجابة عالٍ؟** الخيار الأقوى لاحقاً هو وحدة Kotlin أصلية
  (AudioRecord/AudioTrack) بدل flutter_sound — معماريتنا تدعم استبدالها بسهولة.
- iOS غير مدعوم حالياً بسبب قيود العمل في الخلفية بدون إنترنت.

---

## الاختبار

```powershell
flutter test            # اختبارات الوحدة (ترميز الحِزَم + المزج)
adb logcat | findstr TakiWaki   # متابعة سجلّات الخدمة
```
