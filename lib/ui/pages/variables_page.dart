import 'package:bluetooth_terminal/ui/pages/page_wrapper.dart';
import 'package:bluetooth_terminal/ui/widgets/panels/variables_panel.dart';
import 'package:flutter/material.dart';

class VariablesPage extends StatelessWidget {
  const VariablesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const PageWrapper(
      title: "Variables",
      panels: [
        VariablesPanel(
          id: "variables",
          constraintHeight: false,
          showAddButton: true,
        ),
      ],
    );
  }
}
