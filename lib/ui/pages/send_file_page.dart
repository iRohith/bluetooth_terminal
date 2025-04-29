import 'dart:io';

import 'package:bluetooth_terminal/services/connection_service.dart';
import 'package:bluetooth_terminal/services/log_service.dart';
import 'package:bluetooth_terminal/ui/pages/page_wrapper.dart';
import 'package:bluetooth_terminal/ui/widgets/panels/base_panel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SendFilePage extends StatelessWidget {
  const SendFilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final fileName = "".obs;

    final TextEditingController pwdController = TextEditingController(text: "");
    Uint8List? bytes;
    bool sending = false;

    return PageWrapper(
      title: "Send File",
      panels: [
        BasePanel(
          id: "send_file",
          title: "Send File",
          constraintHeight: false,
          child: SizedBox(
            height: 600,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              spacing: 8,
              children: [
                ElevatedButton(
                  onPressed: () async => bytes = await _pickFile(fileName),
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    backgroundColor: Get.theme.colorScheme.primaryContainer,
                    foregroundColor: Get.theme.colorScheme.onPrimaryContainer,
                    elevation: 8,
                  ),
                  child: Text("Select file"),
                ),

                Obx(
                  () =>
                      fileName.value.isNotEmpty
                          ? Text("File: ${fileName.value}")
                          : SizedBox(),
                ),

                Divider(),

                SizedBox(
                  width: 250,
                  child: ValueBuilder<bool?>(
                    initialValue: true,
                    builder:
                        (obscureText, updateFn) => TextField(
                          controller: pwdController,
                          decoration: InputDecoration(
                            labelText: "Password",
                            border: const OutlineInputBorder(),
                            suffixIcon: IconButton(
                              icon: Icon(
                                obscureText!
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                                color: Colors.grey,
                              ),
                              onPressed: () => updateFn(!obscureText),
                            ),
                          ),
                          obscureText: obscureText,
                        ),
                  ),
                ),

                ElevatedButton(
                  onPressed: () async {
                    if (sending) {
                      return;
                    }
                    sending = true;
                    await ConnectionService.to.sendProtected(
                      pwdController.text,
                      bytes,
                    );
                    sending = false;
                  },
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    backgroundColor: Get.theme.colorScheme.primaryContainer,
                    foregroundColor: Get.theme.colorScheme.onPrimaryContainer,
                    elevation: 8,
                  ),
                  child: Text("Send"),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<Uint8List?> _pickFile(Rx<String> fileName) async {
    final logService = LogService.to;
    FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result != null) {
      try {
        File file = File(result.files.single.path!);
        final bytes = file.readAsBytesSync();
        fileName.value = result.files.single.name;

        logService.logSys("Opened file: ${fileName.value}");
        return bytes;
      } catch (e) {
        if (kDebugMode) {
          print(e);
        }

        logService.logSys("Failed to read file; Error: $e");
        fileName.value = "";
      }
    }
    return null;
  }
}
