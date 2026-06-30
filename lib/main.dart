import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app.dart';
import 'core/background/foreground.dart';
import 'core/session_controller.dart';
import 'core/settings_controller.dart';
import 'data/profile_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  final repo = ProfileRepository();
  await repo.init();
  final settingsBox = await Hive.openBox('settings_box');

  Foreground.initCommunicationPort();
  Foreground.init();

  runApp(
    ProviderScope(
      overrides: [
        profileRepositoryProvider.overrideWithValue(repo),
        settingsBoxProvider.overrideWithValue(settingsBox),
      ],
      child: const WithForegroundTask(child: SoundMeshApp()),
    ),
  );
}
