import 'package:bluetooth_terminal/ui/widgets/panels/base_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class LogPanel extends BasePanel<Null> {
  final RxList<String> log;

  const LogPanel({
    super.key,
    required this.log,
    super.title = "Log",
    super.constraintHeight = false,
    required super.id,
  });

  @override
  Widget buildPanel(BuildContext context, Null state) {
    final TextEditingController txtController = TextEditingController(
      text: log.join("\n"),
    );

    interval(
      log,
      (v) => txtController.text = v.join("\n"),
      time: const Duration(milliseconds: 100),
    );

    return Column(
      children: [
        Container(
          width: double.infinity,
          height: 250,
          padding: const EdgeInsets.all(8),
          child: TextField(
            controller: txtController,
            readOnly: true,
            decoration: const InputDecoration(border: OutlineInputBorder()),
            maxLines: null,
            expands: true,
            textAlignVertical: TextAlignVertical.top,
          ),
        ),

        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          spacing: 8,
          children: [
            ElevatedButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: txtController.text));
                Get.snackbar("Copied", "Log copied to clipboard");
              },
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                backgroundColor: Get.theme.colorScheme.primaryContainer,
                foregroundColor: Get.theme.colorScheme.onPrimaryContainer,
                elevation: 8,
              ),
              child: Text("Copy"),
            ),

            ElevatedButton(
              onPressed: () => log.clear(),
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                backgroundColor: Get.theme.colorScheme.primaryContainer,
                foregroundColor: Get.theme.colorScheme.onPrimaryContainer,
                elevation: 8,
              ),
              child: Text("Clear"),
            ),
          ],
        ),
      ],
    );
  }
}
