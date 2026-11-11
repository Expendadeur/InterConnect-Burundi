import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/marketplace_provider.dart';

class MarketplaceScreen extends ConsumerStatefulWidget {
  const MarketplaceScreen({super.key});

  @override
  ConsumerState<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends ConsumerState<MarketplaceScreen> {
  final List<String> _categories = [
    'Toutes',
    'Artisanat 🎨',
    'Café & Thé ☕',
    'Agriculture 🌾',
    'Mode & Wax 👗',
    'Services & Tech 💻',
    'Immobilier 🏠',
    'Autre 📦',
  ];

  void _showAddProductDialog() {
    final titleCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final locationCtrl = TextEditingController(text: 'Bujumbura');
    final descCtrl = TextEditingController();
    String selectedCat = 'Artisanat 🎨';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
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
                      '🛍️ Vendre un article',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: titleCtrl,
                  decoration: InputDecoration(
                    labelText: 'Nom de l’article / Produit *',
                    hintText: 'Ex: Panier Agaseke traditionnel',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: priceCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Prix en BIF *',
                          hintText: 'Ex: 25000',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: locationCtrl,
                        decoration: InputDecoration(
                          labelText: 'Ville / Province *',
                          hintText: 'Ex: Gitega',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedCat,
                  decoration: InputDecoration(
                    labelText: 'Catégorie *',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  items: _categories.where((c) => c != 'Toutes').map((c) {
                    return DropdownMenuItem(value: c, child: Text(c));
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setModalState(() => selectedCat = val);
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descCtrl,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Description détaillée *',
                    hintText: 'Rédigez dans votre langue, l’IA traduira pour les acheteurs internationaux.',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  icon: const Icon(Icons.cloud_upload, color: Colors.white),
                  label: const Text(
                    'Publier l’article sur le Marché',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () async {
                    if (titleCtrl.text.trim().isEmpty || priceCtrl.text.trim().isEmpty) {
                      return;
                    }
                    Navigator.pop(ctx);
                    final price = double.tryParse(priceCtrl.text.trim()) ?? 0.0;
                    final ok = await ref.read(marketplaceProvider.notifier).createProduct(
                          title: titleCtrl.text.trim(),
                          price: price,
                          category: selectedCat,
                          location: locationCtrl.text.trim(),
                          description: descCtrl.text.trim(),
                        );
                    if (ok && mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('✅ Article publié avec succès sur le Marché mondial !'),
                          backgroundColor: AppColors.success,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(marketplaceProvider);
    final user = ref.watch(authProvider).user;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/feed'),
        ),
        title: const Row(
          children: [
            Text('🛍️ ', style: TextStyle(fontSize: 22)),
            Text(
              'Marché Mondial',
              style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_balance_wallet_outlined, color: AppColors.success),
            tooltip: 'Mon Portefeuille',
            onPressed: () => context.go('/wallet'),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(104),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Rechercher un produit, café, artisanat...',
                    prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: const BorderSide(color: AppColors.divider),
                    ),
                  ),
                  onChanged: (q) => ref.read(marketplaceProvider.notifier).setSearchQuery(q),
                ),
              ),
              SizedBox(
                height: 42,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: _categories.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, i) {
                    final cat = _categories[i];
                    final isSel = state.selectedCategory == cat;
                    return ChoiceChip(
                      label: Text(cat, style: TextStyle(fontSize: 12, color: isSel ? Colors.white : Colors.black87)),
                      selected: isSel,
                      selectedColor: AppColors.primary,
                      onSelected: (_) => ref.read(marketplaceProvider.notifier).setCategory(cat),
                    );
                  },
                ),
              ),
              const SizedBox(height: 6),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.success,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_shopping_cart),
        label: const Text('Vendre un article'),
        onPressed: _showAddProductDialog,
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(marketplaceProvider.notifier).loadProducts(),
        child: state.isLoading && state.products.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : state.filteredProducts.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.storefront_outlined, size: 70, color: AppColors.textSecondary),
                        const SizedBox(height: 12),
                        const Text(
                          'Aucun article dans cette catégorie.',
                          style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.add),
                          label: const Text('Soyez le premier à publier !'),
                          onPressed: _showAddProductDialog,
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(14),
                    itemCount: state.filteredProducts.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, i) {
                      final p = state.filteredProducts[i];
                      final displayTitle = p.translatedTitle ?? p.title;
                      final displayDesc = p.translatedDescription ?? p.description;

                      return Card(
                        elevation: 1.5,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: const BorderSide(color: AppColors.divider),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(14.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 18,
                                    backgroundColor: AppColors.primary.withOpacity(0.1),
                                    backgroundImage: p.sellerAvatar != null
                                        ? NetworkImage(p.sellerAvatar!)
                                        : null,
                                    child: p.sellerAvatar == null
                                        ? Text(p.sellerName.isNotEmpty ? p.sellerName[0].toUpperCase() : 'V')
                                        : null,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          p.sellerName,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                        ),
                                        Text(
                                          '📍 ${p.location} • ${p.category}',
                                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: AppColors.success.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: AppColors.success.withOpacity(0.4)),
                                    ),
                                    child: Text(
                                      '${p.price.toStringAsFixed(0)} BIF',
                                      style: const TextStyle(
                                        color: AppColors.success,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(height: 20),
                              Text(
                                displayTitle,
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                displayDesc,
                                style: const TextStyle(fontSize: 13, color: AppColors.onSurface, height: 1.4),
                              ),
                              const SizedBox(height: 14),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      icon: const Icon(Icons.chat_outlined, size: 18, color: AppColors.primary),
                                      label: const Text('Discuter (traduit auto)'),
                                      style: OutlinedButton.styleFrom(
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      ),
                                      onPressed: () {
                                        context.go('/messages');
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      icon: const Icon(Icons.shopping_bag_outlined, size: 18, color: Colors.white),
                                      label: const Text('Acheter', style: TextStyle(fontWeight: FontWeight.bold)),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.primary,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      ),
                                      onPressed: () {
                                        showDialog(
                                          context: context,
                                          builder: (ctx) => AlertDialog(
                                            title: Text('Commander : $displayTitle'),
                                            content: Text(
                                              'Voulez-vous initier l’achat auprès de ${p.sellerName} pour un montant de ${p.price.toStringAsFixed(0)} BIF ?\n\nVous pourrez contacter directement le vendeur au ${p.sellerPhone}.',
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.pop(ctx),
                                                child: const Text('Annuler'),
                                              ),
                                              ElevatedButton(
                                                onPressed: () {
                                                  Navigator.pop(ctx);
                                                  context.go('/messages');
                                                },
                                                style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
                                                child: const Text('Confirmer & Contacter', style: TextStyle(color: Colors.white)),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}

