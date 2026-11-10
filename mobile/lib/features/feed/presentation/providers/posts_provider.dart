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
      final res = await _apiClient.dio.get('/posts');
      final list = (res.data['data'] as List<dynamic>?)
              ?.map((item) => PostModel.fromJson(item))
              .toList() ??
          [];
      state = PostsState(posts: list, isLoading: false);

      // Traduction automatique INVISIBLE : chaque post dans une autre langue est traduit immédiatement
      _autoTranslateAll(list);
    } catch (e) {
      state = PostsState(posts: state.posts, isLoading: false, error: 'Impossible de charger les posts');
    }
  }

  /// Traduit en arrière-plan tous les posts qui ne sont pas dans la langue de l'utilisateur.
  /// Pas de clic nécessaire — la traduction apparaît dès que l'IA répond.
  Future<void> _autoTranslateAll(List<PostModel> posts) async {
    for (final post in posts) {
      // On ne traduit que si la langue source est différente de la langue cible
      if (post.originalLanguage != _userLanguage && post.translatedContent == null) {
        _translateInBackground(post);
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
      post.translatedContent = res.data['translated_text'] ?? res.data['translatedText'];
      // Notifie l'UI que le texte traduit est disponible
      state = PostsState(posts: [...state.posts], isLoading: false);
    } catch (_) {
      // Silencieux — si la traduction échoue, on affiche le texte original
    }
  }

  Future<void> createPost(String content, String originalLanguage) async {
    try {
      await _apiClient.dio.post('/posts', data: {
        'content': content,
        'originalLanguage': originalLanguage,
      });
      await fetchPosts();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> likePost(String postId) async {
    try {
      await _apiClient.dio.post('/posts/$postId/like');
      final updated = state.posts.map((p) {
        if (p.id == postId) {
          return PostModel(
            id: p.id, authorId: p.authorId, authorName: p.authorName,
            authorAvatar: p.authorAvatar, content: p.content,
            originalLanguage: p.originalLanguage, mediaUrls: p.mediaUrls,
            likesCount: p.likesCount + 1, commentsCount: p.commentsCount,
            createdAt: p.createdAt, translatedContent: p.translatedContent,
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
