// lib/services/telegram_service.dart
import 'dart:developer';
import 'package:http/http.dart' as http;
import '../core/constants.dart';

class TelegramService {
  static Future<void> sendMessage(String message) async {
    try {
      final url = Uri.parse(
        'https://api.telegram.org/bot${AppConstants.telegramBotToken}/sendMessage',
      );

      await http.post(
        url,
        body: {
          'chat_id': AppConstants.telegramChatId,
          'text': message,
          'parse_mode': 'HTML',
        },
      );
    } catch (e) {
      log('Telegram error: $e');
    }
  }
}
