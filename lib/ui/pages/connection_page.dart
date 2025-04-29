import 'package:bluetooth_terminal/services/connection_service.dart';
import 'package:bluetooth_terminal/ui/pages/page_wrapper.dart';
import 'package:bluetooth_terminal/ui/widgets/panels/base_panel.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ConnectionPage extends StatelessWidget {
  const ConnectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    final ctype = ConnectionService.to.connectionType;

    return PageWrapper(
      title: "Connections",
      useScroll: false,
      panels: [
        BasePanel(
          id: "connection",
          title: "Connection",
          width: Get.width * 0.8,
          constraintHeight: false,
          child: Obx(() {
            final ctypes = ConnectionService.to.connectors.keys.toList();
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: List.generate(
                ctypes.length,
                (i) => ListTile(
                  title: Text(ctypes[i]),
                  leading: Radio<String>(
                    value: ctypes[i],
                    groupValue: ctype.value,
                    onChanged: (v) => ctype.value = v ?? "None",
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}
