import 'package:bluetooth_terminal/modals/slider_data.dart';
import 'package:bluetooth_terminal/services/connection_service.dart';
import 'package:bluetooth_terminal/services/data_service.dart';
import 'package:bluetooth_terminal/services/storage_service.dart';
import 'package:bluetooth_terminal/ui/widgets/edit_dialog.dart';
import 'package:bluetooth_terminal/ui/widgets/panels/base_panel.dart';
import 'package:bluetooth_terminal/utils/constants.dart';
import 'package:bluetooth_terminal/utils/util.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../modals/data_packet.dart';

class SlidersPanel extends BasePanel<List<(SliderData, DataPacket)>> {
  final bool showAddButton;

  const SlidersPanel({
    super.key,
    required super.id,
    super.title = "Sliders",
    this.showAddButton = true,
    super.constraintHeight = true,
  });

  @override
  Future<List<(SliderData, DataPacket)>?> loadState() {
    return StorageService.to.loadSliders(id);
  }

  @override
  Widget buildPanel(
    BuildContext context,
    List<(SliderData, DataPacket)>? state,
  ) {
    return ValueBuilder<List<(SliderData, DataPacket)>?>(
      initialValue: state!,
      onUpdate: (v) {
        StorageService.to.saveSliders(id, v!);
      },
      builder: (sliders, updateFn) {
        void update(int index, SliderData? sd, DataPacket? dp) {
          if (index != -1 || sd == null || dp == null) {
            final r = sliders!.removeAt(index);
            DataService.to.removeAllVarsWithPrefix("slider_${id}_${r.$2.id}");
          } else if (index == -1 || index >= sliders!.length) {
            sliders!.add((sd, dp));
          } else {
            DataService.to.removeAllVarsWithPrefix(
              "slider_${id}_${sliders[index].$2.id}",
            );
            sliders[index] = (sd, dp);
          }
          updateFn(sliders);
        }

        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            spacing: 8,
            children: [
              ...List.generate(
                sliders!.length,
                (i) => _buildSlider(
                  sliders[i].$1,
                  sliders[i].$2,
                  (sd, dp) => update(i, sd, dp),
                ),
              ),
              if (showAddButton)
                ElevatedButton(
                  onPressed:
                      () => _showAddOrEditItemDialog(
                        (sd, dp) => update(-1, null, null),
                        defaultName: "S ${sliders.length + 1}",
                      ),
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    backgroundColor: Get.theme.colorScheme.primaryContainer,
                    foregroundColor: Get.theme.colorScheme.onPrimaryContainer,
                    elevation: 8,
                  ),
                  child: const Text("Add slider"),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSlider(
    SliderData sd,
    DataPacket dp,
    Function(SliderData? sd, DataPacket? dp) updateFn,
  ) {
    final slider = DataService.to.getVar(
      "slider_${id}_${dp.id}_slider",
      sd.min,
    );
    final textValue = DataService.to.getVar(
      "slider_${id}_${dp.id}_textValue",
      sd.min.toStringAsFixed(3),
    );

    final TextEditingController controller = TextEditingController(
      text: textValue.value,
    );

    debounce(textValue, (tv) {
      final v = double.tryParse(tv);
      if (v != null) {
        slider.value = v.clamp(sd.min, sd.max);
      }
    }, time: 1.seconds);

    controller.addListener(() => textValue.value = controller.text);

    debounce(slider, (v) {
      if (sd.min <= v && v <= sd.max) {
        ConnectionService.to.writeDataPacket(dp.copyWith(value: v));
      }
    }, time: 0.5.seconds);

    return Row(
      children: [
        ElevatedButton(
          onPressed: () {
            final v = slider.value.clamp(sd.min, sd.max);
            ConnectionService.to.writeDataPacket(dp.copyWith(value: v));
            slider.value = v;
            controller.text = v.toStringAsFixed(3);
          },
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            backgroundColor: Get.theme.colorScheme.primaryContainer,
            foregroundColor: Get.theme.colorScheme.onPrimaryContainer,
            elevation: 8,
          ),
          child: Text(
            sd.name,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ),

        Expanded(
          child: ObxValue(
            (sliderValue) => Slider(
              min: sd.min,
              max: sd.max,
              value: sliderValue.value,
              onChanged: (v) {
                controller.text = v.toStringAsFixed(3);
                sliderValue.value = double.parse(controller.text);
              },
            ),
            slider,
          ),
        ),

        SizedBox(
          width: 70,
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(border: OutlineInputBorder()),
          ),
        ),
        const SizedBox(width: 8),

        IconButton(
          onPressed: () => _showAddOrEditItemDialog(updateFn, sd: sd, dp: dp),
          icon: const Icon(Icons.edit),
        ),
      ],
    );
  }

  void _showAddOrEditItemDialog(
    Function(SliderData?, DataPacket?) updateFn, {
    SliderData? sd,
    DataPacket? dp,
    String? defaultName,
  }) {
    Get.dialog(
      EditDialog(
        title: sd == null ? "Add" : "Edit",
        submitText: sd == null ? "Add" : "Save",
        onDelete:
            sd != null && showAddButton ? () => updateFn(null, null) : null,
        onSubmit: (data) {
          sd = SliderData(
            name: data["Name"]!,
            min: data["Min"]!,
            max: data["Max"]!,
          );
          dp = DataPacket(cmd: FLOAT_SEND, id: data["ID"]!);
          updateFn(sd, dp);
        },
        widgets: [
          EditDialogWidgetData(EditWidgetType.id, "ID", data: dp?.id ?? 0),
          EditDialogWidgetData(
            EditWidgetType.text,
            "Name",
            data: sd?.name ?? (defaultName ?? "Unknown"),
          ),
          EditDialogWidgetData(EditWidgetType.number, "Min", data: 0.0),
          EditDialogWidgetData(EditWidgetType.number, "Max", data: 0.0),
        ],
      ),
    );
  }
}
