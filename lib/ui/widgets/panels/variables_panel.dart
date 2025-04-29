import 'package:bluetooth_terminal/modals/variable_data.dart';
import 'package:bluetooth_terminal/services/data_service.dart';
import 'package:bluetooth_terminal/services/storage_service.dart';
import 'package:bluetooth_terminal/ui/widgets/edit_dialog.dart';
import 'package:bluetooth_terminal/ui/widgets/panels/base_panel.dart';
import 'package:bluetooth_terminal/utils/util.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class Variable {
  final RxInt id;
  final RxString name;

  const Variable(this.id, this.name);
}

class VariablesPanel extends BasePanel<List<Variable>> {
  final bool showAddButton;

  const VariablesPanel({
    super.key,
    this.showAddButton = true,
    super.title = "Variables",
    super.constraintHeight = true,
    required super.id,
  });

  @override
  Future<List<Variable>?> loadState() async {
    return (await StorageService.to.loadVariables(
      id,
      numDefaultVars: id.contains("home") ? 0 : 8,
    )).map((e) => Variable(e.id.obs, e.name.obs)).toList();
  }

  @override
  Widget buildPanel(BuildContext context, List<Variable>? state) {
    return ValueBuilder<List<Variable>?>(
      initialValue: state!,
      onUpdate: (v) {
        StorageService.to.saveVariables(
          id,
          v!.map((v) => VariableData(v.id.value, v.name.value)).toList(),
        );
      },
      builder:
          (variables, updateFn) => GridView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 1.4,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: variables!.length + (showAddButton ? 1 : 0),
            itemBuilder: (ctx, index) {
              void update(v) {
                if (v == null) {
                  variables.removeAt(index);
                } else if (index >= variables.length) {
                  variables.add(v);
                } else {
                  variables[index] = v;
                }
                updateFn(variables);
              }

              return showAddButton && index == variables.length
                  ? _buildAddItemButton(update, "Var ${variables.length + 1}")
                  : _buildGridItem(variables[index], update);
            },
          ),
    );
  }

  Widget _buildGridItem(Variable v, Function(Variable?) updateFn) {
    return GestureDetector(
      onTap: () => _showAddOrEditItemDialog(updateFn, variable: v),
      child: Card(
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ObxValue(
                (name) => Text(
                  name.value,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.normal,
                  ),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.fade,
                  maxLines: 1,
                ),
                v.name,
              ),

              SizedBox(height: 6),

              ObxValue(
                (id) => ObxValue(
                  (value) => Text(
                    value.toStringAsFixed(3),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  DataService.to.getVariable(id.value),
                ),
                v.id,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddItemButton(
    Function(Variable?) updateFn,
    String? defaultName,
  ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: IconButton(
          icon: const Icon(Icons.add),
          onPressed: () {
            _showAddOrEditItemDialog(updateFn, defaultName: defaultName);
          },
        ),
      ),
    );
  }

  void _showAddOrEditItemDialog(
    Function(Variable?) updateFn, {
    Variable? variable,
    String? defaultName,
  }) {
    final id = variable?.id;

    Get.dialog(
      EditDialog(
        title: id == null ? "Add" : "Edit",
        submitText: id == null ? "Add" : "Save",
        onDelete: id != null && showAddButton ? () => updateFn(null) : null,
        onSubmit: (data) {
          if (variable != null) {
            variable!.id.value = data["ID"]!;
            variable!.name.value = data["Name"];
          } else {
            variable = Variable(
              (data["ID"]! as int).obs,
              (data["Name"]! as String).obs,
            );
          }
          updateFn(variable);
        },
        widgets: [
          EditDialogWidgetData(EditWidgetType.id, "ID", data: id?.value),
          EditDialogWidgetData(
            EditWidgetType.text,
            "Name",
            data: variable?.name.value ?? (defaultName ?? "Unknown"),
          ),
        ],
      ),
    );
  }
}
