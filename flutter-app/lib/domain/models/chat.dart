class ChatUser {
  final int id;
  final String name;
  final String? role;
  final int unread;
  final String? last;
  final String? lastAt;

  ChatUser({
    required this.id,
    required this.name,
    this.role,
    this.unread = 0,
    this.last,
    this.lastAt,
  });

  factory ChatUser.fromJson(Map<String, dynamic> json) => ChatUser(
        id: json['id'] as int? ?? 0,
        name: (json['name'] as String?) ?? '',
        role: json['role'] as String?,
        unread: (json['unread'] as num?)?.toInt() ?? 0,
        last: json['last'] as String?,
        lastAt: json['last_at'] as String?,
      );
}

class ChatMessage {
  final int id;
  final int senderId;
  final int receiverId;
  final String content;
  final String? createdAt;
  final String? senderName;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.content,
    this.createdAt,
    this.senderName,
  });

  bool isMine(int myId) => senderId == myId;

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    final sender = json['sender'];
    return ChatMessage(
      id: json['id'] as int? ?? 0,
      senderId: (json['sender_id'] as num?)?.toInt() ?? 0,
      receiverId: (json['receiver_id'] as num?)?.toInt() ?? 0,
      content: (json['content'] as String?) ?? '',
      createdAt: json['created_at'] as String?,
      senderName: sender is Map ? (sender['name'] as String?) : null,
    );
  }
}