import 'dart:async';
import 'dart:math';

import 'package:bluetooth_terminal/modals/chart_data.dart';
import 'package:bluetooth_terminal/services/data_service.dart';
import 'package:bluetooth_terminal/ui/widgets/edit_dialog.dart';
import 'package:bluetooth_terminal/ui/widgets/panels/base_panel.dart';
import 'package:bluetooth_terminal/utils/constants.dart';
import 'package:bluetooth_terminal/utils/util.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:get/get.dart';

class ChartPanel extends BasePanel<ChartData> {
  final Rx<ChartData> _chartData;
  final List<List<FlSpot>> buffer;
  final Function(ChartData?)? updateFn;

  final List<StreamSubscription> subs = [];

  ChartPanel({
    super.key,
    required super.id,
    required this.buffer,
    required ChartData chartData,
    super.title = "Chart",
    this.updateFn,
  }) : _chartData = chartData.obs,
       super(constraintHeight: false);

  void update(ChartData? cd) {
    if (updateFn != null) {
      if (cd != null) {
        _chartData.value = cd;
      }
      updateFn!(cd);
    }
  }

  Future<void> closeSubs() async {
    for (final sub in subs) {
      await sub.cancel();
    }
    subs.clear();
  }

  @override
  Widget buildPanel(BuildContext context, ChartData? _) {
    if (buffer.isEmpty) {
      buffer.addAll(
        List.generate(_chartData.value.variables.length, (_) => []),
      );
    }

    return GestureDetector(
      onTap: () {
        if (updateFn != null) {
          final bufferCopy = buffer.toList();
          showAddOrEditChartDialog(
            (c) {
              buffer.clear();
              buffer.addAll(bufferCopy);
              update(c);
            },
            chartData: _chartData.value,
            buffer: bufferCopy,
          );
        }
      },
      child: ObxValue(
        (chartData) => SizedBox(
          width: double.infinity,
          height: 250,
          child: FutureBuilder(
            future: _buildChart(chartData.value, buffer),
            builder: (_, widget) => widget.data ?? const SizedBox(),
          ),
        ),
        _chartData,
      ),
    );
  }

