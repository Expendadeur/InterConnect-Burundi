import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/message_model.dart';

class MessagingState {
  final List<MessageModel> messages;
  final bool isLoading;

  const MessagingState({required this.messages, this.isLoading = false});
}

class MessagingNotifier extends StateNotifier<MessagingState> {
  final ApiClient _apiClient;
  final String _userLanguage;

  MessagingNotifier(this._apiClient, this._userLanguage)
      : super(const MessagingState(messages: []));

  Future<void> loadMessages(String conversationId) async {
    state = MessagingState(messages: state.messages, isLoading: true);
    try {
      final res = await _apiClient.dio
          .get('/messaging/conversations/$conversationId/messages');
      final list = (res.data as List<dynamic>?)
              ?.map((item) => MessageModel.fromJson(item))
              .toList() ??
          [];
      state = MessagingState(messages: list, isLoading: false);

      // Traduction automatique INVISIBLE de tous les messages reçus
      _autoTranslateAll(list);
    } catch (_) {
      state = MessagingState(messages: state.messages, isLoading: false);
    }
  }

  /// Traduit tous les messages entrants qui sont dans une autre langue — aucun clic requis.
  Future<void> _autoTranslateAll(List<MessageModel> messages) async {
    for (final msg in messages) {
      if (msg.originalLanguage != _userLanguage && msg.translatedContent == null) {
        _translateMessageInBackground(msg);
      }
    }
  }

  Future<void> _translateMessageInBackground(MessageModel msg) async {
    try {
      final res = await _apiClient.dio.post('/translation/translate', data: {
        'text': msg.content,
        'source_language': msg.originalLanguage,
        'target_language': _userLanguage,
      });
      msg.translatedContent = res.data['translated_text'] ?? res.data['translatedText'];
      state = MessagingState(messages: [...state.messages], isLoading: false);
    } catch (_) {}
  }

  Future<void> sendMessage(
      String conversationId, String content, String language) async {
    try {
      final res = await _apiClient.dio.post('/messaging/messages', data: {
        'conversationId': conversationId,
        'content': content,
        'originalLanguage': language,
      });
      final msg = MessageModel.fromJson(res.data);
      state = MessagingState(
          messages: [...state.messages, msg], isLoading: false);
    } catch (_) {}
  }

  Future<void> openOrCreateConversation(String otherUserId) async {
    try {
      await _apiClient.dio.post('/messaging/conversations', data: {
        'participantId': otherUserId,
      });
    } catch (_) {}
  }
}

final messagingProvider =
    StateNotifierProvider<MessagingNotifier, MessagingState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final user = ref.watch(authProvider).user;
  final userLang = user?.preferredLanguage ?? 'fr';
  return MessagingNotifier(apiClient, userLang);
});
