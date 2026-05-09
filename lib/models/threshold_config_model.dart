// lib/models/threshold_config_model.dart
class ThresholdConfig {
  final int moistureMin;
  final int moistureMax;
  final int lightMin;
  final int lightMax;
  final int waterMin;
  final int waterMax;
  final int batteryMin;

  const ThresholdConfig({
    required this.moistureMin,
    required this.moistureMax,
    required this.lightMin,
    required this.lightMax,
    required this.waterMin,
    required this.waterMax,
    required this.batteryMin,
  });

  factory ThresholdConfig.fromMap(Map<dynamic, dynamic> map) {
    return ThresholdConfig(
      moistureMin: (map['moisture_min'] as num?)?.toInt() ?? 30,
      moistureMax: (map['moisture_max'] as num?)?.toInt() ?? 80,
      lightMin: (map['light_min'] as num?)?.toInt() ?? 20,
      lightMax: (map['light_max'] as num?)?.toInt() ?? 90,
      waterMin: (map['water_min'] as num?)?.toInt() ?? 10,
      waterMax: (map['water_max'] as num?)?.toInt() ?? 95,
      batteryMin: (map['battery_min'] as num?)?.toInt() ?? 15,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'moisture_min': moistureMin,
      'moisture_max': moistureMax,
      'light_min': lightMin,
      'light_max': lightMax,
      'water_min': waterMin,
      'water_max': waterMax,
      'battery_min': batteryMin,
    };
  }

  ThresholdConfig copyWith({
    int? moistureMin,
    int? moistureMax,
    int? lightMin,
    int? lightMax,
    int? waterMin,
    int? waterMax,
    int? batteryMin,
  }) {
    return ThresholdConfig(
      moistureMin: moistureMin ?? this.moistureMin,
      moistureMax: moistureMax ?? this.moistureMax,
      lightMin: lightMin ?? this.lightMin,
      lightMax: lightMax ?? this.lightMax,
      waterMin: waterMin ?? this.waterMin,
      waterMax: waterMax ?? this.waterMax,
      batteryMin: batteryMin ?? this.batteryMin,
    );
  }
}
