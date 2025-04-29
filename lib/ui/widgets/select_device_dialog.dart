import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:searchable_listview/searchable_listview.dart';

class SelectDeviceDialog extends StatelessWidget {
  final String name;
  final RxList<(String, String)> devices;
  final Function(String, String) connectCallback;

  const SelectDeviceDialog({
    super.key,
    this.name = "Select Device",
    required this.devices,
    required this.connectCallback,
  });

  @override
  Widget build(BuildContext context) {
    final connecting = "".obs;

    return AlertDialog(
      title: Text(name),
      content: Container(
        width: 250,
        constraints: BoxConstraints(maxHeight: Get.height * 0.5),
        child: Obx(() {
          return SearchableList<(String, String)>.sliver(
            // ignore: invalid_use_of_protected_member
            initialList: devices.value,
            keyboardAction: TextInputAction.none,
            itemBuilder:
                (item) => ListTile(
                  title: Text(item.$1),
                  subtitle: Text(item.$2),
                  trailing: Obx(
                    () =>
                        connecting.value == item.$1
                            ? const CircularProgressIndicator()
                            : const SizedBox(),
                  ),
                  onTap: () {
                    if (connecting.value.isEmpty) {
                      connecting.value = item.$1;
                      connectCallback(item.$1, item.$2);
                    }
                  },
                ),
            filter:
                (value) =>
                    devices
                        .where(
                          (e) =>
                              e.$1.toLowerCase().contains(
                                value.toLowerCase(),
                              ) ||
                              e.$2.toLowerCase().contains(value.toLowerCase()),
                        )
                        .toList(),
            inputDecoration: InputDecoration(
              labelText: "Search",
              border: const OutlineInputBorder(),
            ),
          )..sliverScrollEffect = false;
        }),
      ),
      actions: [
        TextButton(
          onPressed: () async {
            Get.back(result: false);
          },
          child: Text("Cancel"),
        ),
      ],
    );
  }
}
