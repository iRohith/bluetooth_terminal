import 'package:bluetooth_terminal/utils/constants.dart';
import 'package:get/get.dart';

class LogService extends GetxService {
  static LogService get to => Get.find();

  final RxList<String> sendLog = <String>[].obs;
  final RxList<String> recvLog = <String>[].obs;
  final RxList<String> sysLog = <String>[].obs;

  LogService() {
    ever(sysLog, (v) => printInfo(info: v.lastOrNull ?? ""));
  }

  void logSend(String msg) {
    sendLog.add("> $msg");

    if (sendLog.length > MAX_LOG_LINES) {
      sendLog.removeAt(0);
    }
  }

  void logRecv(String msg) {
    recvLog.add("> $msg");

    if (recvLog.length > MAX_LOG_LINES) {
      recvLog.removeAt(0);
    }
  }

  void logSys(String msg) {
    sysLog.add("> $msg");

    if (sysLog.length > MAX_LOG_LINES) {
      sysLog.removeAt(0);
    }
  }
}
