import 'package:flutter/material.dart';

/// A single row in the plan comparison table.
class FeatureRow extends StatelessWidget {
  const FeatureRow({
    super.key,
    required this.label,
    required this.basic,
    required this.growth,
    required this.pro,
  });

  final String label;
  final Widget basic;
  final Widget growth;
  final Widget pro;

  static Widget _check(bool value) => value
      ? const Icon(Icons.check_circle, color: Color(0xFF2196F3), size: 20)
      : const Icon(Icons.remove, color: Color(0xFFBDBDBD), size: 20);

  static Widget fromBool(bool value) => _check(value);

  static Widget fromText(String text) => Text(
        text,
        style: const TextStyle(fontSize: 13, color: Color(0xFF424242)),
        textAlign: TextAlign.center,
      );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF616161))),
          ),
          Expanded(child: Center(child: basic)),
          Expanded(child: Center(child: growth)),
          Expanded(child: Center(child: pro)),
        ],
      ),
    );
  }
}
