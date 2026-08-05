import 'dart:ui';

import 'package:window_manager/window_manager.dart';
import 'package:windows_single_instance/windows_single_instance.dart';

class WindowsManage {
  static Future<void> initialize(List<String> args) async {
    await windowManager.ensureInitialized();
    await WindowsSingleInstance.ensureSingleInstance(
      args,
      "armazem_app_custom_id", // Identificador único do app
    );

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
