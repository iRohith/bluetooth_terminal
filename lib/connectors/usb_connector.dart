import 'dart:async';

import 'package:bluetooth_terminal/ui/widgets/select_device_dialog.dart';
import 'package:bluetooth_terminal/utils/util.dart';
import 'package:bluetooth_terminal/connectors/base_connector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_libserialport/flutter_libserialport.dart';
import 'package:get/get.dart';

class UsbConnector extends BaseConnector {
  SerialPort? _connectedPort;
  StreamSubscription? _scanSubscription;

  final devices = <(String, String)>[].obs;

  @override
  Future<bool> init() async {
    for (final port in await SerialPort.availablePorts) {
      devices.add((port, ""));
    }

    _scanSubscription = Stream.periodic(
      2.seconds,
      (_) => SerialPort.availablePorts,
    ).listen((results) async {
      for (final port in await results) {
        final idx = devices.indexWhere((v) => v.$1 == port);

        if (idx == -1) {
          devices.add((port, ""));
        } else {
          devices[idx] = (port, "");
        }
      }
    });

    printInfo(info: "Ports length: ${devices.length}");

    return true;
  }

  @override
  Future<bool> dispose() async {
    _scanSubscription?.cancel();
    return true;
  }

  @override
  Future<bool> connect() async {
    try {
      connected.value =
          true ==
          await Get.dialog(
            SelectDeviceDialog(
              name: "USB device",
              devices: devices,
              connectCallback: (p, _) async {
                try {
                  final conn = SerialPort(p);

                  String msg =
                      (await tryFunc(
                        conn.openReadWrite,
                        name: "USB openReadWrite",
                      )).msg;
                  if (msg != "OK") {
                    throw Exception(msg);
                  }

                  final cfg =
                      (await tryFunc(
                        () => conn.config,
                        name: "USB Get Config",
                      )).result ??
                      SerialPortConfig();

                  msg =
                      (await tryFunc(
                        () => conn.setConfig(cfg..baudRate = 115200),
                        name: "USB Set Config"
                      )).msg;
                  if (msg != "OK") {
                    throw Exception(msg);
                  }

                  _connectedPort = conn;
                  Get.back(result: true);
                } catch (e, st) {
                  printError(info: "$e\n$st");
                  Get.back(result: false);
                }
              },
            ),
          );
      return connected.value;
    } catch (e, st) {
      printError(info: "USB connect error: $e\n$st");
      return false;
    }
  }

  @override
  Future<bool> disconnect() async {
    try {
      _connectedPort?.close();
      _connectedPort?.dispose();
      _connectedPort = null;
      connected.value = false;
      return true;
    } catch (e, st) {
      printError(info: "USB dipose error: $e\n$st");
      return false;
    }
  }

  @override
  Stream<int> read() {
    printInfo(info: "Connected... Reading...");
    showSnackbar("Connected", "");

    SerialPortReader reader = SerialPortReader(_connectedPort!);
    return reader.stream.expand<int>((v) => v);
  }

  @override
  Future<int> write(Uint8List buffer) async {
    try {
      return _connectedPort!.write(buffer);
    } catch (e, st) {
      printError(info: "USB Write error: $e\n$st");
      return -1;
    }
  }
}
