import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/community_provider.dart';

class CommunityScreen extends ConsumerWidget {
  const CommunityScreen({super.key});

  String _getLanguageBadge(String lang) {
    switch (lang.toLowerCase()) {
      case 'rn':
        return 'Kirundi 🇧🇮';
      case 'fr':
        return 'Français 🇫🇷';
      case 'en':
        return 'English 🇬🇧';
      case 'sw':
        return 'Kiswahili 🇹🇿';
      default:
        return lang.toUpperCase();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(communityProvider);
    final currentUser = ref.watch(authProvider).user;
    final users = state.filteredUsers.where((u) => u.id != currentUser?.id).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Text('🌍 ', style: TextStyle(fontSize: 22)),
            Text(
              'Communauté Mondiale',
              style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(108),
          child: Column(
            children: [
              // Champ de recherche
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Rechercher un membre, pays, langue...',
                    prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: const BorderSide(color: AppColors.divider),
                    ),
                  ),
                  onChanged: (val) => ref.read(communityProvider.notifier).setSearchQuery(val),
                ),
              ),
              // Filtres par langue maternelle
              SizedBox(
                height: 44,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  children: [
                    _filterChip(ref, 'Toutes les langues', 'all', state.selectedLanguageFilter),
                    _filterChip(ref, 'Kirundi 🇧🇮', 'rn', state.selectedLanguageFilter),
                    _filterChip(ref, 'Français 🇫🇷', 'fr', state.selectedLanguageFilter),
                    _filterChip(ref, 'English 🇬🇧', 'en', state.selectedLanguageFilter),
                    _filterChip(ref, 'Swahili 🇹🇿', 'sw', state.selectedLanguageFilter),
                  ],
                ),
              ),
              const SizedBox(height: 6),
            ],
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(communityProvider.notifier).fetchUsers(),
        child: state.isLoading && users.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : users.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Text(
                        'Aucun membre trouvé pour ce filtre.\nTous les membres inscrits sont automatiquement connectés !',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: users.length,
                    itemBuilder: (context, index) {
                      final u = users[index];
                      final langLabel = _getLanguageBadge(u.preferredLanguage);

                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: const BorderSide(color: AppColors.divider),
                        ),
                        elevation: 0.5,
                        child: Padding(
                          padding: const EdgeInsets.all(14.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  // Avatar
                                  Stack(
                                    children: [
                                      CircleAvatar(
                                        radius: 26,
                                        backgroundColor: AppColors.primary.withOpacity(0.1),
                                        backgroundImage: u.avatarUrl != null && u.avatarUrl!.isNotEmpty
                                            ? NetworkImage(u.avatarUrl!)
                                            : null,
                                        child: (u.avatarUrl == null || u.avatarUrl!.isEmpty)
                                            ? Text(
                                                u.displayName.isNotEmpty
                                                    ? u.displayName[0].toUpperCase()
                                                    : 'U',
                                                style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 18,
                                                    color: AppColors.primary),
                                              )
                                            : null,
                                      ),
                                      Positioned(
                                        right: 0,
                                        bottom: 0,
                                        child: Container(
                                          width: 12,
                                          height: 12,
                                          decoration: BoxDecoration(
                                            color: AppColors.success,
                                            shape: BoxShape.circle,
                                            border: Border.all(color: Colors.white, width: 2),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(width: 12),
                                  // Nom & Langue
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          u.displayName,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold, fontSize: 16),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '@${u.username}',
                                          style: const TextStyle(
                                              color: AppColors.textSecondary, fontSize: 13),
                                        ),
                                        const SizedBox(height: 4),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: AppColors.primary.withOpacity(0.08),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            'Langue : $langLabel',
                                            style: const TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.primary),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Boutons d'action directe (sans limite d'ami)
                                  IconButton(
                                    icon: const Icon(Icons.chat_bubble_outline,
                                        color: AppColors.primary),
                                    tooltip: 'Envoyer un message',
                                    onPressed: () {
                                      // Ouvre directement la conversation
                                      context.go('/chat/conv-${u.id}');
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.call, color: AppColors.success),
                                    tooltip: 'Appel vocal direct',
                                    onPressed: () {
                                      context.go('/call/direct-${u.id}');
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.videocam, color: AppColors.primaryDark),
                                    tooltip: 'Appel vidéo direct',
                                    onPressed: () {
                                      context.go('/call/direct-${u.id}');
                                    },
                                  ),
                                ],
                              ),
                              if (u.bio != null && u.bio!.isNotEmpty) ...[
                                const SizedBox(height: 10),
                                Text(
                                  u.bio!,
                                  style: const TextStyle(
                                      fontSize: 13, color: AppColors.onSurface, height: 1.3),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }

  Widget _filterChip(WidgetRef ref, String label, String value, String currentSelected) {
    final isSelected = currentSelected == value;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: FilterChip(
        label: Text(label, style: TextStyle(fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
        selected: isSelected,
        selectedColor: AppColors.primary.withOpacity(0.18),
        checkmarkColor: AppColors.primary,
        onSelected: (_) => ref.read(communityProvider.notifier).setLanguageFilter(value),
      ),
    );
  }
}

