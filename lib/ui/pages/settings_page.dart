import 'package:bluetooth_terminal/services/connection_service.dart';
import 'package:bluetooth_terminal/services/data_service.dart';
import 'package:bluetooth_terminal/services/settings_service.dart';
import 'package:bluetooth_terminal/services/storage_service.dart';
import 'package:bluetooth_terminal/ui/pages/page_wrapper.dart';
import 'package:bluetooth_terminal/ui/widgets/panels/base_panel.dart';
import 'package:bluetooth_terminal/utils/routes.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final ds = DataService.to;

    final ssid = ds.getVar("ssid", "", save: true);
    final username = ds.getVar("username", "", save: true);
    final pwd = ds.getVar("pwd", "", save: true);
    final wsrelay = ds.getVar("wsrelay", "ws://", save: true);

    final ssidCtrl = TextEditingController(text: ssid.value);
    final usernameCtrl = TextEditingController(text: username.value);
    final pwdCtrl = TextEditingController(text: pwd.value);
    final wsrelayCtrl = TextEditingController(text: wsrelay.value);

    ssidCtrl.addListener(() => ssid.value = ssidCtrl.text);
    usernameCtrl.addListener(() => username.value = usernameCtrl.text);
    pwdCtrl.addListener(() => pwd.value = pwdCtrl.text);
    wsrelayCtrl.addListener(() => wsrelay.value = wsrelayCtrl.text);

    return PageWrapper(
      title: "Settings",
      useScroll: false,
      panels: [
        BasePanel(
          title: "Settings",
          id: "settings",
          width: Get.width * 0.8,
          constraintHeight: false,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              spacing: 12,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Dark Theme",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                    ObxValue(
                      (isDarkMode) => Switch(
                        value: isDarkMode.value,
                        onChanged: (value) => isDarkMode.value = value,
                      ),
                      SettingsService.to.isDarkMode,
                    ),
                  ],
                ),
                ElevatedButton(
                  onPressed: () async {
                    await StorageService.to.reset();
                    SettingsService.to.reset();
                    ConnectionService.to.reset();
                    DataService.to.reset();
                    Get.offAllNamed(Routes.connection);

                    Get.snackbar(
                      "App reset",
                      "",
                      snackPosition: SnackPosition.BOTTOM,
                      duration: const Duration(seconds: 2),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    backgroundColor: Get.theme.colorScheme.primaryContainer,
                    foregroundColor: Get.theme.colorScheme.onPrimaryContainer,
                    elevation: 8,
                  ),
                  child: const Text("Reset App"),
                ),
              ],
            ),
          ),
        ),

        BasePanel(
          id: "wifi",
          title: "Wifi",
          width: Get.width * 0.8,
          constraintHeight: false,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              spacing: 12,
              children: [
                TextField(
                  controller: ssidCtrl,
                  decoration: InputDecoration(
                    labelText: "SSID",
                    border: const OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.name,
                  maxLines: 1,
                ),

                ValueBuilder<bool?>(
                  initialValue: true,
                  builder:
                      (obscureText, updateFn) => TextField(
                        controller: pwdCtrl,
                        keyboardType: TextInputType.visiblePassword,
                        maxLines: 1,
                        decoration: InputDecoration(
                          labelText: "Password",
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            icon: Icon(
                              obscureText!
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              color: Colors.grey,
                            ),
                            onPressed: () => updateFn(!obscureText),
                          ),
                        ),
                        obscureText: obscureText,
                      ),
                ),

                TextField(
                  controller: usernameCtrl,
                  decoration: InputDecoration(
                    labelText: "WPA2 Username",
                    border: const OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.name,
                  maxLines: 1,
                ),

                TextField(
                  controller: wsrelayCtrl,
                  decoration: InputDecoration(
                    labelText: "WS Relay URL",
                    border: const OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.name,
                  maxLines: 1,
                ),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton(
                      onPressed: () async {
                        ConnectionService.to.writeMessage(
                          "SSID:${ssid.value};;PWD:${pwd.value};;USERNAME:${username.value}",
                          log: false,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        backgroundColor: Get.theme.colorScheme.primaryContainer,
                        foregroundColor:
                            Get.theme.colorScheme.onPrimaryContainer,
                        elevation: 8,
                      ),
                      child: const Text("Send Creds"),
                    ),

                    ElevatedButton(
                      onPressed: () async {
                        ConnectionService.to.writeMessage(
                          "WSRELAY:${wsrelay.value}",
                          log: false,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        backgroundColor: Get.theme.colorScheme.primaryContainer,
                        foregroundColor:
                            Get.theme.colorScheme.onPrimaryContainer,
                        elevation: 8,
                      ),
                      child: const Text("Send Relay"),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
