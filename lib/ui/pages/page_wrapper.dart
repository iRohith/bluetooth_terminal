import 'package:bluetooth_terminal/services/connection_service.dart';
import 'package:bluetooth_terminal/ui/widgets/panels/base_panel.dart';
import 'package:bluetooth_terminal/ui/widgets/side_menu.dart';
import 'package:bluetooth_terminal/utils/routes.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class PageWrapper extends StatelessWidget {
  final List<BasePanel> panels;
  final Widget? extraWidget;
  final String title;
  final bool useScroll;

  const PageWrapper({
    super.key,
    required this.panels,
    this.title = '',
    this.useScroll = true,
    this.extraWidget,
  });

  @override
  Widget build(BuildContext context) {
    final child =
        panels.length == 1 && extraWidget == null
            ? Center(child: panels.first)
            : SizedBox(
              width: double.infinity,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                spacing: 8,
                children: [...panels, if (extraWidget != null) extraWidget!],
              ),
            );

    final connectionType = ConnectionService.to.connectionType;

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: <Widget>[
          IconButton(
            onPressed: () {
              Get.toNamed(Routes.connection);
            },
            icon: Obx(() {
              final c = connectionType.value.toLowerCase();
              var icon = Icons.do_not_disturb;
              if (c.startsWith("ws")){
                icon = Icons.wifi;
              } else if (c.contains("usb")) {
                icon = Icons.usb;
              } else if (c.contains("ble") || c.contains("bt")) {
                icon = Icons.bluetooth;
              }
              return Icon(icon);
            }),
          ),
        ],
      ),
      drawer: SideMenu(),
      body: SafeArea(
        child: useScroll ? SingleChildScrollView(child: child) : child,
      ),
    );
  }
}
