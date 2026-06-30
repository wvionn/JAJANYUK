import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/cart_provider.dart';

class ChatMessage {
  final String text;
  final bool isMe;
  final DateTime time;
  final String? imageUrl;

  const ChatMessage({
    required this.text,
    required this.isMe,
    required this.time,
    this.imageUrl,
  });
}

// Real-time chat messages stream provider based on orderId
final userChatStreamProvider = StreamProvider.family<List<ChatMessage>, String>((ref, orderId) {
  final client = Supabase.instance.client;
  final currentUserId = client.auth.currentUser?.id ?? '';
  
  return client
      .from('chat_messages')
      .stream(primaryKey: ['id'])
      .eq('order_id', orderId)
      .order('created_at')
      .map((list) {
        return list.map((e) {
          return ChatMessage(
            text: e['message'] as String? ?? '',
            isMe: (e['sender_id'] as String?) == currentUserId,
            time: e['created_at'] != null 
                ? DateTime.parse(e['created_at'] as String) 
                : DateTime.now(),
          );
        }).toList();
      });
});

class ChatPage extends ConsumerStatefulWidget {
  final String vendorId;
  final String vendorName;

  const ChatPage({
    super.key,
    required this.vendorId,
    required this.vendorName,
  });

  @override
  ConsumerState<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends ConsumerState<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<String> _quickReplies = [
    'Berapa lama estimasi pesanan?',
    'Apakah ada promo hari ini?',
    'Saya mau pesan ulang',
    'Pesanan saya sudah siap?',
  ];

  Future<void> _sendMessage(String text, String orderId) async {
    if (text.trim().isEmpty) return;
    final client = Supabase.instance.client;
    final currentUserId = client.auth.currentUser?.id;
    if (currentUserId == null) return;

    try {
      await client.from('chat_messages').insert({
        'order_id': orderId,
        'sender_id': currentUserId,
        'message': text.trim(),
        'is_read': false,
        'created_at': DateTime.now().toIso8601String(),
      });
      _messageController.clear();
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengirim pesan: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients &&
          _scrollController.position.hasContentDimensions) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _formatTime(DateTime time) {
    final localTime = time.toLocal();
    final h = localTime.hour.toString().padLeft(2, '0');
    final m = localTime.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(orderHistoryProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black),
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: const Color(0xFF4F7FFF),
              child: Text(
                widget.vendorName.isNotEmpty ? widget.vendorName[0].toUpperCase() : 'W',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.vendorName,
                    style: const TextStyle(color: Colors.black, fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  const Row(
                    children: [
                      Icon(Icons.circle, size: 8, color: Colors.green),
                      SizedBox(width: 4),
                      Text('Online sekarang', style: TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.normal)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.call_outlined, color: Colors.grey),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Fitur telepon segera hadir'), behavior: SnackBarBehavior.floating),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.grey),
            onPressed: () {},
          ),
        ],
      ),
      body: ordersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text('Gagal memuat data pesanan: $err', textAlign: TextAlign.center),
          ),
        ),
        data: (orders) {
          final latestOrder = orders.where((o) => o.vendorId == widget.vendorId).firstOrNull;
          if (latestOrder == null) {
            return _buildNoOrderView();
          }

          final chatAsync = ref.watch(userChatStreamProvider(latestOrder.id));

          return chatAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Gagal memuat obrolan: $err', textAlign: TextAlign.center),
              ),
            ),
            data: (messages) {
              return Column(
                children: [
                  // Chat area
                  Expanded(
                    child: messages.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.chat_bubble_outline, size: 56, color: Colors.grey[400]),
                                const SizedBox(height: 12),
                                Text(
                                  'Mulai percakapan dengan ${widget.vendorName}',
                                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            controller: _scrollController,
                            reverse: true,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            itemCount: messages.length,
                            itemBuilder: (context, index) {
                              // Reverse order so newest message is at the bottom
                              final reversedIndex = messages.length - 1 - index;
                              return _buildBubble(messages[reversedIndex]);
                            },
                          ),
                  ),

                  // Quick replies
                  SizedBox(
                    height: 44,
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      scrollDirection: Axis.horizontal,
                      itemCount: _quickReplies.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        return GestureDetector(
                          onTap: () => _sendMessage(_quickReplies[index], latestOrder.id),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: const Color(0xFF4F7FFF).withValues(alpha: 0.4)),
                            ),
                            child: Text(
                              _quickReplies[index],
                              style: const TextStyle(
                                color: Color(0xFF4F7FFF),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Input bar
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -3))],
                    ),
                    child: SafeArea(
                      child: Row(
                        children: [
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFFF0F4FF),
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.emoji_emotions_outlined, color: Colors.grey),
                                    onPressed: () {},
                                  ),
                                  Expanded(
                                    child: TextField(
                                      controller: _messageController,
                                      decoration: const InputDecoration(
                                        hintText: 'Ketik pesan...',
                                        hintStyle: TextStyle(color: Colors.grey),
                                        border: InputBorder.none,
                                        isDense: true,
                                      ),
                                      textInputAction: TextInputAction.send,
                                      onSubmitted: (val) => _sendMessage(val, latestOrder.id),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.attach_file_outlined, color: Colors.grey),
                                    onPressed: () {},
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          GestureDetector(
                            onTap: () => _sendMessage(_messageController.text, latestOrder.id),
                            child: Container(
                              width: 46,
                              height: 46,
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Color(0xFF4F7FFF), Color(0xFF7BA7FF)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildNoOrderView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline_rounded, size: 72, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text(
              'Belum Ada Pesanan',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Anda belum melakukan pemesanan di ${widget.vendorName}. Silakan pesan makanan terlebih dahulu untuk memulai obrolan dengan penjual.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600], height: 1.4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBubble(ChatMessage msg) {
    final isMe = msg.isMe;
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isMe ? const Color(0xFF4F7FFF) : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isMe ? 18 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 18),
                ),
                boxShadow: [
                  BoxShadow(
                    color: (isMe ? const Color(0xFF4F7FFF) : Colors.black).withValues(alpha: 0.1),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                msg.text,
                style: TextStyle(
                  color: isMe ? Colors.white : Colors.black87,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatTime(msg.time),
                  style: const TextStyle(color: Colors.grey, fontSize: 11),
                ),
                if (isMe) ...[
                  const SizedBox(width: 4),
                  const Icon(Icons.done_all, size: 14, color: Color(0xFF4F7FFF)),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
