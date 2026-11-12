class PostModel {
  final String id;
  final String authorId;
  final String authorName;
  final String? authorAvatar;
  final bool authorIsOnline;
  final String content;
  final String originalLanguage;
  final List<String> mediaUrls;
  final String postType;
  final int likesCount;
  final int viewsCount;
  final int commentsCount;
  final int sharesCount;
  final DateTime createdAt;
  String? translatedContent;
  bool isTranslating;

  PostModel({
    required this.id,
    required this.authorId,
    required this.authorName,
    this.authorAvatar,
    this.authorIsOnline = true,
    required this.content,
    required this.originalLanguage,
    this.mediaUrls = const [],
    this.postType = 'text',
    this.likesCount = 0,
    this.viewsCount = 0,
    this.commentsCount = 0,
    this.sharesCount = 0,
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

    final authorIsOnline = author?['isOnline'] ?? author?['is_online'] ?? true;

    return PostModel(
      id: json['id'] ?? '',
      authorId: json['authorId'] ?? json['author_id'] ?? '',
      authorName: authorName,
      authorAvatar: author?['avatarUrl'] ?? author?['avatar_url'],
      authorIsOnline: authorIsOnline,
      content: json['content'] ?? '',
      originalLanguage: json['originalLanguage'] ?? json['original_language'] ?? 'fr',
      mediaUrls: (json['mediaUrls'] as List<dynamic>?)?.map((e) => e.toString()).toList() ??
                 (json['media_urls'] as List<dynamic>?)?.map((e) => e.toString()).toList() ??
                 [],
      postType: json['postType'] ?? json['post_type'] ?? 'text',
      likesCount: json['likesCount'] ?? json['likes_count'] ?? 0,
      viewsCount: json['viewsCount'] ?? json['views_count'] ?? 0,
      commentsCount: json['commentsCount'] ?? json['comments_count'] ?? 0,
      sharesCount: json['sharesCount'] ?? json['shares_count'] ?? 0,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : (json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now()),
    );
  }
}
