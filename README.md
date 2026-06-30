# SoundMesh — Offline LAN Walkie‑Talkie & Intercom for Android

**SoundMesh** is a futuristic, fully **offline** intercom for Android. It connects everyone on the same local Wi‑Fi network — **no internet, no SIM, no Bluetooth, no servers** — and lets the whole group talk at the same time, like a real walkie‑talkie.

Built with Flutter. Dark/light themes. English & Arabic.

---

## Features

- **Simple account** — just a name, a phone number, and a photo/avatar.
- **Simultaneous group voice** — everyone hears everyone at once (full‑duplex live audio).
- **Text & image messaging** between everyone on the network.
- **Two talk modes**
  - **Push‑to‑Talk (PTT)** — hold the mic button to speak instantly, no ringing.
  - **Call with ring** — ring a group or an individual, just like a phone call.
  - **Silent broadcast** — push your voice to everyone with no ring at all.
- **Reaches devices even when the app is closed** — incoming calls ring (full‑screen, like WhatsApp/Telegram) and silent broadcasts wake the device, thanks to a background foreground service.
- **Anyone can leave** an active audio session — not just the person who started it.
- **Live speaking animation** shown on *all* connected devices for whoever is talking.
- **Edit your profile** (name / phone / photo) anytime; changes propagate to peers.
- **Settings** — dark/light theme toggle and English/Arabic language toggle.
- **Futuristic UI** — animated sound orb, glassmorphism, neon gradients, smooth transitions.

> **Platform:** Android only. iOS is not supported because its background‑execution model does not allow a closed app to be woken by LAN traffic without internet/push servers.

---

## Requirements

| Tool | Notes |
|------|-------|
| **Flutter SDK** (3.3+) | Install first if not present |
| **JDK 17** | Required to build for Android |
| **Android SDK** | Usually at `%LOCALAPPDATA%\Android\Sdk` |
| Two Android phones on the **same Wi‑Fi** | For real audio testing |

### Installing Flutter (quick)
1. Download Flutter: https://docs.flutter.dev/get-started/install/windows
2. Unzip to e.g. `C:\src\flutter` and add `C:\src\flutter\bin` to your `PATH`.
3. Install JDK 17 and add it to `PATH`.
4. Verify: `flutter doctor` then `flutter doctor --android-licenses`.

---

## Getting Started

```powershell
flutter pub get
```

### Run (debug)
```powershell
flutter run            # single device
flutter run -d <id>    # specific device (list with: flutter devices)
```

To test group voice, run the app on **two phones** connected to the same router.

### Build a release APK
```powershell
flutter build apk --release
```
> A **release** build (AOT) is required for reliable standalone background behavior — the debug APK only works while tethered to `flutter run`.

The output APK is at `build/app/outputs/flutter-apk/app-release.apk`.

---

## How It Works (Architecture)

```
lib/
  core/
    network/
      transport_service.dart    UDP unicast audio + TCP text/images/avatars
      protocol/packet.dart       binary audio frame + control packet encoding
    call/
      call_protocol.dart         JSON call signaling (call / cancel / wake / accept / decline)
      call_service.dart          sends signaling datagrams
      call_task_handler.dart     background isolate: presence beacon, discovery,
                                 call signaling, ring & silent‑wake notifications
    audio/
      audio_service.dart         capture/playback (flutter_sound), PCM16 16 kHz mono
      jitter_buffer.dart         per‑speaker network‑jitter compensation
      mixer.dart                 mixes multiple speakers into one stream
    background/foreground.dart    foreground service setup (runs while app is closed)
    session_controller.dart       central Riverpod controller wiring everything together
    settings_controller.dart      theme + language (persisted with Hive)
    i18n/app_text.dart            English / Arabic UI strings
    theme/                        colors, dark/light palette, app theme
  data/                          profile (Hive) + message store
  features/                      onboarding / home / profile / chat / settings / call / permission
  widgets/                       SoundOrb / GlowMicButton / SpeakingAvatar / Waveform / Glass ...
```

- **Audio:** PCM16, 16 kHz, mono, 20 ms frames. Each speaker sends frames over UDP to every
  connected peer; each device mixes incoming frames into a single playback stream.
- **Discovery:** every device broadcasts its presence every ~2 s on `239.7.7.7:45454`
  (multicast) plus a `255.255.255.255` broadcast fallback.
- **Background:** a `flutter_foreground_task` background isolate keeps presence, discovery and
  call signaling alive even after the app is swiped away, and posts full‑screen ring / silent‑wake
  notifications via `flutter_local_notifications`.

### Network ports
| Purpose | Protocol | Port |
|---------|----------|------|
| Peer discovery / presence beacon | UDP multicast + broadcast | 45454 |
| Live voice | UDP unicast | 45456 |
| Text / images / avatars | TCP | 45455 |
| Call signaling (ring / wake / cancel) | UDP | 45457 |

---

## Permissions

The app requests these on first launch and guides you to enable them:

- **Microphone** — to capture and transmit your voice.
- **Notifications** — to ring and wake for incoming calls/broadcasts.
- **Display over other apps** — lets the call screen appear over the lock screen and wake the
  device from the background (important on Samsung / One UI).
- **Ignore battery optimization** — keeps the background service alive while sleeping.

---

## Troubleshooting

- **Devices don't see each other?** Turn off **AP/Client Isolation** in your router settings and
  make sure both phones are on the **same** network (not the guest network).
- **No audio?** Grant the microphone and notification permissions, and exclude the app from
  battery optimization (the app asks automatically on first connect).
- **No ring when the app is closed?** Use a **release** build, allow "Display over other apps",
  and enable Autostart / disable battery restrictions on aggressive vendors (Xiaomi/MIUI, Samsung).

---

## Testing

```powershell
flutter test                         # unit tests (packet encoding + audio mixing)
flutter analyze                      # static analysis
adb logcat -s flutter                # follow background‑isolate logs (prefix "TW-BG:")
```

---

## Credits

Designed and developed by **Bareq Maher** — https://github.com/bareqmaher-arch
