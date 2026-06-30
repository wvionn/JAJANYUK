import 'package:supabase_flutter/supabase_flutter.dart';

class ChatRemoteDatasource {
  final SupabaseClient _client;

  ChatRemoteDatasource(this._client);

  Stream<List<Map<String, dynamic>>> watchChatMessages(String orderId) {
    return _client
        .from('chat_messages')
        .stream(primaryKey: ['id'])
        .eq('order_id', orderId)
        .order('created_at');
  }

  Future<void> sendMessage({
    required String orderId,
    required String text,
  }) async {
    final currentUserId = _client.auth.currentUser?.id;
    if (currentUserId == null) throw Exception('User not authenticated');

    await _client.from('chat_messages').insert({
      'order_id': orderId,
      'sender_id': currentUserId,
      'message': text.trim(),
      'is_read': false,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  String? getCurrentUserId() {
    return _client.auth.currentUser?.id;
  }
}
