import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Coque principale de l'application (utilisée par le ShellRoute de app_router.dart).
/// Affiche la page enfant et une barre de navigation pour les 4 routes du shell :
/// /feed, /community, /messages et /profile/:userId.
class MainScaffold extends StatelessWidget {
  final Widget child;

  const MainScaffold({super.key, required this.child});

  static const Color _burundiRed = Color(0xFFCE1126);

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/community')) return 1;
    if (location.startsWith('/messages')) return 2;
    if (location.startsWith('/profile')) return 3;
    return 0; // /feed par défaut
  }

  void _onTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/feed');
        break;
      case 1:
        context.go('/community');
        break;
      case 2:
        context.go('/messages');
        break;
      case 3:
        // 'me' = valeur par défaut déjà utilisée dans app_router.dart pour userId
        context.go('/profile/me');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = _currentIndex(context);

    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) => _onTap(context, index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: _burundiRed,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Accueil',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_outline),
            activeIcon: Icon(Icons.people),
            label: 'Communauté',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            activeIcon: Icon(Icons.chat_bubble),
            label: 'Messages',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}