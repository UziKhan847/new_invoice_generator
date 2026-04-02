import 'package:flutter/material.dart';

class SimpleChartPlaceholder extends StatelessWidget {
  final String title;
  const SimpleChartPlaceholder({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: SizedBox(height: 180, child: Center(child: Text(title))),
    );
  }
}