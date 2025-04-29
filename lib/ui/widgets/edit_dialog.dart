import 'package:bluetooth_terminal/services/data_service.dart';
import 'package:bluetooth_terminal/utils/util.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class EditDialogWidgetData {
  final EditWidgetType type;
  final String name;
  final String Function(dynamic)? validate;
  final dynamic extra;
  dynamic data;

  EditDialogWidgetData(
    this.type,
    this.name, {
    this.extra,
    this.validate,
    this.data,
  });
}

class EditDialog extends StatelessWidget {
  final String title;
  final Function? onDelete;
  final Function(Map<String, dynamic>)? onSubmit;
  final String? cancelText;
  final String? submitText;

  final List<EditDialogWidgetData> widgets;

  const EditDialog({
    super.key,
    required this.widgets,
    required this.title,
    this.onSubmit,
    this.onDelete,
    this.cancelText = "Cancel",
    this.submitText = "Ok",
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title:
          onDelete == null
              ? Text(title)
              : Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(title),
                  if (onDelete != null)
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () async {
                        onDelete!();
                        await closeSnackbar();
                        Get.back();
                      },
                    ),
                ],
              ),
      scrollable: true,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 8,
        children: List.generate(
          widgets.length,
          (i) => _buildEditWidget(widgets[i]),
        ),
      ),
      actions: [
        if (cancelText != null)
          TextButton(
            onPressed: () async {
              await closeSnackbar();
              Get.back();
            },
            child: Text(cancelText!),
          ),
        if (submitText != null)
          ElevatedButton(
            onPressed: () async {
              final msg = _validate(widgets);

              if (msg.isEmpty) {
                onSubmit?.call(_map(widgets));
                await closeSnackbar();
                Get.back();
              } else {
                await closeSnackbar();
                showSnackbar("Error", msg);
              }
            },
            child: Text(submitText ?? "Submit"),
          ),
      ],
    );
  }

  Widget _buildEditWidget(EditDialogWidgetData wd) {
    if (wd.type == EditWidgetType.text ||
        wd.type == EditWidgetType.number ||
        wd.type == EditWidgetType.id) {
      return _buildTextWidget(wd);
    }

    if (wd.type == EditWidgetType.row) {
      final List<EditDialogWidgetData> row = wd.data;
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 8,
        children: [
          if (wd.name.isNotEmpty) Text(wd.name),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: 8,
            children: List<Widget>.generate(
              row.length,
              (i) => Expanded(child: _buildEditWidget(row[i])),
            ),
          ),
        ],
      );
    }

    if (wd.type == EditWidgetType.custom) {
      return wd.extra;
    }

    return const SizedBox();
  }

  Widget _buildTextWidget(EditDialogWidgetData data) {
    if (data.type == EditWidgetType.id) {}
    final TextEditingController controller = TextEditingController();

    var keyboardType = TextInputType.text;

    if (data.type == EditWidgetType.id) {
      if (data.data is! int) {
        data.data = 0;
      }
      controller.text = (data.data as int).toString();
      keyboardType = TextInputType.numberWithOptions(
        decimal: false,
        signed: false,
      );
    } else if (data.type == EditWidgetType.number) {
      if (data.data is! double) {
        data.data = 0.0;
      }
      controller.text = (data.data as double).toStringAsFixed(3);
      keyboardType = TextInputType.numberWithOptions(
        decimal: true,
        signed: true,
      );
    } else if (data.type == EditWidgetType.text) {
      if (data.data is! String) {
        data.data = "";
      }
      controller.text = data.data as String;
      data.data = controller.text;
    }

    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: data.name,
        border: const OutlineInputBorder(),
      ),
      keyboardType: keyboardType,
      maxLines: 1,
      onChanged: (value) {
        if (data.type == EditWidgetType.number) {
          data.data = double.tryParse(value);
        } else if (data.type == EditWidgetType.id) {
          data.data = int.tryParse(value);
        } else {
          data.data = value;
        }
      },
    );
  }

  static Map<String, dynamic> _map(List<EditDialogWidgetData> widgets) {
    final entries = <MapEntry<String, dynamic>>[];

    for (final w in widgets) {
      entries.add(
        MapEntry(w.name, w.type == EditWidgetType.row ? _map(w.data) : w.data),
      );
    }

    return Map.fromEntries(entries);
  }

  static String _validate(List<EditDialogWidgetData> widgets) {
    String msg = "";

    for (final wd in widgets) {
      if (wd.validate != null) {
        msg += wd.validate!(wd.data);
        continue;
      }

      if (wd.type == EditWidgetType.text) {
        if (wd.data == null ||
            wd.data is! String ||
            (wd.data as String).isEmpty) {
          msg += "${wd.name} cannot be empty.\n";
        }
      } else if (wd.type == EditWidgetType.number) {
        if (wd.data == null ||
            wd.data is! double ||
            wd.data == double.maxFinite) {
          msg += "Invalid ${wd.name} value: '${wd.data}'\n";
        }
      } else if (wd.type == EditWidgetType.id) {
        if (wd.data == null || wd.data is! int || wd.data == -1) {
          msg += "Invalid ${wd.name}: '${wd.data}'.\n";
        } else if (wd.extra == "id_exists" &&
            !DataService.to.hasVariable(wd.data)) {
          msg += "Invalid ${wd.name}: 'Id ${wd.data} not found'.\n";
        }
      } else if (wd.type == EditWidgetType.row) {
        _validate(wd.data);
      }
    }

    return msg.trim();
  }
}
