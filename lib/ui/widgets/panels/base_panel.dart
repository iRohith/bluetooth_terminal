import 'package:flutter/material.dart';

class BasePanel<State> extends StatelessWidget {
  final String id;
  final String title;
  final double width;
  final Widget? child;
  final bool constraintHeight;

  const BasePanel({
    super.key,
    required this.id,
    this.title = 'Unknown',
    this.width = double.infinity,
    this.constraintHeight = true,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: loadState(),
      builder: (context, state) {
        Widget child = const Center(child: CircularProgressIndicator());

        if (state.hasError) {
          child = const Placeholder();
        } else if (state.connectionState == ConnectionState.done) {
          child = Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.normal),
              ),
              const SizedBox(height: 8),
              buildPanel(context, state.data) ??
                  this.child ??
                  Placeholder(),
            ],
          );
        }

        return Card(
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Container(
            width: width,
            constraints:
                constraintHeight ? const BoxConstraints(maxHeight: 250) : null,
            padding: const EdgeInsets.all(8.0),
            child:
                constraintHeight ? SingleChildScrollView(child: child) : child,
          ),
        );
      },
    );
  }

  Widget? buildPanel(BuildContext context, State? state) {
    return null;
  }

  Future<State?> loadState() async {
    return null;
  }
}
