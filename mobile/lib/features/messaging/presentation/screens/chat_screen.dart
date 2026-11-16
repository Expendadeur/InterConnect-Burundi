import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/network/api_client.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/messaging_provider.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String conversationId;

  const ChatScreen({super.key, required this.conversationId});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  UserModel? _interlocutor;

  @override
  void initState() {
    super.initState();
    ref.read(messagingProvider.notifier).loadMessages(widget.conversationId);
    _loadInterlocutor();
  }

  Future<void> _loadInterlocutor() async {
    // Si l'ID est un UUID utilisateur direct
    if (!widget.conversationId.startsWith('conv-')) {
      await _loadInterlocutorById(widget.conversationId);
    }
  }

  Future<void> _loadInterlocutorById(String userId) async {
    try {
      final apiClient = ref.read(apiClientProvider);
      final res = await apiClient.dio.get('/users/$userId');
      if (mounted) {
        setState(() {
          _interlocutor = UserModel.fromJson(res.data);
        });
      }
    } catch (_) {}
  }

  void _detectInterlocutorFromMessages(List<dynamic> messages) {
    if (_interlocutor != null || messages.isEmpty) return;
    final myId = ref.read(authProvider).user?.id;
    for (final m in messages) {
      if (m.senderId != null && m.senderId.toString().isNotEmpty && m.senderId != myId) {
        _loadInterlocutorById(m.senderId.toString());
        break;
      }
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _send() {
    final text = _messageController.text.trim();
    final userLang = ref.read(authProvider).user?.preferredLanguage ?? 'fr';
    if (text.isNotEmpty) {
      ref.read(messagingProvider.notifier).sendMessage(
            widget.conversationId,
            text,
            userLang,
          );
      _messageController.clear();
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  ImageProvider? _getProfileImage(String? avatarUrl) {
    if (avatarUrl == null || avatarUrl.isEmpty) return null;
    if (avatarUrl.startsWith('data:image')) {
      try {
        final commaIdx = avatarUrl.indexOf(',');
        final base64Str = commaIdx != -1 ? avatarUrl.substring(commaIdx + 1) : avatarUrl;
        return MemoryImage(base64Decode(base64Str));
      } catch (_) {
        return null;
      }
    }
    return NetworkImage(avatarUrl);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(messagingProvider);
    final user = ref.watch(authProvider).user;

    final displayName = _interlocutor?.displayName ??
        (widget.conversationId.startsWith('conv-') ? 'Discussion' : 'Discussion');
    final profileImage = _getProfileImage(_interlocutor?.avatarUrl);
    final initials = displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U';
    final isOnline = _interlocutor?.isOnline ?? false;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/messages'),
        ),
        title: InkWell(
          onTap: () {
            if (_interlocutor != null) {
              context.go('/profile/${_interlocutor!.id}');
            }
          },
          child: Row(
            children: [
              // Avatar avec indicateur en ligne
              Stack(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: AppColors.primary.withOpacity(0.15),
                    backgroundImage: profileImage,
                    child: profileImage == null
                        ? Text(
                            initials,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          )
                        : null,
                  ),
                  if (isOnline)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 11,
                        height: 11,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1EB53A),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 10),
              // Nom et statut en ligne
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      displayName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Row(
                      children: [
                        if (isOnline)
                          Container(
                            width: 6,
                            height: 6,
                            margin: const EdgeInsets.only(right: 4),
                            decoration: const BoxDecoration(
                              color: Color(0xFF1EB53A),
                              shape: BoxShape.circle,
                            ),
                          ),
                        Text(
                          isOnline ? 'En ligne' : 'Hors ligne',
                          style: TextStyle(
                            fontSize: 11,
                            color: isOnline ? const Color(0xFF1EB53A) : Colors.grey,
                            fontWeight: isOnline ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.call, color: AppColors.success),
            tooltip: 'Appel vocal',
            onPressed: () {
              final targetId = _interlocutor?.id ?? widget.conversationId;
              context.go('/call/$targetId', extra: _interlocutor);
            },
          ),
          IconButton(
            icon: const Icon(Icons.videocam, color: AppColors.primary),
            tooltip: 'Appel vidéo',
            onPressed: () {
              final targetId = _interlocutor?.id ?? widget.conversationId;
              context.go('/call/$targetId', extra: _interlocutor);
            },
          ),
        ],
      ),
      body: Builder(
        builder: (context) {
          _detectInterlocutorFromMessages(state.messages);
          return Column(
        children: [
          Expanded(
            child: state.isLoading && state.messages.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: state.messages.length,
                    itemBuilder: (context, index) {
                      final msg = state.messages[index];
                      final isMe = msg.senderId == user?.id;

                      return Align(
                        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          constraints: BoxConstraints(
                              maxWidth: MediaQuery.of(context).size.width * 0.75),
                          decoration: BoxDecoration(
                            color: isMe ? AppColors.primary : Colors.white,
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(16),
                              topRight: const Radius.circular(16),
                              bottomLeft: Radius.circular(isMe ? 16 : 4),
                              bottomRight: Radius.circular(isMe ? 4 : 16),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.06),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              // Texte du message dans la langue de l'utilisateur
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  msg.translatedContent ?? msg.content,
                                  style: TextStyle(
                                    color: isMe ? Colors.white : AppColors.onSurface,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              // Heure + Coche de statut (simple ✓ pour envoyé, double ✓✓ bleu pour lu)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '${msg.createdAt.hour}:${msg.createdAt.minute.toString().padLeft(2, '0')}',
                                    style: TextStyle(
                                      color: isMe ? Colors.white70 : AppColors.textSecondary,
                                      fontSize: 10,
                                    ),
                                  ),
                                  if (isMe) ...[
                                    const SizedBox(width: 4),
                                    Icon(
                                      msg.isRead ? Icons.done_all : Icons.done,
                                      size: 15,
                                      color: msg.isRead ? const Color(0xFF64B5F6) : Colors.white70,
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),

          // Zone de saisie
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      hintText: 'Écrire un message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                    ),
                    onSubmitted: (_) => _send(),
                  ),
                ),
                const SizedBox(width: 8),
                FloatingActionButton.small(
                  onPressed: _send,
                  backgroundColor: AppColors.primary,
                  child: const Icon(Icons.send, color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      );
    }),
    );
  }
}
