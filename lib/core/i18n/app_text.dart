/// نصوص التطبيق بلغتين. تُختار النسخة المناسبة حسب لغة الإعدادات.
abstract class AppText {
  String get localeCode;

  // عام
  String get appName;
  String get appTagline;
  String get next;
  String get start;
  String get cancel;
  String get save;
  String get continueLabel;
  String get retry;
  String get you;

  // الترحيب
  String get welcomeTitle;
  String get welcomeBody;
  String get feature1Title;
  String get feature1Body;
  String get feature2Title;
  String get feature2Body;

  // الحساب
  String get createAccount;
  String get yourName;
  String get nameHint;
  String get phone;
  String get phoneHint;
  String get pickAvatar;
  String get aboutYou;

  // الرئيسية
  String get channelName;
  String get channelDesc;
  String get connected;
  String get connecting;
  String get members;
  String get onlineNow;
  String get waitingToSpeak;
  String get speakingNow;
  String get holdToTalk;
  String get callOptions;
  String get callWithRing;
  String get callWithRingDesc;
  String get transmitVoice;
  String get transmitVoiceDesc;
  String get stopBroadcast;
  String get ringingMembers;
  String get broadcastOn;
  String get broadcastOff;
  String get leaveAudio;
  String get noMembersToCall;
  String get micRequired;

  // المحادثة
  String get messages;
  String get typeMessage;
  String get noMessages;
  String get noMessagesBody;

  // الملف الشخصي
  String get profile;
  String get savedChanges;

  // الإعدادات
  String get settings;
  String get appearance;
  String get theme;
  String get darkMode;
  String get lightMode;
  String get systemMode;
  String get language;
  String get arabic;
  String get english;
  String get permissionsTitle;
  String get openPermissions;
  String get designedBy;
  String get designerName;
  String get aboutApp;
  String get aboutAppBody;

  // الأذونات
  String get permGateTitle;
  String get permGateBody;
  String get permGrant;
  String get permGranted;
  String get permAllSet;
  String get permEnterApp;
  String get permMicTitle;
  String get permMicBody;
  String get permNotifTitle;
  String get permNotifBody;
  String get permOverlayTitle;
  String get permOverlayBody;
  String get permBatteryTitle;
  String get permBatteryBody;
  String get permOpenSettings;

  // الاتصال الوارد
  String get incomingCall;
  String get incomingGroupCall;
  String get callingYou;
  String get accept;
  String get decline;

  static AppText of(String code) => code == 'ar' ? ArText() : EnText();
}

