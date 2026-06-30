import '../entities/chat_message_entity.dart';

abstract class ChatRepository {
  Stream<List<ChatMessageEntity>> watchChatMessages(String orderId);
  Future<void> sendMessage({
    required String orderId,
    required String text,
  });
}
