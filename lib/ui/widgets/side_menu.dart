import 'package:bluetooth_terminal/services/settings_service.dart';
import 'package:bluetooth_terminal/utils/routes.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SideMenu extends StatelessWidget {
  const SideMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        children: [
          SizedBox(
            height: 180,
            child: DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('BT Terminal', style: TextStyle(fontSize: 24)),
                  SizedBox(height: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ObxValue(
                        (speed) => Text(
                          "Speed: ${speed.value.toStringAsFixed(2)} KB/s",
                        ),
                        SettingsService.to.speed,
                      ),

                      ObxValue(
                        (v) => Text("Vars: ${v.value.toStringAsFixed(2)} /s"),
                        SettingsService.to.varsPerSecond,
                      ),

                      ObxValue(
                            (l) => Text("Latency: ${l.value.round()} ms"),
                        SettingsService.to.latency,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          ListTile(
            title: const Text('Home'),
            onTap: () => Get.offAllNamed(Routes.home),
          ),
          ListTile(
            title: const Text('Variables'),
            onTap: () => Get.offAllNamed(Routes.variables),
          ),
          ListTile(
            title: const Text('Keypad'),
            onTap: () => Get.offAllNamed(Routes.keypad),
          ),
          ListTile(
            title: const Text('Charts'),
            onTap: () => Get.offAllNamed(Routes.charts),
          ),
          ListTile(
            title: const Text('Send file'),
            onTap: () => Get.offAllNamed(Routes.sendFile),
          ),
          ListTile(
            title: const Text('Logs'),
            onTap: () => Get.offAllNamed(Routes.logs),
          ),
          const Divider(),
          ListTile(
            title: const Text('Connection'),
            onTap: () => Get.offAllNamed(Routes.connection),
          ),
          ListTile(
            title: const Text('Settings'),
            onTap: () => Get.offAllNamed(Routes.settings),
          ),
        ],
      ),
    );
  }
}