class EnText extends AppText {
  @override
  String get localeCode => 'en';
  @override
  String get appName => 'SoundMesh';
  @override
  String get appTagline => 'Talk across your space — no internet needed.';
  @override
  String get next => 'Next';
  @override
  String get start => 'Get Started';
  @override
  String get cancel => 'Cancel';
  @override
  String get save => 'Save';
  @override
  String get continueLabel => 'Continue';
  @override
  String get retry => 'Retry';
  @override
  String get you => 'You';
  @override
  String get welcomeTitle => 'SoundMesh';
  @override
  String get welcomeBody =>
      'A futuristic intercom that links everyone over your local WiFi — fully offline.';
  @override
  String get feature1Title => 'Talk Together';
  @override
  String get feature1Body =>
      'Push to talk or open the mic — everyone hears everyone, instantly.';
  @override
  String get feature2Title => 'Ring & Reach';
  @override
  String get feature2Body =>
      'Ring anyone even when their app is closed, or broadcast silently.';
  @override
  String get createAccount => 'Create your profile';
  @override
  String get yourName => 'Name';
  @override
  String get nameHint => 'Enter your name';
  @override
  String get phone => 'Phone number';
  @override
  String get phoneHint => '07xx xxx xxxx';
  @override
  String get pickAvatar => 'Pick a photo or an avatar';
  @override
  String get aboutYou => 'About';
  @override
  String get channelName => 'Mesh Channel';
  @override
  String get channelDesc => 'Local WiFi channel · no internet';
  @override
  String get connected => 'Connected';
  @override
  String get connecting => 'Connecting…';
  @override
  String get members => 'Members';
  @override
  String get onlineNow => 'Online';
  @override
  String get waitingToSpeak => 'Tap & hold the mic to talk';
  @override
  String get speakingNow => 'Speaking…';
  @override
  String get holdToTalk => 'Hold to talk';
  @override
  String get callOptions => 'Start a call';
  @override
  String get callWithRing => 'Call with ring';
  @override
  String get callWithRingDesc => 'Rings everyone — talk after they answer.';
  @override
  String get transmitVoice => 'Broadcast voice (no ring)';
  @override
  String get transmitVoiceDesc => 'Your voice reaches everyone instantly.';
  @override
  String get stopBroadcast => 'Stop broadcast';
  @override
  String get ringingMembers => 'Ringing members… hold the mic to talk';
  @override
  String get broadcastOn => 'Live broadcast is on — everyone hears you now';
  @override
  String get broadcastOff => 'Broadcast stopped';
  @override
  String get leaveAudio => 'Leave audio';
  @override
  String get noMembersToCall => 'No members online to call.';
  @override
  String get micRequired => 'Microphone permission is required to talk.';
  @override
  String get messages => 'Messages';
  @override
  String get typeMessage => 'Type a message…';
  @override
  String get noMessages => 'No messages yet';
  @override
  String get noMessagesBody => 'Start the conversation with text or a photo';
  @override
  String get profile => 'Profile';
  @override
  String get savedChanges => 'Changes saved';
  @override
  String get settings => 'Settings';
  @override
  String get appearance => 'Appearance';
  @override
  String get theme => 'Theme';
  @override
  String get darkMode => 'Dark';
  @override
  String get lightMode => 'Light';
  @override
  String get systemMode => 'System';
  @override
  String get language => 'Language';
  @override
  String get arabic => 'العربية';
  @override
  String get english => 'English';
  @override
  String get permissionsTitle => 'Permissions';
  @override
  String get openPermissions => 'Review permissions';
  @override
  String get designedBy => 'Designed & built by';
  @override
  String get designerName => 'Bareq Maher';
  @override
  String get aboutApp => 'About SoundMesh';
  @override
  String get aboutAppBody =>
      'Offline intercom over local WiFi. Voice, calls, messages and images — no internet, no servers.';
  @override
  String get permGateTitle => 'Enable permissions';
  @override
  String get permGateBody =>
      'SoundMesh needs these to ring you and play voice even when closed.';
  @override
  String get permGrant => 'Enable';
  @override
  String get permGranted => 'Granted';
  @override
  String get permAllSet => 'All set!';
  @override
  String get permEnterApp => 'Enter SoundMesh';
  @override
  String get permMicTitle => 'Microphone';
  @override
  String get permMicBody => 'To capture and transmit your voice.';
  @override
  String get permNotifTitle => 'Notifications';
  @override
  String get permNotifBody => 'To show incoming calls and ringing.';
  @override
  String get permOverlayTitle => 'Display over other apps';
  @override
  String get permOverlayBody =>
      'Lets the app wake and open for incoming voice — essential on Samsung.';
  @override
  String get permBatteryTitle => 'Unrestricted battery';
  @override
  String get permBatteryBody =>
      'Keeps you reachable in the background. Turn off battery limits.';
  @override
  String get permOpenSettings => 'Open settings';
  @override
  String get incomingCall => 'Incoming call';
  @override
  String get incomingGroupCall => 'Incoming group call';
  @override
  String get callingYou => 'is calling you on SoundMesh…';
  @override
  String get accept => 'Accept';
  @override
  String get decline => 'Decline';
}

