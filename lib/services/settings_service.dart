import 'dart:async';

import 'package:bluetooth_terminal/modals/data_packet.dart';
import 'package:bluetooth_terminal/services/connection_service.dart';
import 'package:bluetooth_terminal/services/log_service.dart';
import 'package:bluetooth_terminal/services/storage_service.dart';
import 'package:bluetooth_terminal/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SettingsService extends GetxService {
  static SettingsService get to => Get.find();

  final logService = LogService.to;
  final cs = ConnectionService.to;

  final isDarkMode =
      (StorageService.to.prefs.getBool("isDarkMode") ?? true).obs;

  final speed = 0.0.obs;
  final latency = 0.0.obs;
  final varsPerSecond = 0.0.obs;

  final _stopwatch = Stopwatch()..start();

  double get seconds => _stopwatch.elapsedMilliseconds * 0.001;

  SettingsService() {
    Get.engine.addPostFrameCallback((_) {
      final c = StorageService.to.prefs.getString("connectionType");

      if (c != null && c != "None") {
        cs.connectionType.trigger(c);
      }
    });

    int vars = 0;
    int lastPingMs = 0, lastUpdateMs = 0;
    final pings = <double>[];

    ever(cs.currentPacket, (dp) {
      final ms = _stopwatch.elapsedMilliseconds;

      if (dp.cmd == FLOAT_RECV) {
        vars += 1;
      } else if (dp.cmd == PING) {
        if (ms - lastUpdateMs > 1000) {
          final s = 1000.0 / (ms - lastUpdateMs);
          varsPerSecond.value = vars * s;
          speed.value = s * cs.numBytesReceived.value / 1024;

          cs.numBytesReceived.value = 0;
          vars = 0;
          lastUpdateMs = ms;
        }

        pings.add(0.5 * (ms - lastPingMs));

        if (pings.length >= 5) {
          latency.value = pings.reduce((a, b) => a + b) / pings.length;
          pings.clear();
        }
      }
    });

    Timer.periodic(const Duration(milliseconds: 500), (_){
      if (cs.connected.value) {
        cs.writeDataPacket(DataPacket(cmd: PING, id: 0));
      }

      lastPingMs = _stopwatch.elapsedMilliseconds;
    });

    ever(
      isDarkMode,
      (value) => Get.changeThemeMode(value ? ThemeMode.dark : ThemeMode.light),
    );

    ever(cs.connectionType, (c) async {
      if (c != "None") {
        StorageService.to.prefs.setString("connectionType", c);
      } else {
        latency.value = 0;
      }
    });

    ever(cs.connected, (c) {
      latency.value = 0;
      speed.value = 0;
      varsPerSecond.value = 0;
      vars = 0;
    });
  }

  void reset() {
    isDarkMode.value = true;
  }
}
