// lib/models/telegram_config_model.dart
class TelegramConfig {
  final bool isActive;
  final String? botToken;
  final String? chatId;

  const TelegramConfig({required this.isActive, this.botToken, this.chatId});

  factory TelegramConfig.fromMap(Map<dynamic, dynamic> map) {
    return TelegramConfig(
      isActive: map['isActive'] as bool? ?? false,
      botToken: map['botToken'] as String?,
      chatId: map['chatId'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'isActive': isActive,
      if (botToken != null) 'botToken': botToken,
      if (chatId != null) 'chatId': chatId,
    };
  }

  TelegramConfig copyWith({bool? isActive, String? botToken, String? chatId}) {
    return TelegramConfig(
      isActive: isActive ?? this.isActive,
      botToken: botToken ?? this.botToken,
      chatId: chatId ?? this.chatId,
    );
  }
}
