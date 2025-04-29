import 'package:bluetooth_terminal/modals/data_packet.dart';
import 'package:bluetooth_terminal/ui/pages/page_wrapper.dart';
import 'package:bluetooth_terminal/ui/widgets/panels/keypad_panel.dart';
import 'package:bluetooth_terminal/ui/widgets/panels/sliders_panel.dart';
import 'package:bluetooth_terminal/utils/constants.dart';
import 'package:flutter/material.dart';

class KeypadPage extends StatelessWidget {
  const KeypadPage({super.key});

  @override
  Widget build(BuildContext context) {
    return PageWrapper(
      title: "Keypad",
      panels: [
        KeypadPanel(
          title: "Keypad",
          id: "keypad",
          showAddButton: true,
          enableSendMessageButton: true,
          constraintHeight: false,
          labelledButtons: [
            [
              ("ON", DataPacket(cmd: ON_SEND, id: 0x11)),
              ("OFF", DataPacket(cmd: OFF_SEND, id: 0x12)),
              ("MODE", DataPacket(cmd: MODE_SEND, id: 0x13)),
            ],
            [
              ("UP", DataPacket(cmd: UP_SEND, id: 0x14)),
              ("DOWN", DataPacket(cmd: DOWN_SEND, id: 0x15)),
            ],
          ],
        ),

        SlidersPanel(
          id: "sliders",
          title: "Sliders",
          constraintHeight: false,
          showAddButton: true,
        ),
      ],
    );
  }
}
