import '../../domain/entities/chat_message_entity.dart';
import '../../domain/repositories/chat_repository.dart';
import '../datasources/chat_remote_datasource.dart';

class ChatRepositoryImpl implements ChatRepository {
  final ChatRemoteDatasource _datasource;

  ChatRepositoryImpl(this._datasource);

  @override
  Stream<List<ChatMessageEntity>> watchChatMessages(String orderId) {
    final currentUserId = _datasource.getCurrentUserId() ?? '';
    return _datasource.watchChatMessages(orderId).map((list) {
      return list.map((e) {
        return ChatMessageEntity(
          text: e['message'] as String? ?? '',
          isMe: (e['sender_id'] as String?) == currentUserId,
          time: e['created_at'] != null 
              ? DateTime.parse(e['created_at'] as String) 
              : DateTime.now(),
        );
      }).toList();
    });
  }

  @override
  Future<void> sendMessage({
    required String orderId,
    required String text,
  }) async {
    await _datasource.sendMessage(orderId: orderId, text: text);
  }
}
