import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:bluetooth_terminal/connectors/base_connector.dart';
import 'package:bluetooth_terminal/connectors/mock_connector.dart';
import 'package:bluetooth_terminal/modals/data_packet.dart';
import 'package:bluetooth_terminal/services/log_service.dart';
import 'package:bluetooth_terminal/services/storage_service.dart';
import 'package:bluetooth_terminal/utils/constants.dart';
import 'package:bluetooth_terminal/utils/routes.dart';
import 'package:bluetooth_terminal/utils/util.dart';
import 'package:crypto/crypto.dart';
import 'package:get/get.dart';

class ConnectionService extends GetxService {
  static ConnectionService get to => Get.find();

  final connectors =
      <String, BaseConnector Function()>{"None": () => MockConnector()}.obs;

  final storageService = StorageService.to;
  final logService = LogService.to;
  final connectionType = "None".obs;
  final connected = false.obs;

  final currentPacket = DataPacket(cmd: 0, id: 0, value: 0).obs;
  final numBytesReceived = 0.obs;

  Worker? _connectionTypeWorker, _connectionDisposeWorker;
  StreamSubscription<DataPacket>? _dataStream;
  BaseConnector _connector = MockConnector();

  @override
  void onInit() {
    super.onInit();

    _connectionTypeWorker?.dispose();
    _connectionTypeWorker = ever(connectionType, (c) async {
      await disposeConnector();

      if ("OK" !=
          (await tryFunc(() async {
            final fn = connectors[c]!;
            _connector = fn();
          }, name: "Find connector")).msg) {
        reset();
        showSnackbar("Error", "Invalid connector");
        return;
      }

      _connectionDisposeWorker = ever(_connector.connected, (connected) async {
        this.connected.value = connectionType.value != "None" && connected;
        if (!connected) {
          await disposeConnector();
          reset();
        }
      });

      if ("OK" !=
          (await tryFunc(
            _connector.init,
            timeout: 5.seconds,
            name: "Init connector",
          )).msg) {
        reset();
        showSnackbar("Error", "Init failed");
        return;
      }

      if ("OK" !=
          (await tryFunc(
            _connector.connect,
            timeout: 60.seconds,
            name: "Connect connector",
          )).msg) {
        reset();
        showSnackbar("Error", "Connect failed");
        return;
      }

      if (_connector.connected.value) {
        start();

        if (connectionType.value != "None") {
          Get.offAllNamed(Routes.home);
        }
      } else {
        reset();
        showSnackbar("Error", "Connection failed");
      }
    });
  }

  @override
  void onClose() async {
    reset();

    _connectionTypeWorker?.dispose();
    _connectionTypeWorker = null;

    super.onClose();
  }

  void start() {
    _dataStream?.cancel();
    _dataStream = _connector
        .read()
        .transform(dataPacketTransformer())
        .listen(
          (dp) {
            currentPacket.value = dp;
            _connector.connected.value = true;
          },
          onError: (e, st) {
            printError(info: "error in data stream: $e\n$st");
            reset();
          },
          onDone: () {
            printInfo(info: "Done");
            reset();
          },
          cancelOnError: true,
        );
  }

  void reset() {
    while (Get.isDialogOpen!) {
      Get.back();
    }
    connectionType.value = "None";
  }

  Future<void> disposeConnector() async {
    await tryFunc(() async {
      _dataStream?.cancel();
      _dataStream = null;
      _connectionDisposeWorker?.dispose();
      _connectionDisposeWorker = null;
      await _connector.disconnect();
      await _connector.dispose();

      if (!(_connector is MockConnector &&
          (_connector as MockConnector).idleMode)) {
        showSnackbar("Disconnected", "");
      }
    }, name: "disposeConnector");
  }

  Future<bool> writeDataPacket(DataPacket dp) async {
    if (connectionType.value == "None" || _connector.connected.value == false) {
      return false;
    }

    final buffer = dp.toBuffer(null);

    final res = await tryFunc<int>(() => _connector.write(buffer));

    if (res.msg == "OK") {
      if (dp.cmd != PING) {
        LogService.to.logSend(
          "${res.result != buffer.length ? "Partial(${res.result}) sent; " : ""}$dp",
        );
      }
    } else {
      LogService.to.logSend("Failed => $dp; Error: ${res.msg}");
    }

    return res.result == buffer.length;
  }

  Future<bool> writeMessage(String msg, {bool log = true}) async {
    final bytes =
        DataPacket(
          cmd: MSG_SEND,
          id: 0,
          value: msg.length.toDouble(),
        ).toBuffer(null).toList();
    bytes.addAll(utf8.encode(msg));
    final res = await tryFunc<int>(
      () => _connector.write(Uint8List.fromList(bytes)),
      name: "Write message",
    );

    if (res.result == bytes.length) {
      if (log) {
        LogService.to.logSend("Msg: $msg, Cmd: $MSG_SEND");
      }
    } else {
      LogService.to.logSend(
        "Failed => Msg: $msg, Cmd: $MSG_SEND; Error: ${res.msg}",
      );
    }

    return res.result == bytes.length;
  }

  Future<bool> sendProtected(String pwd, Uint8List? bytes) async {
    if (bytes == null) {
      showSnackbar("Error", "No file selected");
      return false;
    }

    final pwdBytes =
        utf8.encode(sha256.convert(utf8.encode(pwd)).toString()).toList();
    pwdBytes.insert(0, PASSWORD_SEND);

    final result = await tryFunc<int>(
      () => _connector.write(Uint8List.fromList(pwdBytes)),
      name: "Send password",
    );

    if (result.result != pwdBytes.length) {
      showSnackbar("Error", "Failed to validate password");
      return false;
    }

    showSnackbar(
      "Validating password...",
      "Waiting for response",
      showProgressIndicator: true,
      duration: const Duration(seconds: 10),
    );

    final completer = Completer<bool>();

    Worker w = once(
      currentPacket,
      (dp) async {
        final result =
            dp.cmd != PASSWORD_VALID
                ? TryResponse(-1, "Invalid password")
                : await tryFunc<int>(
                  () => _connector.write(bytes),
                  name: "Write protected",
                );

        if (result.result == bytes.length) {
          showSnackbar("Success", "Sent data");
          completer.complete(true);
        } else {
          showSnackbar("Error", result.msg);
          completer.complete(false);
        }
      },
      condition:
          () => [
            PASSWORD_VALID,
            PASSWORD_INVALID,
          ].contains(currentPacket.value.cmd),
    );

    return (await tryFunc(
          () => completer.future,
          showSnackBar: true,
          name: "Send protected",
          onTimeout: () => w.dispose(),
        )).msg ==
        "OK";
  }
}
