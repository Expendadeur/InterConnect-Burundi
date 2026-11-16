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
  final String? currentUserId;

  const CommunityState({
    required this.users,
    this.isLoading = false,
    this.error,
    this.searchQuery = '',
    this.selectedLanguageFilter = 'all',
    this.currentUserId,
  });

  List<UserModel> get filteredUsers {
    return users.where((u) {
      // Exclure l'utilisateur connecté
      if (currentUserId != null && u.id == currentUserId) return false;

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
  final String? _currentUserId;

  CommunityNotifier(this._apiClient, this._currentUserId)
      : super(CommunityState(users: const [], currentUserId: _currentUserId)) {
    fetchUsers();
  }

  Future<void> fetchUsers() async {
    state = CommunityState(
      users: state.users,
      isLoading: true,
      searchQuery: state.searchQuery,
      selectedLanguageFilter: state.selectedLanguageFilter,
      currentUserId: _currentUserId,
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
        currentUserId: _currentUserId,
      );
    } catch (e) {
      state = CommunityState(
        users: state.users,
        isLoading: false,
        error: 'Impossible de charger la communauté.',
        searchQuery: state.searchQuery,
        selectedLanguageFilter: state.selectedLanguageFilter,
        currentUserId: _currentUserId,
      );
    }
  }

  void setSearchQuery(String query) {
    state = CommunityState(
      users: state.users,
      isLoading: state.isLoading,
      searchQuery: query,
      selectedLanguageFilter: state.selectedLanguageFilter,
      currentUserId: _currentUserId,
    );
  }

  void setLanguageFilter(String lang) {
    state = CommunityState(
      users: state.users,
      isLoading: state.isLoading,
      searchQuery: state.searchQuery,
      selectedLanguageFilter: lang,
      currentUserId: _currentUserId,
    );
  }
}

final communityProvider = StateNotifierProvider<CommunityNotifier, CommunityState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final user = ref.watch(authProvider).user;
  return CommunityNotifier(apiClient, user?.id);
});
