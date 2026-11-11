import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/network/api_client.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class ConversationItem {
  final String id;
  final String name;
  final String? avatarUrl;
  final String lastMessage;
  final String lastMessageLang;
  final String? lastMessageTranslated;
  final String time;
  final bool isGroup;

  const ConversationItem({
    required this.id,
    required this.name,
    this.avatarUrl,
    required this.lastMessage,
    required this.lastMessageLang,
    this.lastMessageTranslated,
    required this.time,
    this.isGroup = false,
  });
}

final conversationsProvider = FutureProvider<List<ConversationItem>>((ref) async {
  final apiClient = ref.watch(apiClientProvider);
  final userLang = ref.watch(authProvider).user?.preferredLanguage ?? 'fr';
  try {
    final res = await apiClient.dio.get('/messaging/conversations');
    final raw = res.data as List<dynamic>? ?? [];
    final items = raw.map((j) {
      final lastMsg = j['lastMessage'];
      return ConversationItem(
        id: j['id'] ?? '',
        name: j['name'] ?? 'Conversation',
        avatarUrl: j['avatarUrl'],
        lastMessage: lastMsg?['content'] ?? '',
        lastMessageLang: lastMsg?['originalLanguage'] ?? 'fr',
        time: j['updatedAt'] != null
            ? _formatTime(DateTime.parse(j['updatedAt']))
            : '',
        isGroup: j['isGroup'] ?? false,
      );
    }).toList();
    return items;
  } catch (_) {
    return const [];
  }
});

String _formatTime(DateTime dt) {
  final now = DateTime.now();
  if (dt.day == now.day) {
    return '${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  }
  return 'Hier';
}

class ConversationsScreen extends ConsumerWidget {
  const ConversationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final convAsync = ref.watch(conversationsProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/feed'),
        ),
        title: const Text('Messages', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.people_alt_outlined, color: AppColors.primary),
            tooltip: 'Trouver un contact',
            onPressed: () => context.go('/community'),
          ),
        ],
      ),
      body: convAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Impossible de charger les conversations')),
        data: (convs) => convs.isEmpty
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.chat_bubble_outline, size: 60, color: AppColors.textSecondary),
                    const SizedBox(height: 12),
                    const Text('Aucune conversation pour l\'instant.',
                        style: TextStyle(color: AppColors.textSecondary)),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.people_alt),
                      label: const Text('Trouver des membres'),
                      onPressed: () => context.go('/community'),
                    ),
                  ],
                ),
              )
            : ListView.separated(
                itemCount: convs.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final conv = convs[index];
                  return ListTile(
                    leading: Stack(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: conv.isGroup ? AppColors.success : AppColors.primary,
                          backgroundImage: conv.avatarUrl != null
                              ? NetworkImage(conv.avatarUrl!)
                              : null,
                          child: conv.avatarUrl == null
                              ? Icon(
                                  conv.isGroup ? Icons.group : Icons.person,
                                  color: Colors.white,
                                )
                              : null,
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: AppColors.success,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 1.5),
                            ),
                          ),
                        ),
                      ],
                    ),
                    title: Text(conv.name,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Row(
                      children: [
                        if (conv.lastMessageLang != (ref.read(authProvider).user?.preferredLanguage ?? 'fr'))
                          const Icon(Icons.auto_awesome, size: 10, color: AppColors.primary),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            conv.lastMessage,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                    trailing: Text(conv.time,
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 12)),
                    onTap: () => context.go('/chat/${conv.id}'),
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/community'),
        backgroundColor: AppColors.primary,
        tooltip: 'Nouveau message',
        child: const Icon(Icons.edit, color: Colors.white),
      ),
    );
  }
}
