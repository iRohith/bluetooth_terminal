import 'package:bluetooth_terminal/services/log_service.dart';
import 'package:bluetooth_terminal/ui/pages/page_wrapper.dart';
import 'package:bluetooth_terminal/ui/widgets/panels/log_panel.dart';
import 'package:flutter/material.dart';

class LogsPage extends StatelessWidget {
  const LogsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final logService = LogService.to;

    return PageWrapper(
      title: "Logs",
      panels: [
        LogPanel(title: "System Log", id: 'sys_log', log: logService.sysLog),
        LogPanel(title: "Send Log", id: 'send_log', log: logService.sendLog),
        LogPanel(title: "Receive Log", id: 'recv_log', log: logService.recvLog),
      ],
    );
  }
}
