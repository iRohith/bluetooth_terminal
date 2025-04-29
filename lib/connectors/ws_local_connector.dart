import 'dart:async';
import 'dart:typed_data';

import 'package:bluetooth_terminal/services/data_service.dart';
import 'package:bluetooth_terminal/utils/util.dart';
import 'package:bluetooth_terminal/connectors/base_connector.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:web_socket/web_socket.dart';

class WSLocalConnector extends BaseConnector {
  final wsurl = DataService.to.getVar("websocket_url", "ws://", save: true);
  WebSocket? ws;

  @override
  Future<bool> init() async {
    return true;
  }

  @override
  Future<bool> dispose() async {
    ws?.close();
    ws = null;
    return true;
  }

  @override
  Future<bool> connect() async {
    try {
      final ctrl = TextEditingController(text: wsurl.value);
      ctrl.addListener(() => wsurl.value = ctrl.text);
      final connecting = false.obs;

      connected.value =
          true ==
          await Get.dialog(
            AlertDialog(
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("WebSocket"),

                  Obx(
                    () =>
                        connecting.value
                            ? const CircularProgressIndicator()
                            : const SizedBox(),
                  ),
                ],
              ),
              content: TextField(
                controller: ctrl,
                decoration: InputDecoration(
                  labelText: "URL",
                  border: const OutlineInputBorder(),
                ),
                keyboardType: TextInputType.url,
                maxLines: 1,
              ),
              actions: [
                TextButton(
                  onPressed: () async {
                    try {
                      connecting.value = true;
                      ws = await WebSocket.connect(Uri.parse(wsurl.value));
                      Get.back(result: true);
                    } catch (e, st) {
                      printError(info: "$e\n$st");
                      Get.back(result: false);
                      ws = null;
                    }
                  },
                  child: Text("Ok"),
                ),

                TextButton(
                  onPressed: () async {
                    Get.back(result: false);
                  },
                  child: Text("Cancel"),
                ),
              ],
            ),
          );
      connecting.value = false;
      return connected.value;
    } catch (e, st) {
      printError(info: "WS connect error: $e\n$st");
      return false;
    }
  }

  @override
  Future<bool> disconnect() async {
    try {
      ws?.close();
      ws = null;
      connected.value = false;
      return true;
    } catch (e, st) {
      printError(info: "WS dispose error: $e\n$st");
      return false;
    }
  }

  @override
  Stream<int> read() {
    printInfo(info: "Connected... Reading...");
    showSnackbar("Connected", "");

    final empty = Uint8List(0);

    // return ws!.stream.cast<Uint8List>().expand((e) => e);
    return ws!.events
        .map<Uint8List>((e) {
          switch (e) {
            case TextDataReceived():
              break;
            case BinaryDataReceived(data: final data):
              return data;
            case CloseReceived(code: final code, reason: final reason):
              printInfo(info: "WS Closed: $code; $reason");
              return Uint8List.fromList([-1]);
          }
          return empty;
        })
        .expand((e) => e);
  }

  @override
  Future<int> write(Uint8List buffer) async {
    try {
      // ws!.sink.add(buffer);
      ws!.sendBytes(buffer);
      return buffer.length;
    } catch (e, st) {
      printError(info: "WS Write error: $e\n$st");
      return -1;
    }
  }
}
