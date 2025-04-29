import 'package:bluetooth_terminal/services/connection_service.dart';
import 'package:bluetooth_terminal/services/storage_service.dart';
import 'package:bluetooth_terminal/ui/widgets/edit_dialog.dart';
import 'package:bluetooth_terminal/ui/widgets/panels/base_panel.dart';
import 'package:bluetooth_terminal/utils/constants.dart';
import 'package:bluetooth_terminal/utils/util.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../modals/data_packet.dart';

class KeypadPanel extends BasePanel<List<(String, DataPacket)>> {
  final List<List<(String, DataPacket)>> labelledButtons;
  final bool showAddButton;
  final bool enableSendMessageButton;

  const KeypadPanel({
    super.key,
    required this.labelledButtons,
    this.showAddButton = true,
    this.enableSendMessageButton = false,
    super.title = "Keypad",
    super.constraintHeight = true,
    required super.id,
  });

  @override
  Future<List<(String, DataPacket)>?> loadState() {
    return StorageService.to.loadKeypad(
      id,
      numDefaultKeys: id.contains("home") ? 3 : 8,
    );
  }

  @override
  Widget buildPanel(BuildContext context, List<(String, DataPacket)>? state) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        spacing: 8,
        children: [
          ...labelledButtons.map((b) => _buildLabelledButtons(b)),
          if (enableSendMessageButton) _buildSendMessageButton(),
          _buildIdButtons(state!),
        ],
      ),
    );
  }

  Widget _buildSendMessageButton() {
    final TextEditingController msgController = TextEditingController(text: "");

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      spacing: 8,
      children: [
        SizedBox(
          width: 200,
          child: TextField(
            controller: msgController,
            decoration: InputDecoration(
              labelText: "Message",
              border: OutlineInputBorder(),
            ),
          ),
        ),

        ElevatedButton(
          onPressed: () async {
            if (await ConnectionService.to.writeMessage(msgController.text)) {
              msgController.clear();
            }
          },
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            backgroundColor:
                Theme.of(Get.context!).colorScheme.primaryContainer,
            elevation: 8,
          ),
          child: const Text("Send"),
        ),
      ],
    );
  }

  Widget _buildLabelledButtons(List<(String, DataPacket)> buttons) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      spacing: 8,
      children:
          buttons
              .map(
                (b) => ElevatedButton(
                  onPressed: () => ConnectionService.to.writeDataPacket(b.$2),
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    backgroundColor: Get.theme.colorScheme.primaryContainer,
                    foregroundColor: Get.theme.colorScheme.onPrimaryContainer,
                    elevation: 8,
                  ),
                  child: Text(b.$1),
                ),
              )
              .toList(),
    );
  }

  Widget _buildIdButtons(List<(String, DataPacket)> initButtons) {
    return ValueBuilder<List<(String, DataPacket)>?>(
      initialValue: initButtons,
      onUpdate: (v) {
        StorageService.to.saveKeypad(id, v!);
      },
      builder:
          (buttons, updateFn) =>
              GridView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          childAspectRatio: 1,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                    itemCount: buttons!.length + (showAddButton ? 1 : 0),
                    itemBuilder: (ctx, index) {
                      void update(String? name, DataPacket? dp) {
                        if (name == null || dp == null) {
                          buttons.removeAt(index);
                        } else if (index >= buttons.length) {
                          buttons.add((name, dp));
                        } else {
                          buttons[index] = (name, dp);
                        }
                        updateFn(buttons);
                      }

                      return showAddButton && index == buttons.length
                          ? _buildAddItemButton(
                            update,
                            "K ${buttons.length + 1}",
                          )
                          : _buildKeypadButton(
                            buttons[index].$1,
                            buttons[index].$2,
                            update,
                          );
                    },
                  )
                  as Widget,
    );
  }

  Widget _buildKeypadButton(
    String name,
    DataPacket dp,
    Function(String?, DataPacket?) updateFn,
  ) {
    return ElevatedButton(
      onPressed: () => ConnectionService.to.writeDataPacket(dp),
      onLongPress: () => _showAddOrEditItemDialog(updateFn, name: name, dp: dp),
      style: ElevatedButton.styleFrom(
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            name,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
            overflow: TextOverflow.fade,
            maxLines: 1,
          ),
          Text(
            (" ID: 0x${dp.id.toRadixString(16).toUpperCase()}\n"
                "Val: ${dp.value.toStringAsFixed(3)}"),
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
            textAlign: TextAlign.center,
            overflow: TextOverflow.fade,
            maxLines: 2,
          ),
        ],
      ),
    );
  }

  Widget _buildAddItemButton(
    Function(String?, DataPacket?) updateFn,
    String? defaultName,
  ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: IconButton(
          icon: const Icon(Icons.add),
          onPressed:
              () => _showAddOrEditItemDialog(updateFn, name: defaultName),
        ),
      ),
    );
  }

  void _showAddOrEditItemDialog(
    Function(String?, DataPacket?) updateFn, {
    String? name,
    DataPacket? dp,
  }) {
    Get.dialog(
      EditDialog(
        title: dp == null ? "Add" : "Edit",
        submitText: dp == null ? "Add" : "Save",
        onDelete:
            dp != null && showAddButton ? () => updateFn(null, null) : null,
        onSubmit: (data) {
          name = data["Name"]!;
          dp = DataPacket(
            cmd: FLOAT_SEND,
            id: data["ID"]!,
            value: data["Value"]!,
          );
          updateFn(name, dp);
        },
        widgets: [
          EditDialogWidgetData(EditWidgetType.id, "ID", data: dp?.id),
          EditDialogWidgetData(
            EditWidgetType.text,
            "Name",
            data: name ?? "Unknown",
          ),
          EditDialogWidgetData(EditWidgetType.number, "Value", data: dp?.value),
        ],
      ),
    );
  }
}
