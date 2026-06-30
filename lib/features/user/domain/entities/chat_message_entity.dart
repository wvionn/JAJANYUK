import 'package:equatable/equatable.dart';

class ChatMessageEntity extends Equatable {
  final String text;
  final bool isMe;
  final DateTime time;
  final String? imageUrl;

  const ChatMessageEntity({
    required this.text,
    required this.isMe,
    required this.time,
    this.imageUrl,
  });

  @override
  List<Object?> get props => [text, isMe, time, imageUrl];
}
