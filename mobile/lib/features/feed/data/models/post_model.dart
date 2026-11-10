class PostModel {
  final String id;
  final String authorId;
  final String authorName;
  final String? authorAvatar;
  final String content;
  final String originalLanguage;
  final List<String> mediaUrls;
  final int likesCount;
  final int commentsCount;
  final DateTime createdAt;
  String? translatedContent;
  bool isTranslating;

  PostModel({
    required this.id,
    required this.authorId,
    required this.authorName,
    this.authorAvatar,
    required this.content,
    required this.originalLanguage,
    this.mediaUrls = const [],
    this.likesCount = 0,
    this.commentsCount = 0,
    required this.createdAt,
    this.translatedContent,
    this.isTranslating = false,
  });

  factory PostModel.fromJson(Map<String, dynamic> json) {
    final author = json['author'] as Map<String, dynamic>?;
    final authorName = author != null
        ? ((author['firstName'] != null && (author['firstName'] as String).isNotEmpty)
            ? '${author['firstName']} ${author['lastName'] ?? ""}'.trim()
            : (author['username'] ?? 'Anonyme'))
        : 'Utilisateur';

    return PostModel(
      id: json['id'] ?? '',
      authorId: json['authorId'] ?? '',
      authorName: authorName,
      authorAvatar: author?['avatarUrl'],
      content: json['content'] ?? '',
      originalLanguage: json['originalLanguage'] ?? 'fr',
      mediaUrls: (json['mediaUrls'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      likesCount: json['likesCount'] ?? 0,
      commentsCount: json['commentsCount'] ?? 0,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }
}

