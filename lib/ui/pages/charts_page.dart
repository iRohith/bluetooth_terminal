import 'package:bluetooth_terminal/modals/chart_data.dart';
import 'package:bluetooth_terminal/services/storage_service.dart';
import 'package:bluetooth_terminal/ui/pages/page_wrapper.dart';
import 'package:bluetooth_terminal/ui/widgets/panels/chart_panel.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ChartsPage extends StatelessWidget {
  const ChartsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: StorageService.to.loadCharts("charts"),
      builder:
          (_, v) =>
              v.data == null
                  ? const SizedBox()
                  : SizedBox(
                    width: double.infinity,
                    child: _buildPage(v.data!),
                  ),
    );
  }

  Widget _buildPage(List<ChartData> initData) {
    final List<List<List<FlSpot>>> buffer = List.generate(
      initData.length,
      (_) => [],
    );

    List<ChartPanel> panels = [];

    return ValueBuilder<List<ChartData>?>(
      initialValue: initData,
      onUpdate: (v) {
        StorageService.to.saveCharts("charts", v!);
      },
      builder: (charts, updateFn) {
        void update(int i, ChartData? c, {bool refresh = false}) {
          if (c == null) {
            charts!.removeAt(i);
            buffer.removeAt(i);
            refresh = true;
          } else if (i == -1) {
            charts!.add(c);
            buffer.add([]);
            refresh = true;
          } else {
            charts![i] = c;
          }

          if (refresh) {
            for (final panel in panels) {
              panel.closeSubs();
            }
            updateFn(charts);
          }
        }

        panels = List.generate(
          charts!.length,
          (i) => ChartPanel(
            chartData: charts[i],
            updateFn: (c) => update(i, c),
            buffer: buffer[i],
            id: 'chart_$i',
          ),
        );

        return PageWrapper(
          title: "Charts",
          extraWidget: ElevatedButton(
            onPressed:
                () => ChartPanel.showAddOrEditChartDialog(
                  (c) => update(-1, c, refresh: true),
                  defaultName: "Chart ${charts.length + 1}",
                ),
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              backgroundColor: Get.theme.colorScheme.primaryContainer,
              foregroundColor: Get.theme.colorScheme.onPrimaryContainer,
              elevation: 8,
            ),
            child: const Text("Add chart"),
          ),
          panels: panels,
        );
      },
    );
  }
}
