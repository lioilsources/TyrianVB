import 'package:flutter/material.dart';

/// Reusable HP/Shield/Generator bar widget for HUD.
class HealthBar extends StatelessWidget {
  final String label;
  final double value;
  final double maxValue;
  final Color color;
  final Color? backgroundColor;
  final double height;

  const HealthBar({
    super.key,
    required this.label,
    required this.value,
    required this.maxValue,
    required this.color,
    this.backgroundColor,
    this.height = 16,
  });

  @override
  Widget build(BuildContext context) {
    final ratio = maxValue > 0 ? (value / maxValue).clamp(0.0, 1.0) : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$label: ${value.toInt()} / ${maxValue.toInt()}',
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Container(
          height: height,
          decoration: BoxDecoration(
            color: backgroundColor ?? Colors.black54,
            borderRadius: BorderRadius.circular(2),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: ratio,
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
