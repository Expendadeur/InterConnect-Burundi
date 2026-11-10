import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/posts_provider.dart';
import '../widgets/post_card.dart';

class FeedScreen extends ConsumerStatefulWidget {
  const FeedScreen({super.key});

  @override
  ConsumerState<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends ConsumerState<FeedScreen> {
  final _postController = TextEditingController();
  String _selectedLanguage = 'rn';

  @override
  void initState() {
    super.initState();
    final user = ref.read(authProvider).user;
    _selectedLanguage = user?.preferredLanguage ?? 'rn';
  }

  @override
  void dispose() {
    _postController.dispose();
    super.dispose();
  }

  void _showCreatePostDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                left: 20, right: 20, top: 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Nouvelle publication',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      DropdownButton<String>(
                        value: _selectedLanguage,
                        items: const [
                          DropdownMenuItem(value: 'rn', child: Text('Kirundi 🇧🇮')),
                          DropdownMenuItem(value: 'fr', child: Text('Français 🇫🇷')),
                          DropdownMenuItem(value: 'en', child: Text('English 🇬🇧')),
                          DropdownMenuItem(value: 'sw', child: Text('Swahili 🇹🇿')),
                        ],
                        onChanged: (val) {
                          if (val != null) setModalState(() => _selectedLanguage = val);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.auto_awesome, size: 14, color: AppColors.primary),
                        SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Votre publication sera automatiquement traduite dans la langue de chaque lecteur.',
                            style: TextStyle(fontSize: 12, color: AppColors.primary),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _postController,
                    maxLines: 4,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: 'Que voulez-vous partager ?',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.send),
                    label: const Text('Publier'),
                    onPressed: () async {
                      final text = _postController.text.trim();
                      if (text.isNotEmpty) {
                        Navigator.pop(context);
                        await ref
                            .read(postsProvider.notifier)
                            .createPost(text, _selectedLanguage);
                        _postController.clear();
                      }
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final postsState = ref.watch(postsProvider);
    final user = ref.watch(authProvider).user;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Row(
          children: [
            Text('🇧🇮 ', style: TextStyle(fontSize: 20)),
            Text(
              'InterConnect',
              style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.people_alt_outlined, color: AppColors.primary),
            tooltip: 'Communauté mondiale',
            onPressed: () => context.go('/community'),
          ),
          IconButton(
            icon: const Icon(Icons.chat_outlined, color: AppColors.primary),
            onPressed: () => context.go('/messages'),
          ),
          IconButton(
            icon: CircleAvatar(
              radius: 14,
              backgroundColor: AppColors.primary.withOpacity(0.12),
              backgroundImage: user?.avatarUrl != null
                  ? NetworkImage(user!.avatarUrl!)
                  : null,
              child: user?.avatarUrl == null
                  ? Text(
                      user?.displayName.isNotEmpty == true
                          ? user!.displayName[0].toUpperCase()
                          : 'U',
                      style: const TextStyle(fontSize: 12, color: AppColors.primary),
                    )
                  : null,
            ),
            onPressed: () => context.go('/profile/${user?.id ?? "me"}'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(postsProvider.notifier).fetchPosts(),
        child: postsState.isLoading && postsState.posts.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : postsState.posts.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.article_outlined,
                            size: 60, color: AppColors.textSecondary),
                        const SizedBox(height: 12),
                        const Text('Aucune publication pour l\'instant.',
                            style: TextStyle(color: AppColors.textSecondary)),
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.edit),
                          label: const Text('Créer la première publication'),
                          onPressed: _showCreatePostDialog,
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: postsState.posts.length,
                    itemBuilder: (context, index) {
                      final post = postsState.posts[index];
                      return PostCard(
                        post: post,
                        onLike: () => ref.read(postsProvider.notifier).likePost(post.id),
                        onComment: () {},
                      );
                    },
                  ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreatePostDialog,
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.edit, color: Colors.white),
        label: const Text('Publier', style: TextStyle(color: Colors.white)),
      ),
    );
  }
}
