import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../community/presentation/providers/community_provider.dart';
import '../providers/posts_provider.dart';
import '../widgets/post_card.dart';

class FeedScreen extends ConsumerStatefulWidget {
  const FeedScreen({super.key});

  @override
  ConsumerState<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends ConsumerState<FeedScreen> {
  final _postController = TextEditingController();
  final _mediaUrlController = TextEditingController();
  String _selectedLanguage = 'rn';
  String _selectedPostType = 'text';

  @override
  void initState() {
    super.initState();
    final user = ref.read(authProvider).user;
    _selectedLanguage = user?.preferredLanguage ?? 'rn';
  }

  @override
  void dispose() {
    _postController.dispose();
    _mediaUrlController.dispose();
    super.dispose();
  }

  void _showCommentDialog(String postId) {
    final commentController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
            left: 16, right: 16, top: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Ajouter un commentaire',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: commentController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Votre commentaire...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.send, color: AppColors.primary),
                    onPressed: () async {
                      final text = commentController.text.trim();
                      if (text.isNotEmpty) {
                        Navigator.pop(ctx);
                        await ref.read(postsProvider.notifier).addComment(postId, text);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Commentaire publié avec succès !'),
                              backgroundColor: AppColors.success,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
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
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Créer une publication',
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
                    const SizedBox(height: 10),

                    // Sélecteur de type de publication multimédia
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        ChoiceChip(
                          label: const Row(
                            children: [
                              Icon(Icons.text_fields, size: 16),
                              SizedBox(width: 4),
                              Text('Texte'),
                            ],
                          ),
                          selected: _selectedPostType == 'text',
                          onSelected: (val) => setModalState(() => _selectedPostType = 'text'),
                        ),
                        ChoiceChip(
                          label: const Row(
                            children: [
                              Icon(Icons.photo, size: 16),
                              SizedBox(width: 4),
                              Text('Photo'),
                            ],
                          ),
                          selected: _selectedPostType == 'photo',
                          onSelected: (val) => setModalState(() => _selectedPostType = 'photo'),
                        ),
                        ChoiceChip(
                          label: const Row(
                            children: [
                              Icon(Icons.videocam, size: 16),
                              SizedBox(width: 4),
                              Text('Vidéo'),
                            ],
                          ),
                          selected: _selectedPostType == 'video',
                          onSelected: (val) => setModalState(() => _selectedPostType = 'video'),
                        ),
                        ChoiceChip(
                          label: const Row(
                            children: [
                              Icon(Icons.audiotrack, size: 16),
                              SizedBox(width: 4),
                              Text('Musique'),
                            ],
                          ),
                          selected: _selectedPostType == 'audio',
                          onSelected: (val) => setModalState(() => _selectedPostType = 'audio'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    TextField(
                      controller: _postController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        hintText: 'Que voulez-vous partager avec le Burundi et le monde ?',
                        border: OutlineInputBorder(),
                      ),
                    ),

                    if (_selectedPostType != 'text') ...[
                      const SizedBox(height: 10),
                      TextField(
                        controller: _mediaUrlController,
                        decoration: InputDecoration(
                          hintText: _selectedPostType == 'photo'
                              ? 'URL ou lien de la photo'
                              : _selectedPostType == 'video'
                                  ? 'URL ou lien de la vidéo'
                                  : 'URL ou lien de la piste audio',
                          prefixIcon: const Icon(Icons.link),
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ],

                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.send),
                      label: const Text('Publier maintenant'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () async {
                        final text = _postController.text.trim();
                        final mediaUrl = _mediaUrlController.text.trim();
                        if (text.isNotEmpty || mediaUrl.isNotEmpty) {
                          Navigator.pop(context);
                          final success = await ref.read(postsProvider.notifier).createPost(
                                content: text,
                                originalLanguage: _selectedLanguage,
                                postType: _selectedPostType,
                                mediaUrls: mediaUrl.isNotEmpty ? [mediaUrl] : [],
                              );
                          _postController.clear();
                          _mediaUrlController.clear();
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(success
                                    ? 'Publication partagée avec succès !'
                                    : 'Erreur lors de la publication.'),
                                backgroundColor:
                                    success ? AppColors.success : AppColors.error,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        }
                      },
                    ),
                  ],
                ),
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
    final communityState = ref.watch(communityProvider);
    final user = ref.watch(authProvider).user;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5), // Fond Facebook moderne
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        automaticallyImplyLeading: false,
        title: const Row(
          children: [
            Text('🇧🇮 ', style: TextStyle(fontSize: 22)),
            Text(
              'InterConnect',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: AppColors.primary,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.storefront_outlined, color: Colors.black87),
            tooltip: 'Marché',
            onPressed: () => context.go('/marketplace'),
          ),
          IconButton(
            icon: const Icon(Icons.account_balance_wallet_outlined, color: Colors.black87),
            tooltip: 'Portefeuille ICB',
            onPressed: () => context.go('/wallet'),
          ),
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Colors.black87),
            tooltip: 'Notifications',
            onPressed: () => context.go('/notifications'),
          ),
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline, color: Colors.black87),
            tooltip: 'Messages',
            onPressed: () => context.go('/messages'),
          ),
          IconButton(
            icon: CircleAvatar(
              radius: 14,
              backgroundColor: AppColors.primaryLight.withOpacity(0.2),
              backgroundImage: user?.avatarUrl != null
                  ? NetworkImage(user!.avatarUrl!)
                  : null,
              child: user?.avatarUrl == null
                  ? Text(
                      user?.displayName.isNotEmpty == true
                          ? user!.displayName[0].toUpperCase()
                          : 'U',
                      style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.bold),
                    )
                  : null,
            ),
            onPressed: () => context.go('/profile/${user?.id ?? "me"}'),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(postsProvider.notifier).fetchPosts();
          await ref.read(communityProvider.notifier).fetchUsers();
        },
        child: CustomScrollView(
          slivers: [
            // ─── BANDEAU DE CRÉATION DE POST EN TÊTE (FACEBOOK STYLE) ───
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: AppColors.primaryLight.withOpacity(0.2),
                          backgroundImage: user?.avatarUrl != null
                              ? NetworkImage(user!.avatarUrl!)
                              : null,
                          child: user?.avatarUrl == null
                              ? Text(
                                  user?.displayName.isNotEmpty == true
                                      ? user!.displayName[0].toUpperCase()
                                      : 'U',
                                  style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                                )
                              : null,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: InkWell(
                            onTap: _showCreatePostDialog,
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'À quoi pensez-vous, ${user?.firstName ?? "cher ami"} ?',
                                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        InkWell(
                          onTap: _showCreatePostDialog,
                          child: const Row(
                            children: [
                              Icon(Icons.photo_library, color: Colors.green, size: 20),
                              SizedBox(width: 6),
                              Text('Photo', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                            ],
                          ),
                        ),
                        InkWell(
                          onTap: _showCreatePostDialog,
                          child: const Row(
                            children: [
                              Icon(Icons.videocam, color: Colors.redAccent, size: 20),
                              SizedBox(width: 6),
                              Text('Vidéo', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                            ],
                          ),
                        ),
                        InkWell(
                          onTap: _showCreatePostDialog,
                          child: const Row(
                            children: [
                              Icon(Icons.audiotrack, color: Colors.purple, size: 20),
                              SizedBox(width: 6),
                              Text('Musique', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // ─── STORIES / UTILISATEURS ACTIFS EN LIGNE (CERCLE VERT) ───
            if (communityState.users.isNotEmpty)
              SliverToBoxAdapter(
                child: Container(
                  height: 96,
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    itemCount: communityState.users.length,
                    itemBuilder: (context, index) {
                      final u = communityState.users[index];
                      return Container(
                        width: 70,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        child: Column(
                          children: [
                            Stack(
                              children: [
                                CircleAvatar(
                                  radius: 26,
                                  backgroundColor: AppColors.primary.withOpacity(0.1),
                                  backgroundImage: u.avatarUrl != null
                                      ? NetworkImage(u.avatarUrl!)
                                      : null,
                                  child: u.avatarUrl == null
                                      ? Text(
                                          u.displayName.isNotEmpty
                                              ? u.displayName[0].toUpperCase()
                                              : 'U',
                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                        )
                                      : null,
                                ),
                                // Indicateur EN LIGNE (Cercle vert)
                                Positioned(
                                  right: 0,
                                  bottom: 0,
                                  child: Container(
                                    width: 14,
                                    height: 14,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF1EB53A),
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: 2),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              u.displayName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),

            // ─── LISTE DES PUBLICATIONS MULTIMÉDIAS DU FIL ───
            if (postsState.isLoading && postsState.posts.isEmpty)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (postsState.posts.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.article_outlined, size: 60, color: Colors.grey),
                      const SizedBox(height: 12),
                      const Text('Aucune publication pour le moment.', style: TextStyle(color: Colors.grey)),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: _showCreatePostDialog,
                        child: const Text('Créer la première publication'),
                      ),
                    ],
                  ),
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final post = postsState.posts[index];
                    return PostCard(
                      post: post,
                      onLike: () => ref.read(postsProvider.notifier).likePost(post.id),
                      onComment: () => _showCommentDialog(post.id),
                      onShare: () {
                        ref.read(postsProvider.notifier).recordShare(post.id);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Publication partagée sur votre profil !'),
                            behavior: SnackBarBehavior.floating,
                            backgroundColor: AppColors.success,
                          ),
                        );
                      },
                    );
                  },
                  childCount: postsState.posts.length,
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreatePostDialog,
        backgroundColor: AppColors.primary,
        tooltip: 'Nouvelle publication',
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
    );
  }
}
