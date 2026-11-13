import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/calls/presentation/screens/call_screen.dart';
import '../../features/feed/presentation/screens/feed_screen.dart';
import '../../features/messaging/presentation/screens/chat_screen.dart';
import '../../features/messaging/presentation/screens/conversations_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../shared/widgets/main_scaffold.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authNotifier = ValueNotifier<bool>(false);

  ref.listen<AuthState>(authProvider, (previous, next) {
    authNotifier.value = next.isAuthenticated;
  });

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: authNotifier,
    redirect: (context, state) {
      final isAuthenticated = ref.read(authProvider).isAuthenticated;
      final isLoading = ref.read(authProvider).isLoading;
      final location = state.matchedLocation;

      if (isLoading) return null;

      final authRoutes = ['/login', '/register', '/splash'];
      final isOnAuthRoute = authRoutes.any((r) => location.startsWith(r));

      if (!isAuthenticated && !isOnAuthRoute) {
        return '/login';
      }

      if (isAuthenticated && isOnAuthRoute && location != '/splash') {
        return '/feed';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const LoginScreen(),
          transitionsBuilder: _fadeTransition,
        ),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const RegisterScreen(),
          transitionsBuilder: _slideTransition,
        ),
      ),
      ShellRoute(
        builder: (context, state, child) => MainScaffold(child: child),
        routes: [
          GoRoute(
            path: '/feed',
            name: 'feed',
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const FeedScreen(),
              transitionsBuilder: _fadeTransition,
            ),
          ),
          GoRoute(
            path: '/messages',
            name: 'messages',
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const ConversationsScreen(),
              transitionsBuilder: _fadeTransition,
            ),
          ),
          GoRoute(
            path: '/profile/:userId',
            name: 'profile',
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: ProfileScreen(
                userId: state.pathParameters['userId'] ?? 'me',
              ),
              transitionsBuilder: _slideTransition,
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/chat/:conversationId',
        name: 'chat',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: ChatScreen(
            conversationId: state.pathParameters['conversationId'] ?? '',
          ),
          transitionsBuilder: _slideTransition,
        ),
      ),
      GoRoute(
        path: '/call/:roomName',
        name: 'call',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: CallScreen(
            roomName: state.pathParameters['roomName'] ?? '',
          ),
          transitionsBuilder: _fadeTransition,
        ),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Color(0xFFCE1126)),
            const SizedBox(height: 16),
            Text(
              'Page introuvable',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(state.error?.message ?? 'Route inconnue'),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go('/feed'),
              child: const Text('Retour à l\'accueil'),
            ),
          ],
        ),
      ),
    ),
  );
});

Widget _fadeTransition(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) {
  return FadeTransition(opacity: animation, child: child);
}

Widget _slideTransition(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) {
  return SlideTransition(
    position: animation.drive(
      Tween(begin: const Offset(1.0, 0.0), end: Offset.zero).chain(
        CurveTween(curve: Curves.easeInOut),
      ),
    ),
    child: child,
  );
}
