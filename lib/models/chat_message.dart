class ChatMessage {
  final String id;
  final String clanId;
  final String companyId;
  final String content;
  final DateTime createdAt;
  final String? senderName;

  const ChatMessage({
    required this.id,
    required this.clanId,
    required this.companyId,
    required this.content,
    required this.createdAt,
    this.senderName,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String,
      clanId: json['clan_id'] as String? ?? '',
      companyId: json['company_id'] as String? ?? '',
      content: json['content'] as String? ?? '',
      createdAt: DateTime.parse(json['created_at'] as String? ?? DateTime.now().toIso8601String()),
      senderName: json['sender_name'] as String?,
    );
  }

  String get timeAgo {
    final now = DateTime.now();
    final diff = now.difference(createdAt);
    if (diff.inMinutes < 1) return 'только что';
    if (diff.inMinutes < 60) return '${diff.inMinutes}м назад';
    if (diff.inHours < 24) return '${diff.inHours}ч назад';
    if (diff.inDays < 7) return '${diff.inDays}д назад';
    return '${createdAt.day}.${createdAt.month.toString().padLeft(2, '0')}.${createdAt.year % 100}';
  }
}