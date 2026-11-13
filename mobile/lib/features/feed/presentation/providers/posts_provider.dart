import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/post_model.dart';

class PostsState {
  final List<PostModel> posts;
  final bool isLoading;
  final String? error;

  const PostsState({
    required this.posts,
    required this.isLoading,
    this.error,
  });

  factory PostsState.initial() => const PostsState(posts: [], isLoading: false);
}

class PostsNotifier extends StateNotifier<PostsState> {
  final ApiClient _apiClient;
  final String _userLanguage;

  PostsNotifier(this._apiClient, this._userLanguage) : super(PostsState.initial()) {
    fetchPosts();
  }

  Future<void> fetchPosts() async {
    state = PostsState(posts: state.posts, isLoading: true);
    try {
      // Envoie la langue de l'utilisateur pour recevoir directement les contenus traduits par le serveur
      final res = await _apiClient.dio.get('/posts?limit=50&lang=$_userLanguage');
      List<dynamic> rawList = [];
      if (res.data is Map && res.data['data'] != null) {
        rawList = res.data['data'];
      } else if (res.data is List) {
        rawList = res.data;
      }

      final list = rawList.map((item) => PostModel.fromJson(item)).toList();
      state = PostsState(posts: list, isLoading: false);

      // Sécurité client : traduction en arrière-plan immédiate si non déjà traduite
      _autoTranslateAll(list);
    } catch (e) {
      state = PostsState(posts: state.posts, isLoading: false, error: 'Impossible de charger les posts');
    }
  }

  Future<void> _autoTranslateAll(List<PostModel> posts) async {
    for (final post in posts) {
      if (post.translatedContent == null || post.translatedContent == post.content) {
        if (post.originalLanguage.toLowerCase() != _userLanguage.toLowerCase()) {
          _translateInBackground(post);
        }
      }
    }
  }

  Future<void> _translateInBackground(PostModel post) async {
    try {
      final res = await _apiClient.dio.post('/translation/translate', data: {
        'text': post.content,
        'source_language': post.originalLanguage,
        'target_language': _userLanguage,
      });

      final translated = res.data['translatedText'] ?? res.data['translated_text'];
      if (translated != null && translated.toString().isNotEmpty) {
        post.translatedContent = translated.toString();
        state = PostsState(posts: [...state.posts], isLoading: false);
      }
    } catch (_) {}
  }

  Future<bool> createPost({
    required String content,
    required String originalLanguage,
    String postType = 'text',
    List<String> mediaUrls = const [],
  }) async {
    try {
      await _apiClient.dio.post('/posts', data: {
        'content': content,
        'originalLanguage': originalLanguage,
        'postType': postType,
        'mediaUrls': mediaUrls,
      });
      await fetchPosts();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> shareToMyProfile(PostModel originalPost) async {
    try {
      final shareContent = 'Partagé : ${originalPost.content}';
      await _apiClient.dio.post('/posts', data: {
        'content': shareContent,
        'originalLanguage': originalPost.originalLanguage,
        'postType': originalPost.postType,
        'mediaUrls': originalPost.mediaUrls,
      });
      await fetchPosts();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> likePost(String postId) async {
    try {
      await _apiClient.dio.post('/posts/$postId/like');
      final updated = state.posts.map((p) {
        if (p.id == postId) {
          return PostModel(
            id: p.id,
            authorId: p.authorId,
            authorName: p.authorName,
            authorAvatar: p.authorAvatar,
            authorIsOnline: p.authorIsOnline,
            content: p.content,
            originalLanguage: p.originalLanguage,
            mediaUrls: p.mediaUrls,
            postType: p.postType,
            likesCount: p.likesCount + 1,
            viewsCount: p.viewsCount,
            commentsCount: p.commentsCount,
            sharesCount: p.sharesCount,
            createdAt: p.createdAt,
            translatedContent: p.translatedContent,
          );
        }
        return p;
      }).toList();
      state = PostsState(posts: updated, isLoading: false);
    } catch (_) {}
  }

  Future<void> addComment(String postId, String commentText) async {
    try {
      await _apiClient.dio.post('/comments/post/$postId', data: {
        'content': commentText,
        'originalLanguage': _userLanguage,
      });
      final updated = state.posts.map((p) {
        if (p.id == postId) {
          return PostModel(
            id: p.id,
            authorId: p.authorId,
            authorName: p.authorName,
            authorAvatar: p.authorAvatar,
            authorIsOnline: p.authorIsOnline,
            content: p.content,
            originalLanguage: p.originalLanguage,
            mediaUrls: p.mediaUrls,
            postType: p.postType,
            likesCount: p.likesCount,
            viewsCount: p.viewsCount,
            commentsCount: p.commentsCount + 1,
            sharesCount: p.sharesCount,
            createdAt: p.createdAt,
            translatedContent: p.translatedContent,
          );
        }
        return p;
      }).toList();
      state = PostsState(posts: updated, isLoading: false);
    } catch (_) {}
  }
}

final postsProvider = StateNotifierProvider<PostsNotifier, PostsState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final user = ref.watch(authProvider).user;
  final userLang = user?.preferredLanguage ?? 'fr';
  return PostsNotifier(apiClient, userLang);
});
