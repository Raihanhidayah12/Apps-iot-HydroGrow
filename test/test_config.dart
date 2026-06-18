// lib/test_config.dart
import 'services/firebase_service.dart';

void testConfigReading() async {
  print('🧪 Testing Firebase config reading...');

  final firebaseService = FirebaseService();

  // Test telegram config
  print('📱 Reading telegram config...');
  final telegramConfig = await firebaseService.getTelegramConfig();
  if (telegramConfig != null) {
    print(
      '✅ Telegram config: isActive=${telegramConfig.isActive}, botToken=${telegramConfig.botToken != null ? "SET" : "NULL"}, chatId=${telegramConfig.chatId != null ? "SET" : "NULL"}',
    );
  } else {
    print('⚠️ No telegram config found');
  }

  // Test threshold config
  print('⚙️ Reading threshold config...');
  final thresholdConfig = await firebaseService.getThresholdConfig();
  if (thresholdConfig != null) {
    print(
      '✅ Threshold config: moisture_min=${thresholdConfig.moistureMin}, moisture_max=${thresholdConfig.moistureMax}',
    );
    print(
      '   light_min=${thresholdConfig.lightMin}, light_max=${thresholdConfig.lightMax}',
    );
    print(
      '   water_min=${thresholdConfig.waterMin}, water_max=${thresholdConfig.waterMax}',
    );
    print('   battery_min=${thresholdConfig.batteryMin}');
  } else {
    print('⚠️ No threshold config found');
  }

  print('🎉 Config reading test completed!');
}