class ArText extends AppText {
  @override
  String get localeCode => 'ar';
  @override
  String get appName => 'SoundMesh';
  @override
  String get appTagline => 'تحدّث عبر محيطك — بلا إنترنت.';
  @override
  String get next => 'التالي';
  @override
  String get start => 'لنبدأ';
  @override
  String get cancel => 'إلغاء';
  @override
  String get save => 'حفظ';
  @override
  String get continueLabel => 'متابعة';
  @override
  String get retry => 'إعادة';
  @override
  String get you => 'أنت';
  @override
  String get welcomeTitle => 'SoundMesh';
  @override
  String get welcomeBody =>
      'إنتركوم مستقبلي يربط الجميع عبر شبكة WiFi المحلية — بلا إنترنت تماماً.';
  @override
  String get feature1Title => 'تحدّثوا معاً';
  @override
  String get feature1Body =>
      'اضغط لتتكلّم أو افتح المايك — الكل يسمع الكل لحظياً.';
  @override
  String get feature2Title => 'رنين ووصول';
  @override
  String get feature2Body =>
      'اتصل بأي شخص حتى لو كان تطبيقه مغلقاً، أو مرّر صوتك بصمت.';
  @override
  String get createAccount => 'أنشئ ملفك الشخصي';
  @override
  String get yourName => 'الاسم';
  @override
  String get nameHint => 'اكتب اسمك';
  @override
  String get phone => 'رقم الهاتف';
  @override
  String get phoneHint => '07xx xxx xxxx';
  @override
  String get pickAvatar => 'اختر صورة أو أفاتاراً';
  @override
  String get aboutYou => 'نبذة';
  @override
  String get channelName => 'قناة Mesh';
  @override
  String get channelDesc => 'قناة WiFi محلية · بلا إنترنت';
  @override
  String get connected => 'متصل';
  @override
  String get connecting => 'جارٍ الاتصال…';
  @override
  String get members => 'الأعضاء';
  @override
  String get onlineNow => 'المتصلون';
  @override
  String get waitingToSpeak => 'اضغط مع الاستمرار على المايك للتحدّث';
  @override
  String get speakingNow => 'يتحدّث الآن…';
  @override
  String get holdToTalk => 'اضغط للتحدّث';
  @override
  String get callOptions => 'ابدأ اتصالاً';
  @override
  String get callWithRing => 'اتصال برنين';
  @override
  String get callWithRingDesc => 'يرنّ عند الجميع — تتحدّثون بعد الردّ.';
  @override
  String get transmitVoice => 'تمرير الصوت (بدون رنين)';
  @override
  String get transmitVoiceDesc => 'صوتك يصل للجميع فوراً.';
  @override
  String get stopBroadcast => 'إيقاف البثّ';
  @override
  String get ringingMembers => 'يرنّ عند الأعضاء… اضغط المايك للتحدّث';
  @override
  String get broadcastOn => 'البثّ المباشر مُفعّل — الجميع يسمعك الآن';
  @override
  String get broadcastOff => 'تم إيقاف البثّ';
  @override
  String get leaveAudio => 'مغادرة الصوت';
  @override
  String get noMembersToCall => 'لا يوجد أعضاء متصلون للاتصال بهم.';
  @override
  String get micRequired => 'إذن الميكروفون مطلوب للتحدّث.';
  @override
  String get messages => 'الرسائل';
  @override
  String get typeMessage => 'اكتب رسالة…';
  @override
  String get noMessages => 'لا رسائل بعد';
  @override
  String get noMessagesBody => 'ابدأ المحادثة برسالة أو صورة';
  @override
  String get profile => 'الملف الشخصي';
  @override
  String get savedChanges => 'تم حفظ التغييرات';
  @override
  String get settings => 'الإعدادات';
  @override
  String get appearance => 'المظهر';
  @override
  String get theme => 'الوضع';
  @override
  String get darkMode => 'ليلي';
  @override
  String get lightMode => 'نهاري';
  @override
  String get systemMode => 'النظام';
  @override
  String get language => 'اللغة';
  @override
  String get arabic => 'العربية';
  @override
  String get english => 'English';
  @override
  String get permissionsTitle => 'الأذونات';
  @override
  String get openPermissions => 'مراجعة الأذونات';
  @override
  String get designedBy => 'تصميم وتطوير';
  @override
  String get designerName => 'بارق ماهر';
  @override
  String get aboutApp => 'عن SoundMesh';
  @override
  String get aboutAppBody =>
      'إنتركوم يعمل دون إنترنت عبر شبكة WiFi المحلية. صوت ومكالمات ورسائل وصور — بلا إنترنت ولا خوادم.';
  @override
  String get permGateTitle => 'فعّل الأذونات';
  @override
  String get permGateBody =>
      'يحتاج SoundMesh هذه الأذونات ليرنّ ويشغّل الصوت حتى وهو مغلق.';
  @override
  String get permGrant => 'تفعيل';
  @override
  String get permGranted => 'مُفعّل';
  @override
  String get permAllSet => 'كل شيء جاهز!';
  @override
  String get permEnterApp => 'ادخل SoundMesh';
  @override
  String get permMicTitle => 'الميكروفون';
  @override
  String get permMicBody => 'لالتقاط صوتك وبثّه.';
  @override
  String get permNotifTitle => 'الإشعارات';
  @override
  String get permNotifBody => 'لعرض المكالمات الواردة والرنين.';
  @override
  String get permOverlayTitle => 'الظهور فوق التطبيقات';
  @override
  String get permOverlayBody =>
      'يسمح للتطبيق بالاستيقاظ والفتح للصوت الوارد — ضروري على سامسونج.';
  @override
  String get permBatteryTitle => 'بطارية بلا قيود';
  @override
  String get permBatteryBody =>
      'تُبقيك متاحاً في الخلفية. أوقف قيود البطارية.';
  @override
  String get permOpenSettings => 'فتح الإعدادات';
  @override
  String get incomingCall => 'اتصال وارد';
  @override
  String get incomingGroupCall => 'اتصال جماعي وارد';
  @override
  String get callingYou => 'يتصل بك عبر SoundMesh…';
  @override
  String get accept => 'قبول';
  @override
  String get decline => 'رفض';
}
