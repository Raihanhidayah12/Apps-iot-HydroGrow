// lib/models/sensor_model.dart
class SensorData {
  final double moisture;
  final double light;
  final double water;
  final double battery;
  final String time;
  final String? plantType;
  final Map<dynamic, dynamic> rawData;

  SensorData({
    required this.moisture,
    required this.light,
    required this.water,
    required this.battery,
    required this.time,
    this.plantType,
    this.rawData = const {},
  });

  factory SensorData.fromMap(Map<dynamic, dynamic> map) {
    return SensorData(
      moisture: double.tryParse(map['moisture']?.toString() ?? '0') ?? 0.0,
      light: double.tryParse(map['light']?.toString() ?? '0') ?? 0.0,
      water: double.tryParse((map['water'] ?? map['water_level'])?.toString() ?? '0') ?? 0.0,
      battery: double.tryParse(map['battery']?.toString() ?? '0') ?? 0.0,
      time: (map['time'] ?? map['timestamp'])?.toString() ?? 'Unknown',
      plantType: map['plantType']?.toString(),
      rawData: Map<dynamic, dynamic>.from(map),
    );
  }

  double? getMoisture(String plantType) {
    final ptLower = plantType.toLowerCase();
    if (rawData.containsKey(ptLower)) {
      final plantData = rawData[ptLower];
      if (plantData is Map) {
        for (var boxKey in plantData.keys) {
          final boxData = plantData[boxKey];
          if (boxData is Map && boxData.containsKey('moisture')) {
            return (boxData['moisture'] ?? 0).toDouble();
          }
        }
      }
    }
    // Fallback if not found inside nested structure
    if (rawData.containsKey('moisture')) {
      return (rawData['moisture'] ?? 0).toDouble();
    }
    return null;
  }

  DateTime get timestamp {
    try {
      // 1. Try to find an explicit timestamp string inside the nested structure
      for (var plantKey in rawData.keys) {
        if (rawData[plantKey] is Map) {
          final plantData = rawData[plantKey] as Map;
          for (var boxKey in plantData.keys) {
            final boxData = plantData[boxKey];
            if (boxData is Map && boxData.containsKey('timestamp')) {
              final nestedTime = boxData['timestamp']?.toString();
              if (nestedTime != null && nestedTime.isNotEmpty) {
                return DateTime.parse(nestedTime);
              }
            }
          }
        }
      }

      // 2. If no nested timestamp exists, parse the key (e.g. "2026-04-30_17-19-09")
      if (time.contains('_') && time.contains('-')) {
        final parts = time.split('_');
        if (parts.length == 2) {
          final datePart = parts[0]; // "2026-04-30"
          final timePart = parts[1].replaceAll('-', ':'); // "17:19:09"
          return DateTime.parse('$datePart $timePart');
        }
      }

      // 3. Fallback to standard parse
      return DateTime.parse(time);
    } catch (e) {
      return DateTime.now();
    }
  }

  /// Returns a list of alert messages if any sensor value is below the threshold.
  List<Map<String, dynamic>> getCriticalAlerts(dynamic thresholdConfig) {
    final List<Map<String, dynamic>> alerts = [];
    if (thresholdConfig == null) return alerts;

    // Check Water
    if (water < thresholdConfig.waterMin) {
      alerts.add({
        'type': 'water',
        'title': 'Water Level Critical',
        'message': 'Water level is at ${water.toStringAsFixed(0)}% (Min: ${thresholdConfig.waterMin}%)',
        'value': water,
        'icon': 'water_drop',
      });
    }

    // Check Battery
    if (battery < thresholdConfig.batteryMin) {
      alerts.add({
        'type': 'battery',
        'title': 'Low Battery',
        'message': 'Battery is at ${battery.toStringAsFixed(0)}% (Min: ${thresholdConfig.batteryMin}%)',
        'value': battery,
        'icon': 'battery_alert',
      });
    }

    // Check Moisture for each plant/box in rawData
    for (var plantKey in rawData.keys) {
      if (rawData[plantKey] is Map) {
        final plantData = rawData[plantKey] as Map;
        for (var boxKey in plantData.keys) {
          final boxData = plantData[boxKey];
          if (boxData is Map && boxData.containsKey('moisture')) {
            final mValue = (boxData['moisture'] ?? 0).toDouble();
            if (mValue < thresholdConfig.moistureMin) {
              alerts.add({
                'type': 'moisture',
                'title': 'Soil Too Dry',
                'message': '${plantKey.toUpperCase()} ($boxKey) is at ${mValue.toStringAsFixed(0)}% (Min: ${thresholdConfig.moistureMin}%)',
                'value': mValue,
                'icon': 'opacity',
              });
            }
          }
        }
      }
    }

    return alerts;
  }
}
