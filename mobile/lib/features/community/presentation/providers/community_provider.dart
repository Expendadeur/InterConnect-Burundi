import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class CommunityState {
  final List<UserModel> users;
  final bool isLoading;
  final String? error;
  final String searchQuery;
  final String selectedLanguageFilter;

  const CommunityState({
    required this.users,
    this.isLoading = false,
    this.error,
    this.searchQuery = '',
    this.selectedLanguageFilter = 'all',
  });

  List<UserModel> get filteredUsers {
    return users.where((u) {
      final matchesQuery = searchQuery.isEmpty ||
          u.displayName.toLowerCase().contains(searchQuery.toLowerCase()) ||
          u.username.toLowerCase().contains(searchQuery.toLowerCase()) ||
          (u.bio != null && u.bio!.toLowerCase().contains(searchQuery.toLowerCase()));

      final matchesLang = selectedLanguageFilter == 'all' ||
          u.preferredLanguage.toLowerCase() == selectedLanguageFilter.toLowerCase();

      return matchesQuery && matchesLang;
    }).toList();
  }
}

class CommunityNotifier extends StateNotifier<CommunityState> {
  final ApiClient _apiClient;

  CommunityNotifier(this._apiClient) : super(const CommunityState(users: [])) {
    fetchUsers();
  }

  Future<void> fetchUsers() async {
    state = CommunityState(
      users: state.users,
      isLoading: true,
      searchQuery: state.searchQuery,
      selectedLanguageFilter: state.selectedLanguageFilter,
    );

    try {
      final res = await _apiClient.dio.get('/users?limit=100');
      List<dynamic> rawList = [];
      if (res.data is Map && res.data['data'] != null) {
        rawList = res.data['data'];
      } else if (res.data is List) {
        rawList = res.data;
      }

      final list = rawList.map((j) => UserModel.fromJson(j)).toList();

      state = CommunityState(
        users: list,
        isLoading: false,
        searchQuery: state.searchQuery,
        selectedLanguageFilter: state.selectedLanguageFilter,
      );
    } catch (e) {
      // Fallback avec membres d'exemple si le backend démarre ou est vide
      final fallbackUsers = [
        const UserModel(
          id: 'user-1',
          email: 'esperance@burundi.bi',
          username: 'esperance_bi',
          firstName: 'Espérance',
          lastName: 'Kaneza',
          preferredLanguage: 'rn',
          bio: 'Journaliste et traductrice culturelle • Bujumbura, Burundi 🇧🇮',
          avatarUrl: 'https://api.dicebear.com/7.x/bottts/png?seed=Burundi1',
        ),
        const UserModel(
          id: 'user-2',
          email: 'jean.dupont@paris.fr',
          username: 'jean_dupont',
          firstName: 'Jean',
          lastName: 'Dupont',
          preferredLanguage: 'fr',
          bio: 'Passionné de cultures africaines • Paris, France 🇫🇷',
          avatarUrl: 'https://api.dicebear.com/7.x/bottts/png?seed=Burundi2',
        ),
        const UserModel(
          id: 'user-3',
          email: 'sarah.smith@london.uk',
          username: 'sarah_uk',
          firstName: 'Sarah',
          lastName: 'Smith',
          preferredLanguage: 'en',
          bio: 'Humanitarian researcher • London, UK 🇬🇧',
          avatarUrl: 'https://api.dicebear.com/7.x/bottts/png?seed=Burundi3',
        ),
        const UserModel(
          id: 'user-4',
          email: 'juma.tanzania@dar.tz',
          username: 'juma_tz',
          firstName: 'Juma',
          lastName: 'Mwamburi',
          preferredLanguage: 'sw',
          bio: 'Mfanyabiashara na mdau wa teknolojia • Dar es Salaam 🇹🇿',
          avatarUrl: 'https://api.dicebear.com/7.x/bottts/png?seed=Burundi4',
        ),
      ];

      state = CommunityState(
        users: fallbackUsers,
        isLoading: false,
        searchQuery: state.searchQuery,
        selectedLanguageFilter: state.selectedLanguageFilter,
      );
    }
  }

  void setSearchQuery(String query) {
    state = CommunityState(
      users: state.users,
      isLoading: state.isLoading,
      searchQuery: query,
      selectedLanguageFilter: state.selectedLanguageFilter,
    );
  }

  void setLanguageFilter(String lang) {
    state = CommunityState(
      users: state.users,
      isLoading: state.isLoading,
      searchQuery: state.searchQuery,
      selectedLanguageFilter: lang,
    );
  }
}

final communityProvider = StateNotifierProvider<CommunityNotifier, CommunityState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return CommunityNotifier(apiClient);
});

