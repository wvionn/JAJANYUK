import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/datasources/chat_remote_datasource.dart';
import '../../data/repositories/chat_repository_impl.dart';
import '../../domain/entities/chat_message_entity.dart';
import '../../domain/repositories/chat_repository.dart';

final chatRemoteDatasourceProvider = Provider<ChatRemoteDatasource>((ref) {
  return ChatRemoteDatasource(Supabase.instance.client);
});

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepositoryImpl(ref.watch(chatRemoteDatasourceProvider));
});

final userChatStreamProvider = StreamProvider.family<List<ChatMessageEntity>, String>((ref, orderId) {
  return ref.watch(chatRepositoryProvider).watchChatMessages(orderId);
});
