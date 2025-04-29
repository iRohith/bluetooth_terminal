import 'dart:async';
import 'dart:io';

import 'package:bluetooth_classic/models/device.dart';
import 'package:bluetooth_terminal/ui/widgets/select_device_dialog.dart';
import 'package:bluetooth_terminal/utils/permission_handler.dart';
import 'package:bluetooth_terminal/utils/util.dart';
import 'package:bluetooth_terminal/connectors/base_connector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:bluetooth_classic/bluetooth_classic.dart';
import 'package:universal_ble/universal_ble.dart';

class BTConnector extends BaseConnector {
  static final suuid = "00001101-0000-1000-8000-00805F9B34FB";

  final _bt = BluetoothClassic();

  final bluetoothOn = false.obs;

  Device? connectedDevice;

  static bool subscriptionsAdded = false;
  static Function (Device)? onDeviceDiscovered;
  static Function (int)? onDeviceStatusChanged;

  @override
  Future<bool> init() async {
    if (!(await PermissionHandler.areBtPermissionsGranted()) ||
        !(await _bt.initPermissions())) {
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

    if (!subscriptionsAdded){
      _bt.onDeviceDiscovered().listen((d) => onDeviceDiscovered?.call(d));
      _bt.onDeviceStatusChanged().listen((e) => onDeviceStatusChanged?.call(e));
      subscriptionsAdded = true;
    }

    return true;
  }

  @override
  Future<bool> dispose() async {
    onDeviceDiscovered = null;
    onDeviceStatusChanged = null;
    return true;
  }

  @override
  Future<bool> connect() async {
    final devices = <(String, String)>[].obs;
    final deviceMap = <String, Device>{};

    for (final d in await _bt.getPairedDevices()) {
      devices.add(((d.name ?? "").isEmpty ? "Unknown" : d.name!, d.address));
      deviceMap[d.address] = d;
    }

    onDeviceDiscovered = (d) {
      deviceMap[d.address] = d;

      final idx = devices.indexWhere((v) => v.$2 == d.address);
      final val = ((d.name ?? "").isEmpty ? "Unknown" : d.name!, d.address);

      if (idx == -1) {
        devices.add(val);
      } else {
        devices[idx] = val;
      }
    };

    await _bt.startScan();

    connected.value =
        true ==
        await Get.dialog(
          SelectDeviceDialog(
            name: "Bluetooth device",
            devices: devices,
            connectCallback: (_, d) async {
              try {
                await _bt.stopScan();
                printInfo(info: "Connecting...");

                await _bt.connect(d, suuid);

                onDeviceStatusChanged = (event) {
                  if (event == Device.connected){
                    connected.value = true;
                  } else if (event == Device.disconnected){
                    connected.value = false;
                  }
                };
                Get.back(result: true);
              } catch (e, st) {
                connected.value = false;
                printError(info: "$e\n$st");
                Get.back(result: false);
              }
            },
          ),
        );

    return connected.value;
  }

  @override
  Future<bool> disconnect() async {
    onDeviceDiscovered = null;
    onDeviceStatusChanged = null;
    connectedDevice = null;
    await tryFunc(_bt.disconnect, name: "BT Classic disconnect");
    connected.value = false;
    return true;
  }

  @override
  Stream<int> read() {
    printInfo(info: "Connected... Reading...");
    showSnackbar("Connected", "");

    return _bt.onDeviceDataReceived().expand<int>((v) => v);
  }

  @override
  Future<int> write(Uint8List buffer) async {
    try {
      await _bt.write(String.fromCharCodes(buffer));
      return buffer.length;
    } catch (e, st) {
      printError(info: "BLE Write error: $e\n$st");
      return -1;
    }
  }
}
