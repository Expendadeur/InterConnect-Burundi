import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/network/api_client.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/data/models/user_model.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  final String userId;

  const ProfileScreen({super.key, required this.userId});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  UserModel? _otherUser;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final me = ref.read(authProvider).user;
    if (widget.userId != 'me' && widget.userId != me?.id) {
      _loadOtherUser();
    }
  }

  @override
  void didUpdateWidget(covariant ProfileScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId) {
      final me = ref.read(authProvider).user;
      if (widget.userId != 'me' && widget.userId != me?.id) {
        _loadOtherUser();
      } else {
        setState(() {
          _otherUser = null;
          _isLoading = false;
          _error = null;
        });
      }
    }
  }

  Future<void> _loadOtherUser() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final apiClient = ref.read(apiClientProvider);
      final res = await apiClient.dio.get('/users/${widget.userId}');
      if (mounted) {
        setState(() {
          _otherUser = UserModel.fromJson(res.data);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Impossible de charger le profil de cet utilisateur.';
          _isLoading = false;
        });
      }
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
    final me = ref.watch(authProvider).user;
    final isOwnProfile = widget.userId == 'me' || (me != null && widget.userId == me.id);
    final user = isOwnProfile ? me : _otherUser;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Profil'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.canPop() ? context.pop() : context.go('/feed'),
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null && !isOwnProfile) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Profil'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.canPop() ? context.pop() : context.go('/feed'),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, color: AppColors.error, size: 54),
                const SizedBox(height: 12),
                Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.error)),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _loadOtherUser,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Réessayer'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Profil'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.canPop() ? context.pop() : context.go('/feed'),
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final profileImage = _getProfileImage(user.avatarUrl);
    final initials = user.displayName.isNotEmpty ? user.displayName[0].toUpperCase() : 'U';

    return Scaffold(
      appBar: AppBar(
        title: Text(isOwnProfile ? 'Mon Profil' : user.displayName),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.canPop() ? context.pop() : context.go('/feed'),
        ),
        actions: isOwnProfile
            ? [
                IconButton(
                  icon: const Icon(Icons.account_balance_wallet_outlined, color: AppColors.success),
                  tooltip: 'Portefeuille & Gains',
                  onPressed: () => context.go('/wallet'),
                ),
                IconButton(
                  icon: const Icon(Icons.settings_outlined, color: AppColors.primary),
                  tooltip: 'Paramètres',
                  onPressed: () => context.go('/settings'),
                ),
              ]
            : [],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Photo de profil
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 54,
                    backgroundColor: AppColors.primary.withOpacity(0.15),
                    backgroundImage: profileImage,
                    child: profileImage == null
                        ? Text(
                            initials,
                            style: const TextStyle(
                              fontSize: 40,
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : null,
                  ),
                  // Indicateur En ligne réel
                  if (user.isOnline)
                    Positioned(
                      bottom: 2,
                      right: 2,
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1EB53A),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              user.displayName,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            Text(
              '@${user.username}',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
            if (user.isOnline) ...[
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.circle, color: Color(0xFF1EB53A), size: 10),
                  SizedBox(width: 5),
                  Text(
                    'En ligne',
                    style: TextStyle(
                      color: Color(0xFF1EB53A),
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],

            // Actions pour profil tiers : Message et Appel direct
            if (!isOwnProfile) ...[
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => context.go('/chat/${user.id}'),
                      icon: const Icon(Icons.chat_bubble_outline, color: Colors.white),
                      label: const Text('Message'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => context.go('/call/${user.id}'),
                      icon: const Icon(Icons.call_outlined, color: AppColors.primary),
                      label: const Text('Appeler'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 24),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: AppColors.divider),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    if (isOwnProfile) ...[
                      ListTile(
                        leading: const Icon(Icons.email_outlined, color: AppColors.primary),
                        title: const Text('Email'),
                        subtitle: Text(user.email.isNotEmpty ? user.email : 'Non renseigné'),
                      ),
                      const Divider(),
                      ListTile(
                        leading: const Icon(Icons.phone_outlined, color: AppColors.primary),
                        title: const Text('Téléphone'),
                        subtitle: Text(user.phone ?? 'Non renseigné'),
                      ),
                      const Divider(),
                      ListTile(
                        leading: const Icon(Icons.badge_outlined, color: AppColors.primary),
                        title: const Text('N° Carte d’Identité (CNI)'),
                        subtitle: Text(user.nationalId ?? 'Non renseigné'),
                      ),
                      const Divider(),
                    ],
                    ListTile(
                      leading: const Icon(Icons.public, color: AppColors.success),
                      title: const Text('Pays'),
                      subtitle: Text(user.country ?? 'Burundi'),
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.info_outline, color: AppColors.primary),
                      title: const Text('Bio'),
                      subtitle: Text(user.bio ?? 'Aucune bio renseignée'),
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.language, color: AppColors.primary),
                      title: const Text('Langue préférée'),
                      subtitle: Text(user.preferredLanguage.toUpperCase()),
                    ),
                  ],
                ),
              ),
            ),

            if (isOwnProfile) ...[
              const SizedBox(height: 36),
              ElevatedButton.icon(
                onPressed: () async {
                  await ref.read(authProvider.notifier).logout();
                  if (context.mounted) {
                    context.go('/login');
                  }
                },
                icon: const Icon(Icons.logout, color: Colors.white),
                label: const Text('Se déconnecter'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
