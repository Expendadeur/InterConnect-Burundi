import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/product_model.dart';

class MarketplaceState {
  final List<ProductModel> products;
  final bool isLoading;
  final String? error;
  final String searchQuery;
  final String selectedCategory;

  const MarketplaceState({
    required this.products,
    this.isLoading = false,
    this.error,
    this.searchQuery = '',
    this.selectedCategory = 'Toutes',
  });

  List<ProductModel> get filteredProducts {
    return products.where((p) {
      final matchesCat = selectedCategory == 'Toutes' || p.category == selectedCategory;
      final q = searchQuery.toLowerCase();
      final title = (p.translatedTitle ?? p.title).toLowerCase();
      final desc = (p.translatedDescription ?? p.description).toLowerCase();
      final matchesSearch = q.isEmpty || title.contains(q) || desc.contains(q) || p.location.toLowerCase().contains(q);
      return matchesCat && matchesSearch;
    }).toList();
  }
}

class MarketplaceNotifier extends StateNotifier<MarketplaceState> {
  final ApiClient _apiClient;
  final Ref _ref;

  MarketplaceNotifier(this._apiClient, this._ref)
      : super(const MarketplaceState(products: [])) {
    loadProducts();
  }

  Future<void> loadProducts() async {
    state = MarketplaceState(
      products: state.products,
      isLoading: true,
      searchQuery: state.searchQuery,
      selectedCategory: state.selectedCategory,
    );

    try {
      final res = await _apiClient.dio.get('/posts?limit=50');
      List<dynamic> raw = [];
      if (res.data is Map && res.data['data'] != null) {
        raw = res.data['data'];
      } else if (res.data is List) {
        raw = res.data;
      }

      final List<ProductModel> items = [];
      for (var j in raw) {
        final content = j['content']?.toString() ?? '';
        if (content.contains('[PRODUIT]')) {
          try {
            final lines = content.replaceFirst('[PRODUIT]', '').trim().split('||');
            if (lines.length >= 4) {
              final author = j['author'] ?? {};
              items.add(ProductModel(
                id: j['id'] ?? '',
                sellerId: author['id'] ?? '',
                sellerName: (author['firstName'] != null)
                    ? '${author['firstName']} ${author['lastName'] ?? ""}'.trim()
                    : author['username'] ?? 'Commerçant',
                sellerAvatar: author['avatarUrl'],
                sellerPhone: author['phone'] ?? '+257',
                title: lines[0].trim(),
                price: double.tryParse(lines[1].trim()) ?? 0.0,
                currency: 'BIF',
                category: lines[2].trim(),
                location: lines[3].trim(),
                description: lines.length > 4 ? lines[4].trim() : lines[0].trim(),
                originalLanguage: j['originalLanguage'] ?? 'rn',
                imageUrl: j['mediaUrls'] != null && (j['mediaUrls'] as List).isNotEmpty
                    ? (j['mediaUrls'] as List)[0]
                    : null,
                createdAt: DateTime.tryParse(j['createdAt'] ?? '') ?? DateTime.now(),
              ));
            }
          } catch (_) {}
        }
      }

      state = MarketplaceState(
        products: items,
        isLoading: false,
        searchQuery: state.searchQuery,
        selectedCategory: state.selectedCategory,
      );

      _autoTranslateProducts();
    } catch (e) {
      state = MarketplaceState(
        products: const [],
        isLoading: false,
        error: e.toString(),
        searchQuery: state.searchQuery,
        selectedCategory: state.selectedCategory,
      );
    }
  }

  Future<void> _autoTranslateProducts() async {
    final userLang = _ref.read(authProvider).user?.preferredLanguage ?? 'fr';

    for (int i = 0; i < state.products.length; i++) {
      final p = state.products[i];
      if (p.originalLanguage.toLowerCase() != userLang.toLowerCase() &&
          p.translatedTitle == null) {
        try {
          final res = await _apiClient.dio.post('/translation', data: {
            'text': '${p.title} --- ${p.description}',
            'source_language': p.originalLanguage,
            'target_language': userLang,
          });

          final trans = res.data['translated_text'] ?? res.data['translatedText'];
          if (trans != null && trans.toString().contains('---')) {
            final parts = trans.toString().split('---');
            final updated = p.copyWith(
              translatedTitle: parts[0].trim(),
              translatedDescription: parts[1].trim(),
            );
            final copy = List<ProductModel>.from(state.products);
            copy[i] = updated;
            state = MarketplaceState(
              products: copy,
              isLoading: state.isLoading,
              searchQuery: state.searchQuery,
              selectedCategory: state.selectedCategory,
            );
          }
        } catch (_) {}
      }
    }
  }

  Future<bool> createProduct({
    required String title,
    required double price,
    required String category,
    required String location,
    required String description,
  }) async {
    final user = _ref.read(authProvider).user;
    final lang = user?.preferredLanguage ?? 'rn';

    final encodedContent = '[PRODUIT]$title || $price || $category || $location || $description';

    try {
      await _apiClient.dio.post('/posts', data: {
        'content': encodedContent,
        'originalLanguage': lang,
      });
      await loadProducts();
      return true;
    } catch (_) {
      return false;
    }
  }

  void setSearchQuery(String q) {
    state = MarketplaceState(
      products: state.products,
      isLoading: state.isLoading,
      searchQuery: q,
      selectedCategory: state.selectedCategory,
    );
  }

  void setCategory(String cat) {
    state = MarketplaceState(
      products: state.products,
      isLoading: state.isLoading,
      searchQuery: state.searchQuery,
      selectedCategory: cat,
    );
  }
}

final marketplaceProvider =
    StateNotifierProvider<MarketplaceNotifier, MarketplaceState>((ref) {
  final client = ref.watch(apiClientProvider);
  return MarketplaceNotifier(client, ref);
});

