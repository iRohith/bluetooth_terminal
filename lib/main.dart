import 'dart:io';

import 'package:bluetooth_terminal/connectors/ble_connector.dart';
import 'package:bluetooth_terminal/connectors/bt_connector.dart';
import 'package:bluetooth_terminal/connectors/mock_connector.dart';
import 'package:bluetooth_terminal/connectors/usb_connector.dart';
import 'package:bluetooth_terminal/connectors/ws_cloud_connector.dart';
import 'package:bluetooth_terminal/connectors/ws_local_connector.dart';
import 'package:bluetooth_terminal/services/connection_service.dart';
import 'package:bluetooth_terminal/services/data_service.dart';
import 'package:bluetooth_terminal/services/log_service.dart';
import 'package:bluetooth_terminal/services/settings_service.dart';
import 'package:bluetooth_terminal/services/storage_service.dart';
import 'package:bluetooth_terminal/ui/pages/charts_page.dart';
import 'package:bluetooth_terminal/ui/pages/connection_page.dart';
import 'package:bluetooth_terminal/ui/pages/home_page.dart';
import 'package:bluetooth_terminal/ui/pages/keypad_page.dart';
import 'package:bluetooth_terminal/ui/pages/logs_page.dart';
import 'package:bluetooth_terminal/ui/pages/send_file_page.dart';
import 'package:bluetooth_terminal/ui/pages/settings_page.dart';
import 'package:bluetooth_terminal/ui/pages/variables_page.dart';
import 'package:bluetooth_terminal/utils/routes.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

void main() async {
  await initServices();
  initConnectors();
  runApp(const MyApp());
}

Future<void> initServices() async {
  Get.put<LogService>(LogService());

  await Get.putAsync<StorageService>(() async {
    final s = StorageService();
    await s.init();
    return s;
  });

  Get.put<ConnectionService>(ConnectionService());
  Get.put<SettingsService>(SettingsService());
  Get.put<DataService>(DataService());
}

void initConnectors(){
  final cs = ConnectionService.to;

  cs.connectors["BLE"] = () => BleConnector();

  if (!kIsWeb && Platform.isAndroid) {
    cs.connectors["BT Classic"] = () => BTConnector();
  }

  cs.connectors["USB"] = () => UsbConnector();
  cs.connectors["WS Local"] = () => WSLocalConnector();
  cs.connectors["WS Cloud"] = () => WSCloudConnector();
  cs.connectors["Test"] = () => MockConnector(idleMode: false);
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    Get.changeThemeMode(
      SettingsService.to.isDarkMode.value ? ThemeMode.dark : ThemeMode.light,
    );

    return GetMaterialApp(
      title: 'Bluetooth Terminal',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.light,
        ),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
      ),
      defaultTransition: Transition.cupertino,
      debugShowCheckedModeBanner: false,
      initialRoute: Routes.home,
      getPages: [
        GetPage(name: Routes.home, page: () => const HomePage(), title: "Home"),
        GetPage(
          name: Routes.variables,
          page: () => const VariablesPage(),
          title: "Variables",
        ),
        GetPage(
          name: Routes.keypad,
          page: () => const KeypadPage(),
          title: "Keypad",
        ),
        GetPage(
          name: Routes.charts,
          page: () => const ChartsPage(),
          title: "Charts",
        ),
        GetPage(
          name: Routes.sendFile,
          page: () => const SendFilePage(),
          title: "Send File",
        ),
        GetPage(name: Routes.logs, page: () => const LogsPage(), title: "Logs"),
        GetPage(
          name: Routes.connection,
          page: () => const ConnectionPage(),
          title: "Connection",
        ),
        GetPage(
          name: Routes.settings,
          page: () => const SettingsPage(),
          title: "Settings",
        ),
      ],
    );
  }
}
