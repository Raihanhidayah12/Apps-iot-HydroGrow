import 'package:flutter/material.dart';
import '../core/constants.dart';

class SensorCard extends StatelessWidget {
  final String label;
  final double value;
  final String unit;
  final IconData icon;
  final Color color;
  final String? subtitle;
  final bool isDarkCard;

  const SensorCard({
    super.key,
    required this.label,
    required this.value,
    this.unit = '%',
    required this.icon,
    required this.color,
    this.subtitle,
    this.isDarkCard = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.95, end: 1.0),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutBack,
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: (isDark || isDarkCard) ? _buildDarkCard() : _buildLightCard(),
        );
      },
    );
  }

  Widget _buildLightCard() {
    return Container(
      padding: const EdgeInsets.all(20), // Padding lebih lega
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white), // Glass border effect
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.08), // Shadow mengikuti warna tema sensor
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLabelText(Colors.grey[500]!),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildAnimatedValue(color),
                    if (subtitle != null) _buildSubtitle(Colors.grey[400]!),
                  ],
                ),
              ),
              _buildIconBox(color.withOpacity(0.1), color),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDarkCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBgDark, // Fixed dark card color
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLabelText(color.withOpacity(0.6)),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildAnimatedValue(Colors.white),
                    if (subtitle != null) _buildSubtitle(color.withOpacity(0.8)),
                  ],
                ),
              ),
              _buildIconBox(Colors.white.withOpacity(0.05), color),
            ],
          ),
        ],
      ),
    );
  }

  // Animasi angka sensor yang bertambah/berkurang secara halus
  Widget _buildAnimatedValue(Color textColor) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: value),
      duration: const Duration(seconds: 1),
      curve: Curves.easeOutExpo,
      builder: (context, animatedValue, child) {
        return FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            "${animatedValue.toStringAsFixed(0)}$unit",
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: textColor,
              letterSpacing: -0.5,
            ),
          ),
        );
      },
    );
  }

  Widget _buildLabelText(Color textColor) {
    return Text(
      label.toUpperCase(),
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w800,
        color: textColor,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildSubtitle(Color textColor) {
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Text(
        subtitle!,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 11, 
          color: textColor,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildIconBox(Color bgColor, Color iconColor) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Icon(icon, size: 22, color: iconColor),
    );
  }
}