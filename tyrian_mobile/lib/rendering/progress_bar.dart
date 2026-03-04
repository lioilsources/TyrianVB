import 'package:flutter/material.dart';

/// Simple gradient progress bar for OSD panel.
class ProgressBar extends StatelessWidget {
  final double value;
  final double maxValue;
  final List<Color> gradientColors;
  final double height;
  final double width;

  const ProgressBar({
    super.key,
    required this.value,
    required this.maxValue,
    this.gradientColors = const [Color(0xFF00FF00), Color(0xFF88FF00)],
    this.height = 12,
    this.width = double.infinity,
  });

  @override
  Widget build(BuildContext context) {
    final ratio = maxValue > 0 ? (value / maxValue).clamp(0.0, 1.0) : 0.0;

    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(2),
        border: Border.all(color: Colors.white24, width: 0.5),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: ratio,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: gradientColors),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }
}
