import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import '../models/schedule_model.dart';
import '../models/telegram_config_model.dart';
import '../models/threshold_config_model.dart';

class FirebaseService {
  final DatabaseReference _db = FirebaseDatabase.instance.ref();

  FirebaseService() {
    if (!kIsWeb) {
      // Enable persistence for offline capability on mobile/desktop only.
      FirebaseDatabase.instance.setPersistenceEnabled(true);
      FirebaseDatabase.instance.setPersistenceCacheSizeBytes(10000000); // 10MB
    }

    // Debug: Check connection
    _checkConnection();
  }

  void _checkConnection() {
    _db.child('.info/connected').onValue.listen((event) {
      final connected = event.snapshot.value as bool? ?? false;
      print('🔥 Firebase Database Connected: $connected');
    });

    // Test write only in debug mode to avoid polluting production database
    if (kDebugMode) {
      _testWrite();
    }
  }

  void _testWrite() async {
    try {
      await _db.child('test/connection').set({
        'timestamp': DateTime.now().toIso8601String(),
        'message': 'Connection test from Flutter app',
      });
      print('✅ Test write successful');
    } catch (e) {
      print('❌ Test write failed: $e');
    }
  }

  // Sensor Live
  Stream<DatabaseEvent> getSensorLive() {
    print('📡 Listening to sensor_live...');
    return _db.child('device/sensor_live').onValue;
  }

  // History
  Stream<DatabaseEvent> getHistory() {
    return _db.child('history').onValue;
  }

  // Units
  Stream<DatabaseEvent> getUnitsStream() {
    return _db.child('device/units').onValue;
  }

  // Thresholds
  Future<void> updateThreshold(String key, int value) async {
    await _db.child('config/thresholds').update({key: value});
  }

  // Manual Pump
  Future<void> activateManualPump(
    int durationMinutes, {
    String source = 'quick',
    bool? isActive,
  }) async {
    await _db.child('device/control/manualTimer').set({
      'duration': durationMinutes,
      'isActive': isActive ?? (durationMinutes > 0),
      'timestamp': DateTime.now().toIso8601String(),
      'source': source,
    });
  }

  // Schedules - DISESUAIKAN DENGAN STRUKTUR BARU
  Stream<DatabaseEvent> getSchedulesStream(String plantTypeId) {
    print('🌿 Listening to schedules for plant type: $plantTypeId');
    return _db.child('config/plant_types/$plantTypeId/schedules').onValue;
  }

  String getNewScheduleId(String plantTypeId) {
    return _db.child('config/plant_types/$plantTypeId/schedules').push().key!;
  }

  Future<void> addSchedule(ScheduleModel schedule) async {
    await _db
        .child(
          'config/plant_types/${schedule.plantTypeId}/schedules/${schedule.id}',
        )
        .set(schedule.toMap());
  }

  Future<void> updateSchedule(ScheduleModel schedule) async {
    await _db
        .child(
          'config/plant_types/${schedule.plantTypeId}/schedules/${schedule.id}',
        )
        .update(schedule.toMap());
  }

  Future<void> deleteSchedule(String plantTypeId, String scheduleId) async {
    await _db
        .child('config/plant_types/$plantTypeId/schedules/$scheduleId')
        .remove();
  }

  // Telegram Active
  Future<void> setTelegramActive(bool isActive) async {
    await _db.child('config/telegram').update({'isActive': isActive});
  }

  // Get Telegram Config
  Future<TelegramConfig?> getTelegramConfig() async {
    try {
      final snapshot = await _db.child('config/telegram').get();
      if (snapshot.value != null) {
        final data = Map<dynamic, dynamic>.from(snapshot.value as Map);
        return TelegramConfig.fromMap(data);
      }
      return null;
    } catch (e) {
      print('❌ Error getting telegram config: $e');
      return null;
    }
  }

  // Update Telegram Config
  Future<void> updateTelegramConfig(TelegramConfig config) async {
    await _db.child('config/telegram').set(config.toMap());
  }

  // Get Threshold Config
  Future<ThresholdConfig?> getThresholdConfig() async {
    try {
      final snapshot = await _db.child('config/thresholds').get();
      if (snapshot.value != null) {
        final data = Map<dynamic, dynamic>.from(snapshot.value as Map);
        return ThresholdConfig.fromMap(data);
      }
      return null;
    } catch (e) {
      print('❌ Error getting threshold config: $e');
      return null;
    }
  }

  // Get Threshold Config Stream - NEW for real-time sync
  Stream<DatabaseEvent> getThresholdConfigStream() {
    print('📡 Listening to threshold config...');
    return _db.child('config/thresholds').onValue;
  }

  // Update Threshold Config
  Future<void> updateThresholdConfig(ThresholdConfig config) async {
    await _db.child('config/thresholds').set(config.toMap());
  }

  // Pump Status
  Stream<DatabaseEvent> getPumpStatusStream() {
    return _db.child('device/control/manualTimer').onValue;
  }

  // Get current pump source for UI
  Future<String?> getPumpSource() async {
    try {
      final snapshot = await _db
          .child('device/control/manualTimer/source')
          .get();
      return snapshot.value as String?;
    } catch (e) {
      print('Error getting pump source: $e');
      return null;
    }
  }

  // Logout
  Future<void> logout() async {
    // Implementasi logout Firebase nanti jika diperlukan
  }

  // Get Plant Types (Categories)
  Stream<DatabaseEvent> getPlantTypesStream() {
    print('🌿 Listening to plant types...');
    return _db.child('config/plant_types').onValue;
  }
}
