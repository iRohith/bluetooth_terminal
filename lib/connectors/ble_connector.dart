import 'dart:async';
import 'dart:io';

import 'package:bluetooth_terminal/ui/widgets/select_device_dialog.dart';
import 'package:bluetooth_terminal/utils/permission_handler.dart';
import 'package:bluetooth_terminal/utils/util.dart';
import 'package:bluetooth_terminal/connectors/base_connector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:universal_ble/universal_ble.dart';

class BleConnector extends BaseConnector {
  static final suuid = ("6db99c15-8890-4fa8-8138-2a1a55deebbf");
  static final wcuuid = ("c389bbb2-c68e-4a4e-8f62-8e0f0fa7e4c6");
  static final rcuuid = ("95e8186c-6ed1-42e8-a1e2-22dfa4c11f68");

  BleDevice? connectedDevice;

  final bluetoothOn = false.obs;

  @override
  Future<bool> init() async {
    if (!(await PermissionHandler.areBtPermissionsGranted())) {
      await showSnackbar("Error", "Missing permissions");
      return false;
    }

    final state = await UniversalBle.getBluetoothAvailabilityState();

    if (state == AvailabilityState.poweredOff) {
      await Get.defaultDialog(
        title: "Turn bluetooth on",
        middleText: "",
        actions: [
          TextButton(
            onPressed: () async {
              if (!kIsWeb && Platform.isAndroid) {
                await UniversalBle.enableBluetooth();
              }
              Get.back();
            },
            child: const Text("Ok"),
          ),
          TextButton(
            onPressed: () {
              Get.back();
            },
            child: const Text("Cancel"),
          ),
        ],
      );

      UniversalBle.onAvailabilityChange = (s) {
        bluetoothOn.trigger(s == AvailabilityState.poweredOn);
      };

      if (await bluetoothOn.stream.first == false) {
        await showSnackbar("Error", "Turn on bluetooth");
        return false;
      }
    } else if (state != AvailabilityState.poweredOn) {
      await showSnackbar("Error", "Unknown bluetooth state");
      return false;
    }

    return true;
  }

  @override
  Future<bool> dispose() async {
    return true;
  }

  @override
  Future<bool> connect() async {
    final devices = <(String, String)>[].obs;
    final deviceMap = <String, BleDevice>{};

    for (final d in await UniversalBle.getSystemDevices(
      withServices: [suuid],
    )) {
      devices.add(((d.name ?? "").isEmpty ? "Unknown" : d.name!, d.deviceId));

      deviceMap[d.deviceId] = d;
    }

    UniversalBle.onScanResult = (d) {
      deviceMap[d.deviceId] = d;

      var idx = devices.indexWhere((v) => v.$2 == d.deviceId);

      final val = ((d.name ?? "").isEmpty ? "Unknown" : d.name!, d.deviceId);

      if (idx == -1) {
        devices.add(val);
      } else {
        devices[idx] = val;
      }
    };

    await UniversalBle.startScan();

    bool connected =
        true ==
        await Get.dialog(
          SelectDeviceDialog(
            name: "BLE device",
            devices: devices,
            connectCallback: (_, d) async {
              try {
                await UniversalBle.stopScan();
                printInfo(info: "Connecting...");
                UniversalBle.connect(d);

                UniversalBle.onConnectionChange = (
                  deviceId,
                  isConnected,
                  error,
                ) async {
                  if (isConnected) {
                    await UniversalBle.discoverServices(d);
                    UniversalBle.requestMtu(d, 512);
                    await UniversalBle.setNotifiable(
                      deviceId,
                      suuid,
                      rcuuid,
                      BleInputProperty.notification,
                    );
                    connectedDevice = deviceMap[d]!;
                    printInfo(info: "Connected: $d");
                    this.connected.trigger(true);

                    UniversalBle.onConnectionChange = (_, c, _) {
                      this.connected.value = c;
                    };
                  } else {
                    this.connected.trigger(false);
                  }
                };

                Get.back(result: await this.connected.stream.first);
              } catch (e, st) {
                printError(info: "$e\n$st");
                Get.back(result: false);
              }
            },
          ),
        );

    return connected;
  }

  @override
  Future<bool> disconnect() async {
    await tryFunc(
      () => UniversalBle.disconnect(connectedDevice!.deviceId),
      name: "BLE Disconnect",
    );
    connectedDevice = null;
    connected.value = false;
    return true;
  }

  @override
  Stream<int> read() {
    printInfo(info: "Connected... Reading...");
    showSnackbar("Connected", "");

    final s = StreamController<int>();

    UniversalBle.onValueChange = (
      String deviceId,
      String characteristicId,
      Uint8List value,
    ) async {
      try {
        if (deviceId == connectedDevice?.deviceId &&
            characteristicId.toLowerCase() == rcuuid.toLowerCase()) {
          for (final b in value) {
            s.add(b);
          }
        }
      } catch (e, st) {
        s.add(-1);
        printError(info: "Ble read error: $e\n$st");
        connected.value = false;
        UniversalBle.onValueChange = (_, _, _) {};
      }
    };

    return s.stream;
  }

  @override
  Future<int> write(Uint8List buffer) async {
    try {
      UniversalBle.writeValue(
        connectedDevice!.deviceId,
        suuid,
        wcuuid,
        buffer,
        BleOutputProperty.withResponse,
      );
      return buffer.length;
    } catch (e, st) {
      printError(info: "BLE Write error: $e\n$st");
      return -1;
    }
  }
}
