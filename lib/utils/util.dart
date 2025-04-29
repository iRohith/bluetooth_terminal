import 'dart:async';
import 'dart:typed_data';

import 'package:bluetooth_terminal/modals/data_packet.dart';
import 'package:bluetooth_terminal/services/connection_service.dart';
import 'package:bluetooth_terminal/services/log_service.dart';
import 'package:bluetooth_terminal/services/settings_service.dart';
import 'package:bluetooth_terminal/utils/constants.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:get/get.dart';

enum EditWidgetType { id, text, number, row, custom }

Future<void> showSnackbar(
  String title,
  String message, {
  Duration duration = const Duration(seconds: 2),
  bool showProgressIndicator = false,
}) async {
  try {
    Get.printInfo(info: "$title: $message");
    await closeSnackbar();
    Get.snackbar(
      title.trim(),
      message.trim(),
      duration: duration,
      snackPosition: SnackPosition.BOTTOM,
      showProgressIndicator: showProgressIndicator,
      animationDuration: const Duration(milliseconds: 200),
    );
  } catch (_) {}
}

Future<void> closeSnackbar() async {
  try {
    await Get.closeCurrentSnackbar();
    // await snackbarController?.close(withAnimations: false);
    // snackbarController = null;
    // Get.closeAllSnackbars();
  } catch (_) {}
}

String formatDuration(double seconds) {
  int hours = (seconds / 3600).floor();
  int minutes = ((seconds % 3600) / 60).floor();
  int secs = (seconds % 60).floor();

  List<String> parts = [];

  if (hours > 0) {
    parts.add('${hours}h');
  }
  if (minutes > 0) {
    parts.add('${minutes}m');
  }
  if (secs > 0 || parts.isEmpty) {
    parts.add('${secs}s');
  }

  return parts.join(' ');
}

StreamTransformer<double, List<FlSpot>> durationAccumulate({
  List<FlSpot> buffer = const [],
  double updateInterval = 0.01,
  double maxDuration = 10,
}) {
  final ss = SettingsService.to;
  double elapsed = SettingsService.to.seconds;

  if (buffer.isEmpty) {
    buffer.addAll(
      List<FlSpot>.generate(
        (maxDuration / 0.01).toInt(),
        (i) => FlSpot(elapsed - maxDuration + i * 0.01, 0.0),
      ),
    );
  }

  return StreamTransformer<double, List<FlSpot>>.fromHandlers(
    handleData: (data, sink) {
      final s = ss.seconds;
      bool changed = false;

      if (buffer.isEmpty || s - buffer.last.x > updateInterval) {
        buffer.add(FlSpot(s, data));
        changed = true;
      }

      if (buffer.last.x - buffer.first.x > maxDuration) {
        final idx = buffer.indexWhere((v) => buffer.last.x - v.x < maxDuration);
        buffer.removeRange(0, idx);
        changed = true;
      }

      if (changed) {
        sink.add(buffer);
      }
    },
  );
}

StreamTransformer<int, DataPacket> dataPacketTransformer() {
  final cs = ConnectionService.to;
  final ls = LogService.to;

  final cmds = [
    FLOAT_RECV,
    PASSWORD_VALID,
    PASSWORD_INVALID,
    MSG_RECV,
    PING,
  ];

  Uint8List buffer = Uint8List(1024);
  int i = 0;
  int cmd = -1;

  int lastByte = 0;
  Uint8List? msgBuf;

  return StreamTransformer<int, DataPacket>.fromHandlers(
    handleData: (data, sink) {
      if (data == -1) {
        sink.close();
        return;
      }

      cs.numBytesReceived.value += 1;

      if (cmds.contains(cmd)) {
        if (cmd == MSG_RECV && msgBuf != null) {
          if (i < msgBuf!.length){
            msgBuf![i++] = data;

            if (i == msgBuf!.length){
              final msg = String.fromCharCodes(msgBuf!);
              ls.logRecv(msg);
              // showSnackbar("Message received", msg);

              msgBuf = null;
              cmd = -1;
              i = 0;
            }
          }
        } else if (data == 0xFF && lastByte == 0xFF) {
          final dp = DataPacket.fromBuffer(buffer);
          sink.add(dp);
          cmd = -1;
          i = 0;

          if (dp.cmd == MSG_RECV && 0 < dp.value && dp.value < 1024){
            cmd = dp.cmd;
            msgBuf = Uint8List(dp.value.toInt());
          }
        } else if (i >= buffer.length) {
          cmd = -1;
          i = 0;
        } else {
          buffer[i++] = data;

          if (cs.connectionType.value == "BT Classic" && i == 6) {
            sink.add(DataPacket.fromBuffer(buffer));
            cmd = -1;
            i = 0;
          }
        }
      } else if (cmds.contains(data)) {
        cmd = data;
        i = 0;
        buffer[i++] = cmd;
      }

      lastByte = data;
    },
  );
}

class TryResponse<T> {
  final T? result;
  final String msg;

  const TryResponse(this.result, this.msg);
}

Future<TryResponse<T>> tryFunc<T>(
  FutureOr<T>? Function() fn, {
  Duration timeout = const Duration(seconds: 10),
  String name = "",
  bool showSnackBar = false,
  Function()? onTimeout,
}) async {
  if (name.isNotEmpty) {
    Get.printInfo(info: "tryFunc: $name");
  }
  try {
    final fnRes = fn();
    final result =
        fnRes is T ? fnRes : await (fnRes as Future<T>).timeout(timeout);

    return TryResponse(result, "OK");
  } on TimeoutException {
    if (onTimeout != null) {
      try {
        onTimeout();
      } catch (e, st) {
        Get.printError(info: "onTimeout error: $e\n$st");
      }
    }

    final msg = "$name timeout";
    Get.printError(info: msg);
    if (showSnackBar) {
      tryFunc(() => showSnackbar("Error", msg));
    }
    return TryResponse(null, msg);
  } catch (e, st) {
    Get.printError(info: "$name error: $e\n$st");
    return TryResponse(null, "Error: $e\n$st");
  }
}
