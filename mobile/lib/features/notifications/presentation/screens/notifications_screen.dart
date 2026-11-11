import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';

class NotificationItem {
  final String id;
  final String title;
  final String message;
  final IconData icon;
  final Color color;
  final DateTime time;
  final bool isRead;

  const NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.icon,
    required this.color,
    required this.time,
    this.isRead = false,
  });
}

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<NotificationItem> notifications = [
      NotificationItem(
        id: '1',
        title: 'Nouvelle vente confirmée !',
        message: 'Un acheteur a commandé votre article "Panier Agaseke".',
        icon: Icons.shopping_bag_outlined,
        color: AppColors.success,
        time: DateTime.now().subtract(const Duration(minutes: 25)),
      ),
      NotificationItem(
        id: '2',
        title: 'Traduction automatique appliquée',
        message: 'Votre publication en Kirundi a été lue par des membres en Français et Anglais.',
        icon: Icons.auto_awesome,
        color: AppColors.primary,
        time: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      NotificationItem(
        id: '3',
        title: 'Nouveau message reçu',
        message: 'Vous avez reçu un message instantanément traduit dans votre langue.',
        icon: Icons.chat_bubble_outline,
        color: AppColors.primary,
        time: DateTime.now().subtract(const Duration(hours: 5)),
      ),
      NotificationItem(
        id: '4',
        title: 'Sécurité du compte validée',
        message: 'Votre profil avec CNI et Téléphone est actif et vérifié.',
        icon: Icons.verified_user_outlined,
        color: AppColors.success,
        time: DateTime.now().subtract(const Duration(days: 1)),
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/feed'),
        ),
        title: const Text('Notifications', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all),
            tooltip: 'Tout marquer comme lu',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Toutes les notifications sont marquées comme lues.')),
              );
            },
          ),
        ],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(14),
        itemCount: notifications.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, i) {
          final n = notifications[i];
          return Card(
            elevation: 0.5,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: const BorderSide(color: AppColors.divider),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: CircleAvatar(
                backgroundColor: n.color.withOpacity(0.12),
                child: Icon(n.icon, color: n.color, size: 22),
              ),
              title: Text(n.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text(n.message, style: const TextStyle(fontSize: 12, color: AppColors.onSurface)),
                  const SizedBox(height: 4),
                  Text(
                    '${n.time.hour}:${n.time.minute.toString().padLeft(2, '0')}',
                    style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

