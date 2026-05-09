// lib/widgets/threshold_slider.dart
import 'package:flutter/material.dart';
import '../core/constants.dart';

class ThresholdSlider extends StatelessWidget {
  final String label;
  final String description;
  final int value;
  final ValueChanged<int> onChanged;
  final Color accentColor;

  const ThresholdSlider({
    super.key,
    required this.label,
    required this.description,
    required this.value,
    required this.onChanged,
    this.accentColor = Colors.green,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(32),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: TextStyle(
              color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 24),

          Row(
            children: [
              Text(
                "$value%",
                style: TextStyle(
                  fontSize: 42,
                  fontWeight: FontWeight.bold,
                  fontFamily: AppFonts.spaceGrotesk,
                  color: accentColor,
                ),
              ),
              const Spacer(),
              Text(
                "Kelembapan Tanah",
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6),
                ),
              ),
            ],
          ),

          Slider(
            value: value.toDouble(),
            min: 0,
            max: 100,
            divisions: 100,
            activeColor: accentColor,
            onChanged: (newValue) {
              onChanged(newValue.round());
            },
          ),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "0%",
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6),
                ),
              ),
              Text(
                "100%",
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