  Future<Widget> _buildChart(
    ChartData chartData,
    List<List<FlSpot>> buffer,
  ) async {
    final lineDataList = List.generate(
      chartData.variables.length,
      (i) => LineChartBarData(
        spots: [FlSpot.zero],
        color: chartData.variables[i].color,
        dotData: const FlDotData(show: false),
        barWidth: 2,
        isCurved: false,
      ),
    );

    await closeSubs();

    subs.addAll(
      List.generate(
        chartData.variables.length,
        (i) => DataService.to
            .getVariable(chartData.variables[i].id)
            .stream
            .transform(
              durationAccumulate(
                buffer: buffer[i],
                updateInterval: chartData.updateInterval,
                maxDuration: chartData.maxDuration,
              ),
            )
            .map((spots) {
              final idx = spots.indexWhere(
                (v) => (spots.last.x - v.x) < chartData.maxDuration,
              );
              return LineChartBarData(
                spots: idx == -1 ? spots : spots.sublist(idx),
                color: chartData.variables[i].color,
                dotData: const FlDotData(show: false),
                barWidth: 2,
                isCurved: false,
              );
            })
            .listen((d) => lineDataList[i] = d),
      ),
    );

    final lineData = <LineChartBarData>[].obs;

    lineData.bindStream(
      Stream.periodic(
        Duration(
          milliseconds: max(10, (chartData.updateInterval * 1000).toInt()),
        ),
        (_) => lineDataList.toList(),
      ),
    );

    final limitY = chartData.minY != chartData.maxY;

    return ObxValue(
      (ld) => LineChart(
        duration: Duration(milliseconds: 10),
        LineChartData(
          minY: limitY ? chartData.minY : null,
          maxY: limitY ? chartData.maxY : null,
          lineTouchData: const LineTouchData(enabled: false),
          clipData: const FlClipData.all(),
          gridData: const FlGridData(show: true, drawVerticalLine: false),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            show: true,
            leftTitles: AxisTitles(
              axisNameWidget: const Text("Values"),
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget:
                    (value, meta) =>
                        _leftTitleWidgets(value, meta, Get.width * 0.9),
                reservedSize: 56,
              ),
              drawBelowEverything: true,
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              axisNameWidget: const Text("Time"),
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget:
                    (value, meta) =>
                        _bottomTitleWidgets(value, meta, Get.width * 0.9),
                reservedSize: 36,
                interval: 1,
              ),
              drawBelowEverything: true,
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          lineBarsData: ld.toList(),
        ),
      ),
      lineData,
    );
  }

  Widget _bottomTitleWidgets(double value, TitleMeta meta, double chartWidth) {
    if (value % 1 != 0) {
      return Container();
    }
    final style = TextStyle(
      color: Get.theme.colorScheme.onPrimaryContainer,
      fontWeight: FontWeight.normal,
      fontSize: min(18, 18 * chartWidth / 300),
    );
    return SideTitleWidget(
      meta: meta,
      space: 16,
      child: Text("${formatDuration(value)} ", style: style),
    );
  }

  Widget _leftTitleWidgets(double value, TitleMeta meta, double chartWidth) {
    final style = TextStyle(
      color: Get.theme.colorScheme.onPrimaryContainer,
      fontWeight: FontWeight.normal,
      fontSize: min(18, 18 * chartWidth / 300),
    );
    return SideTitleWidget(
      meta: meta,
      space: 16,
      child: Text(meta.formattedValue, style: style),
    );
  }

  static void showAddOrEditChartDialog(
    Function(ChartData?) updateFn, {
    ChartData? chartData,
    String? defaultName,
    List<List<FlSpot>>? buffer,
  }) {
    final variables = (chartData?.variables ?? []).obs;

    Get.dialog(
      EditDialog(
        title: chartData == null ? "Add" : "Edit",
        submitText: chartData == null ? "Add" : "Save",
        onDelete: chartData != null ? () => updateFn(null) : null,
        onSubmit: (data) {
          final chartData = ChartData(
            name: data["Name"],
            minY: data["Y Axis Limits: "]["Min"],
            maxY: data["Y Axis Limits: "]["Max"],
            updateInterval: data["Duration: "]["Interval"],
            maxDuration: data["Duration: "]["Max"],
            variables: variables,
          );

          updateFn(chartData);
        },
        widgets: [
          EditDialogWidgetData(
            EditWidgetType.text,
            "Name",
            data: chartData?.name ?? (defaultName ?? "Unknown"),
          ),
          EditDialogWidgetData(
            EditWidgetType.row,
            "Y Axis Limits: ",
            data: [
              EditDialogWidgetData(
                EditWidgetType.number,
                "Min",
                data: chartData?.minY ?? 0.0,
              ),
              EditDialogWidgetData(
                EditWidgetType.number,
                "Max",
                data: chartData?.maxY ?? 1.0,
              ),
            ],
          ),
          EditDialogWidgetData(
            EditWidgetType.row,
            "Duration: ",
            data: [
              EditDialogWidgetData(
                EditWidgetType.number,
                "Interval",
                data: chartData?.updateInterval ?? 0.001,
              ),
              EditDialogWidgetData(
                EditWidgetType.number,
                "Max",
                data: chartData?.maxDuration ?? 10.0,
              ),
            ],
          ),
          EditDialogWidgetData(
            EditWidgetType.custom,
            "Variables",
            validate:
                (_) => variables.isEmpty ? "Minimum 1 variable required\n" : "",
            extra: Column(
              children: [
                ObxValue(
                  (variables) => SizedBox(
                    width: 250,
                    height: min(200, variables.length * 60),
                    child: Card(
                      elevation: 4,
                      child: ReorderableListView.builder(
                        itemCount: variables.length,
                        itemBuilder: (context, index) {
                          final item = variables[index];
                          return GestureDetector(
                            key: ValueKey(item.id),
                            onTap:
                                () => _showAddOrEditVariableDialog(
                                  variables,
                                  index: index,
                                  buffer: buffer,
                                ),
                            child: ListTile(
                              title: Text(item.name),
                              leading: Icon(Icons.circle, color: item.color),
                              // trailing: IconButton(
                              //   icon: Icon(Icons.delete),
                              //   onPressed: () => variables.removeAt(index),
                              // ),
                            ),
                          );
                        },
                        onReorder: (oldIndex, newIndex) {
                          if (oldIndex < newIndex) {
                            newIndex -= 1;
                          }
                          final varItem = variables.removeAt(oldIndex);
                          variables.insert(newIndex, varItem);

                          if (buffer != null) {
                            final bufItem = buffer.removeAt(oldIndex);
                            buffer.insert(newIndex, bufItem);
                          }
                        },
                      ),
                    ),
                  ),
                  variables,
                ),
                Center(
                  child: ElevatedButton(
                    onPressed:
                        () => _showAddOrEditVariableDialog(
                          variables,
                          buffer: buffer,
                        ),
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      backgroundColor:
                          Theme.of(Get.context!).colorScheme.primaryContainer,
                      elevation: 8,
                    ),
                    child: const Text("Add Variable"),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static void _showAddOrEditVariableDialog(
    RxList<ChartVariable> vars, {
    int index = -1,
    List<List<FlSpot>>? buffer,
  }) {
    var variable =
        (index == -1
            ? ChartVariable(
              0,
              "Var ${vars.length}",
              COLORS_PALETTE[Random().nextInt(COLORS_PALETTE.length)],
            )
            : vars[index]);

    final color = variable.color.obs;

    Get.dialog(
      EditDialog(
        title: index == -1 ? "Add" : "Edit",
        submitText: index == -1 ? "Add" : "Save",
        onDelete:
            index != -1
                ? () {
                  vars.removeAt(index);
                  buffer?.removeAt(index);
                }
                : null,
        onSubmit: (data) {
          variable = ChartVariable(data["ID"], data["Name"], color.value);
          if (index == -1) {
            vars.add(variable);
            buffer?.add([]);
          } else {
            if (buffer != null && vars[index].id != variable.id) {
              buffer[index] = [];
            }
            vars[index] = variable;
          }
        },
        widgets: [
          EditDialogWidgetData(
            EditWidgetType.id,
            "ID",
            data: variable.id,
            extra: "id_exists",
          ),
          EditDialogWidgetData(
            EditWidgetType.text,
            "Name",
            data: variable.name,
          ),
          EditDialogWidgetData(
            EditWidgetType.custom,
            "Color",
            extra: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              spacing: 12,
              children: [
                const Text("Color: "),
                Obx(
                  () => IconButton(
                    onPressed: () => _showColorPicker(color),
                    icon: Icon(Icons.circle, color: color.value),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static void _showColorPicker(Rx<Color> color) {
    final Color prevColor = color.value;

    Get.dialog(
      AlertDialog(
        title: Text("Pick a color"),
        content: Obx(
          () => ColorPicker(
            pickerColor: color.value,
            onColorChanged: (c) => color.value = c,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              color.value = prevColor;
              Get.back();
            },
            child: Text("Cancel"),
          ),
          ElevatedButton(onPressed: () => Get.back(), child: Text("Ok")),
        ],
      ),
    );
  }
}
