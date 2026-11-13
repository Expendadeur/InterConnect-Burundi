import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
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
  final _picker = ImagePicker();
  File? _pickedMediaFile;
  String _selectedLanguage = 'rn';
  String _selectedPostType = 'text';

  ImageProvider? _getAvatarImage(String? avatarUrl) {
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

  Future<void> _pickDeviceMedia(String type) async {
    try {
      if (type == 'photo') {
        final picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
        if (picked != null) {
          setState(() {
            _pickedMediaFile = File(picked.path);
            _selectedPostType = 'photo';
          });
        }
      } else if (type == 'camera') {
        final picked = await _picker.pickImage(source: ImageSource.camera, imageQuality: 85);
        if (picked != null) {
          setState(() {
            _pickedMediaFile = File(picked.path);
            _selectedPostType = 'photo';
          });
        }
      } else if (type == 'video') {
        final picked = await _picker.pickVideo(source: ImageSource.gallery);
        if (picked != null) {
          setState(() {
            _pickedMediaFile = File(picked.path);
            _selectedPostType = 'video';
          });
        }
      }
    } catch (_) {}
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
            left: 16,
            right: 16,
            top: 16,
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
                  hintText: 'Votre commentaire dans votre langue...',
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
    _pickedMediaFile = null;
    _selectedPostType = 'text';

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
                left: 20,
                right: 20,
                top: 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Créer une publication',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
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
                    const SizedBox(height: 12),
                    TextField(
                      controller: _postController,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        hintText: 'À quoi pensez-vous ? Exprimez-vous dans votre langue...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Prévisualisation du média choisi depuis l'appareil
                    if (_pickedMediaFile != null) ...[
                      Stack(
                        children: [
                          Container(
                            height: 160,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              color: Colors.black12,
                            ),
                            child: _selectedPostType == 'photo'
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: Image.file(_pickedMediaFile!, fit: BoxFit.cover),
                                  )
                                : const Center(
                                    child: Icon(Icons.videocam, size: 48, color: AppColors.primary),
                                  ),
                          ),
                          Positioned(
                            top: 6,
                            right: 6,
                            child: CircleAvatar(
                              radius: 14,
                              backgroundColor: Colors.black54,
                              child: IconButton(
                                padding: EdgeInsets.zero,
                                icon: const Icon(Icons.close, size: 16, color: Colors.white),
                                onPressed: () {
                                  setModalState(() {
                                    _pickedMediaFile = null;
                                    _selectedPostType = 'text';
                                  });
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Boutons d'accès direct à l'appareil local (Galerie, Caméra, Vidéo, Musique)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.photo_library, color: Colors.green),
                            tooltip: 'Galerie Photos',
                            onPressed: () async {
                              final picked = await _picker.pickImage(source: ImageSource.gallery);
                              if (picked != null) {
                                setModalState(() {
                                  _pickedMediaFile = File(picked.path);
                                  _selectedPostType = 'photo';
                                });
                              }
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.camera_alt, color: AppColors.primary),
                            tooltip: 'Prendre une Photo',
                            onPressed: () async {
                              final picked = await _picker.pickImage(source: ImageSource.camera);
                              if (picked != null) {
                                setModalState(() {
                                  _pickedMediaFile = File(picked.path);
                                  _selectedPostType = 'photo';
                                });
                              }
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.videocam, color: Colors.redAccent),
                            tooltip: 'Choisir une Vidéo',
                            onPressed: () async {
                              final picked = await _picker.pickVideo(source: ImageSource.gallery);
                              if (picked != null) {
                                setModalState(() {
                                  _pickedMediaFile = File(picked.path);
                                  _selectedPostType = 'video';
                                });
                              }
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.audiotrack, color: Colors.purple),
                            tooltip: 'Ajouter Musique',
                            onPressed: () {
                              setModalState(() {
                                _selectedPostType = 'audio';
                              });
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.send),
                      label: const Text('Publier sur InterConnect'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () async {
                        final text = _postController.text.trim();
                        if (text.isNotEmpty || _pickedMediaFile != null) {
                          Navigator.pop(context);

                          List<String> mediaUrls = [];
                          if (_pickedMediaFile != null) {
                            mediaUrls.add(_pickedMediaFile!.path);
                          } else if (_selectedPostType == 'audio') {
                            mediaUrls.add('https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3');
                          }

                          final success = await ref.read(postsProvider.notifier).createPost(
                                content: text,
                                originalLanguage: _selectedLanguage,
                                postType: _selectedPostType,
                                mediaUrls: mediaUrls,
                              );
                          _postController.clear();
                          _pickedMediaFile = null;

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
      backgroundColor: const Color(0xFFF0F2F5),
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
            icon: const Icon(Icons.people_alt_outlined, color: Colors.black87),
            tooltip: 'Communauté',
            onPressed: () => context.go('/community'),
          ),
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
            icon: const Icon(Icons.chat_bubble_outline, color: Colors.black87),
            tooltip: 'Messages & Appels',
            onPressed: () => context.go('/messages'),
          ),
          IconButton(
            icon: CircleAvatar(
              radius: 14,
              backgroundColor: AppColors.primaryLight.withOpacity(0.2),
              backgroundImage: _getAvatarImage(user?.avatarUrl),
              child: user?.avatarUrl == null
                  ? Text(
                      user?.displayName.isNotEmpty == true
                          ? user!.displayName[0].toUpperCase()
                          : 'U',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.bold),
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
            // Barre de création rapide
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
                          backgroundImage: _getAvatarImage(user?.avatarUrl),
                          child: user?.avatarUrl == null
                              ? Text(
                                  user?.displayName.isNotEmpty == true
                                      ? user!.displayName[0].toUpperCase()
                                      : 'U',
                                  style: const TextStyle(
                                      color: AppColors.primary, fontWeight: FontWeight.bold),
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
                                'À quoi pensez-vous, ${user?.firstName ?? "cher membre"} ?',
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

            // Membres en ligne (Cercle vert)
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
                      return InkWell(
                        onTap: () => context.go('/profile/${u.id}'),
                        child: Container(
                          width: 70,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          child: Column(
                            children: [
                              Stack(
                                children: [
                                  CircleAvatar(
                                    radius: 26,
                                    backgroundColor: AppColors.primary.withOpacity(0.1),
                                    backgroundImage: _getAvatarImage(u.avatarUrl),
                                    child: u.avatarUrl == null
                                        ? Text(
                                            u.displayName.isNotEmpty
                                                ? u.displayName[0].toUpperCase()
                                                : 'U',
                                            style: const TextStyle(fontWeight: FontWeight.bold),
                                          )
                                        : null,
                                  ),
                                  if (u.isOnline)
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
                        ),
                      );
                    },
                  ),
                ),
              ),

            // Fil des publications
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
                      const Text('Aucune publication pour le moment.',
                          style: TextStyle(color: Colors.grey)),
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
                      onShare: () async {
                        final success =
                            await ref.read(postsProvider.notifier).shareToMyProfile(post);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(success
                                  ? 'Publication partagée sur votre profil avec succès !'
                                  : 'Erreur lors du partage.'),
                              behavior: SnackBarBehavior.floating,
                              backgroundColor:
                                  success ? AppColors.success : AppColors.error,
                            ),
                          );
                        }
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
