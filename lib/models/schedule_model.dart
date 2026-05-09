// lib/models/schedule_model.dart
class ScheduleModel {
  final String id;
  final String name;
  final String startTime;
  final String endTime;
  final String repeat;
  final bool active;
  final String plantTypeId; // Properti baru

  ScheduleModel({
    required this.id,
    required this.name,
    required this.startTime,
    required this.endTime,
    required this.repeat,
    required this.active,
    required this.plantTypeId, // Diperlukan di konstruktor
  });

  factory ScheduleModel.fromMap(
    String id,
    Map<dynamic, dynamic> map,
    String plantTypeId,
  ) {
    return ScheduleModel(
      id: id,
      name: map['name'] ?? 'Unnamed',
      startTime: map['startTime'] ?? '00:00',
      endTime: map['endTime'] ?? '00:10',
      repeat: map['repeat'] ?? 'Daily',
      active: map['active'] ?? true,
      plantTypeId:
          map['plant_type_id']?.toString() ??
          plantTypeId, // Gunakan parameter jika map tidak punya nilai
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'startTime': startTime,
      'endTime': endTime,
      'repeat': repeat,
      'active': active,
      'plant_type_id': plantTypeId, // Simpan ke map
    };
  }

  // Metode untuk menyalin objek dengan perubahan
  ScheduleModel copyWith({
    String? id,
    String? name,
    String? startTime,
    String? endTime,
    String? repeat,
    bool? active,
    String? plantTypeId,
  }) {
    return ScheduleModel(
      id: id ?? this.id,
      name: name ?? this.name,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      repeat: repeat ?? this.repeat,
      active: active ?? this.active,
      plantTypeId: plantTypeId ?? this.plantTypeId,
    );
  }
}
