import 'dart:async';
import 'dart:convert';

import 'package:bluetooth_terminal/modals/variable_data.dart';
import 'package:bluetooth_terminal/modals/chart_data.dart';
import 'package:bluetooth_terminal/utils/constants.dart';
import 'package:bluetooth_terminal/modals/data_packet.dart';
import 'package:bluetooth_terminal/modals/slider_data.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService extends GetxService {
  static StorageService get to => Get.find();

  late final SharedPreferences prefs;

  Future<void> init() async {
    prefs = await SharedPreferences.getInstance();
  }

  Future<bool> reset() async {
    return prefs.clear();
  }

  Future<List<VariableData>> loadVariables(
    String key, {
    int numDefaultVars = 8,
  }) async {
    try {
      final json =
          jsonDecode((prefs.getString("variables_$key"))!)[key] as List;
      final varList =
          json
              .map((e) => VariableData(e["id"] as int, e["name"] as String))
              .toList();
      return varList;
    } catch (e) {
      printError(info: "Error loadVariables $e");

      final varList = [
        VariableData(0x3, "V motor"),
        VariableData(0x4, "V ref"),
        VariableData(0x7, "Mode"),
        VariableData(0x5, "I motor"),
        VariableData(0x6, "I_m Limit"),
        VariableData(0x8, "Fault"),

        ...List.generate(
          numDefaultVars,
          (i) => VariableData(0x8 + 1 + i, "Var ${7 + i}"),
        ),
      ];

      await saveVariables(key, varList);
      return varList;
    }
  }

  Future<bool> saveVariables(String key, List<VariableData> variables) async {
    final saved = await prefs.setString(
      "variables_$key",
      jsonEncode({
        key: variables.map((e) => {"id": e.id, "name": e.name}).toList(),
      }),
    );
    return saved;
  }

  Future<List<(String, DataPacket)>> loadKeypad(
    String key, {
    int numDefaultKeys = 8,
  }) async {
    try {
      final json = jsonDecode((prefs.getString("keypad_$key"))!)[key] as List;
      final buttons =
          json
              .map(
                (e) => (e["name"] as String, DataPacket.fromJson(e["packet"])),
              )
              .toList();

      return buttons;
    } catch (e) {
      printError(info: "Error loadKeypad $e");

      if (numDefaultKeys > 0) {
        final buttons = List.generate(
          numDefaultKeys,
          (i) => ("K ${i + 1}", DataPacket(cmd: FLOAT_SEND, id: i, value: 0.0)),
        );

        await saveKeypad(key, buttons);
        return buttons;
      } else {
        return [];
      }
    }
  }

  Future<bool> saveKeypad(
    String key,
    List<(String, DataPacket)> buttons,
  ) async {
    bool saved = await prefs.setString(
      "keypad_$key",
      jsonEncode({
        key:
            buttons
                .map((e) => {"name": e.$1, "packet": e.$2.toJson()})
                .toList(),
      }),
    );
    return saved;
  }

  Future<List<(SliderData, DataPacket)>> loadSliders(String key) async {
    try {
      final json = jsonDecode((prefs.getString("sliders_$key"))!)[key] as List;
      final sliders =
          json
              .map(
                (e) => (
                  SliderData.fromJson(e["slider"]),
                  DataPacket.fromJson(e["packet"]),
                ),
              )
              .toList();
      return sliders;
    } catch (e) {
      printError(info: "Error loadSliders $e");

      final sliders = [
        (
          SliderData(name: "V motor", max: 220),
          DataPacket(cmd: FLOAT_SEND, id: 0x00),
        ),
        (
          SliderData(name: "I_m limit", max: 25),
          DataPacket(cmd: FLOAT_SEND, id: 0x01),
        ),
      ];

      await saveSliders(key, sliders);
      return sliders;
    }
  }

  Future<bool> saveSliders(
    String key,
    List<(SliderData, DataPacket)> sliders,
  ) async {
    bool saved = await prefs.setString(
      "sliders_$key",
      jsonEncode({
        key:
            sliders
                .map((e) => {"slider": e.$1.toJson(), "packet": e.$2.toJson()})
                .toList(),
      }),
    );
    return saved;
  }

  Future<List<ChartData>> loadCharts(String key) async {
    try {
      final json = jsonDecode((prefs.getString("charts_$key"))!)[key] as List;
      final charts = json.map((e) => ChartData.fromJson(e)).toList();
      return charts;
    } catch (e) {
      printError(info: "Error loadCharts $e");

      final charts = [
        ChartData(
          name: "Chart 1",
          minY: 0,
          maxY: 0,
          variables: [
            ChartVariable(0x3, "V motor", Colors.red),
            ChartVariable(0x5, "I motor", Colors.green),
          ],
        ),
      ];

      await saveCharts(key, charts);
      return charts;
    }
  }

  Future<bool> saveCharts(String key, List<ChartData> charts) async {
    bool saved = await prefs.setString(
      "charts_$key",
      jsonEncode({key: charts.map((e) => e.toJson()).toList()}),
    );
    return saved;
  }
}
