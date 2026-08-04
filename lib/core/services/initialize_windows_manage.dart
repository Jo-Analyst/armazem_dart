import 'dart:ui';

import 'package:window_manager/window_manager.dart';

class WindowsManage {
  static Future<void> initialize() async {
    await windowManager.ensureInitialized();

    WindowOptions windowOptions = const WindowOptions(
      minimumSize: Size(800, 600),
      // center: true,
    );

    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.maximize();
      await windowManager.show();
      await windowManager.focus();
    });
  }
}
