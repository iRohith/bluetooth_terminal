import 'package:bluetooth_terminal/modals/data_packet.dart';
import 'package:bluetooth_terminal/ui/pages/page_wrapper.dart';
import 'package:bluetooth_terminal/ui/widgets/panels/keypad_panel.dart';
import 'package:bluetooth_terminal/ui/widgets/panels/sliders_panel.dart';
import 'package:bluetooth_terminal/ui/widgets/panels/variables_panel.dart';
import 'package:bluetooth_terminal/utils/constants.dart';
import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return PageWrapper(
      title: "Home",
      panels: [
        const VariablesPanel(
          title: "Variables",
          id: "home_variables",
          constraintHeight: true,
          showAddButton: false,
        ),

        const KeypadPanel(
          title: "Keypad",
          id: "home_keypad",
          showAddButton: false,
          constraintHeight: true,
          labelledButtons: [
            [
              ("ON", DataPacket(cmd: ON_SEND, id: 0x11)),
              ("OFF", DataPacket(cmd: OFF_SEND, id: 0x12)),
              ("MODE", DataPacket(cmd: MODE_SEND, id: 0x13)),
            ],
          ],
        ),

        const SlidersPanel(
          title: "Sliders",
          id: "home_sliders",
          showAddButton: false,
          constraintHeight: false,
        ),
      ],
    );
  }
}
