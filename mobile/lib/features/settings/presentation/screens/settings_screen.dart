import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _autoTranslate = true;
  bool _pushNotifications = true;
  bool _soundEnabled = true;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/feed'),
        ),
        title: const Text('Paramètres', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Section Langue & IA
          _sectionHeader('TRADUCTION & IA'),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: AppColors.divider)),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.translate, color: AppColors.primary),
                  title: const Text('Langue maternelle'),
                  subtitle: Text(user?.preferredLanguage.toUpperCase() ?? 'FR'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Pour modifier votre langue, mettez à jour votre profil.')),
                    );
                  },
                ),
                const Divider(height: 1),
                SwitchListTile(
                  secondary: const Icon(Icons.auto_awesome, color: AppColors.primary),
                  title: const Text('Traduction instantanée automatique'),
                  subtitle: const Text('Traduire automatiquement tous les contenus reçus'),
                  value: _autoTranslate,
                  onChanged: (v) => setState(() => _autoTranslate = v),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Section Notifications
          _sectionHeader('NOTIFICATIONS'),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: AppColors.divider)),
            child: Column(
              children: [
                SwitchListTile(
                  secondary: const Icon(Icons.notifications_active_outlined, color: AppColors.success),
                  title: const Text('Notifications push'),
                  subtitle: const Text('Alertes pour les nouveaux messages et appels'),
                  value: _pushNotifications,
                  onChanged: (v) => setState(() => _pushNotifications = v),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  secondary: const Icon(Icons.volume_up_outlined, color: AppColors.success),
                  title: const Text('Sons et sonneries d’appels'),
                  value: _soundEnabled,
                  onChanged: (v) => setState(() => _soundEnabled = v),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Section Sécurité & Compte
          _sectionHeader('SÉCURITÉ & CERTIFICATION'),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: AppColors.divider)),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.verified_outlined, color: AppColors.primary),
                  title: const Text('Badge de certification Pro'),
                  subtitle: const Text('Demander un badge certifié pour vendre à l’international'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Certification InterConnect Pro'),
                        content: const Text(
                          'Votre identité avec Carte Nationale d’Identité (CNI) et Numéro de téléphone est en cours de validation par l’administration.\n\nUne fois certifié, le badge bleu apparaîtra sur votre profil.',
                        ),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Compris')),
                        ],
                      ),
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.lock_outline, color: AppColors.onSurface),
                  title: const Text('Confidentialité des données'),
                  subtitle: const Text('Vos informations sont cryptées de bout en bout'),
                  onTap: () {},
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // Bouton Déconnexion
          ElevatedButton.icon(
            icon: const Icon(Icons.logout, color: Colors.white),
            label: const Text('Se déconnecter', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              await ref.read(authProvider.notifier).logout();
              if (mounted) context.go('/login');
            },
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: AppColors.textSecondary,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

