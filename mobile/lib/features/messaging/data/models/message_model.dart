class MessageModel {
  final String id;
  final String conversationId;
  final String senderId;
  final String? senderName;
  final String content;
  final String originalLanguage;
  final bool isRead;
  final DateTime createdAt;
  String? translatedContent;

  MessageModel({
    required this.id,
    required this.conversationId,
    required this.senderId,
    this.senderName,
    required this.content,
    required this.originalLanguage,
    this.isRead = false,
    required this.createdAt,
    this.translatedContent,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    final sender = json['sender'] as Map<String, dynamic>?;
    return MessageModel(
      id: json['id'] ?? '',
      conversationId: json['conversationId'] ?? json['conversation_id'] ?? '',
      senderId: json['senderId'] ?? json['sender_id'] ?? '',
      senderName: sender?['username'] ?? 'User',
      content: json['content'] ?? '',
      originalLanguage: json['originalLanguage'] ?? json['original_language'] ?? 'fr',
      isRead: json['isRead'] ?? json['is_read'] ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }
}
