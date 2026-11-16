import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/services/ringtone_service.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class CallScreen extends ConsumerStatefulWidget {
  final String roomName;
  final UserModel? extraUser;

  const CallScreen({super.key, required this.roomName, this.extraUser});

  @override
  ConsumerState<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends ConsumerState<CallScreen> with SingleTickerProviderStateMixin {
  UserModel? _interlocutor;
  bool _isLoading = true;
  bool _isMuted = false;
  bool _isVideoOff = false;
  bool _isSpeakerOn = false;

  bool _isOffline = false;
  bool _isRinging = false;
  bool _isConnected = false;
  bool _noAnswer = false;

  int _callDurationSeconds = 0;
  Timer? _callTimer;
  Timer? _ringingTimer;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  String get _cleanTargetId {
    if (widget.roomName.startsWith('room-')) {
      return widget.roomName.substring(5);
    }
    return widget.roomName;
  }

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    if (widget.extraUser != null) {
      _interlocutor = widget.extraUser;
      _isLoading = false;
      _handleCallFlow();
    } else {
      _loadInterlocutor();
    }
  }

  Future<void> _loadInterlocutor() async {
    final targetId = _cleanTargetId;

    try {
      final apiClient = ref.read(apiClientProvider);
      final res = await apiClient.dio.get('/users/$targetId');
      if (mounted) {
        setState(() {
          _interlocutor = UserModel.fromJson(res.data);
          _isLoading = false;
        });
        _handleCallFlow();
      }
    } catch (_) {
      // Si l'ID était un ID de conversation, tente d'extraire l'interlocuteur des messages
      try {
        final apiClient = ref.read(apiClientProvider);
        final convRes = await apiClient.dio.get('/messaging/conversations/$targetId/messages');
        final raw = convRes.data as List<dynamic>? ?? [];
        final currentUserId = ref.read(authProvider).user?.id;
        String? otherUserId;
        for (final m in raw) {
          if (m['senderId'] != null && m['senderId'] != currentUserId) {
            otherUserId = m['senderId'].toString();
            break;
          }
        }
        if (otherUserId != null) {
          final userRes = await apiClient.dio.get('/users/$otherUserId');
          if (mounted) {
            setState(() {
              _interlocutor = UserModel.fromJson(userRes.data);
              _isLoading = false;
            });
            _handleCallFlow();
            return;
          }
        }
      } catch (_) {}

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _handleCallFlow();
      }
    }
  }

  void _handleCallFlow() {
    // ─── 1. CAS : INTERLOCUTEUR INTROUVABLE OU HORS LIGNE ───
    if (_interlocutor == null || !_interlocutor!.isOnline) {
      RingtoneService.stop();
      _ringingTimer?.cancel();
      _callTimer?.cancel();
      if (mounted) {
        setState(() {
          _isOffline = true;
          _isRinging = false;
          _isConnected = false;
          _noAnswer = false;
        });
      }
      HapticFeedback.heavyImpact();
      return;
    }

    // ─── 2. CAS : INTERLOCUTEUR EN LIGNE ───
    // Démarrer la sonnerie native
    if (mounted) {
      setState(() {
        _isOffline = false;
        _isRinging = true;
        _isConnected = false;
        _noAnswer = false;
      });
    }

    RingtoneService.play();

    // Sonnerie jusqu'à 30 secondes max en attente de décrochage (JAMAIS d'auto-connexion factice !)
    _ringingTimer?.cancel();
    int seconds = 0;
    _ringingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      seconds++;
      if (!mounted) {
        timer.cancel();
        RingtoneService.stop();
        return;
      }
      HapticFeedback.lightImpact();

      if (seconds >= 30) {
        timer.cancel();
        RingtoneService.stop();
        if (mounted) {
          setState(() {
            _isRinging = false;
            _isConnected = false;
            _noAnswer = true;
          });
        }
      }
    });
  }

  void _startCallTimer() {
    _callTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _callDurationSeconds++;
        });
      }
    });
  }

  String _formatDuration(int totalSeconds) {
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
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
  void dispose() {
    RingtoneService.stop();
    _pulseController.dispose();
    _ringingTimer?.cancel();
    _callTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final displayName = _interlocutor?.displayName ?? 'Correspondant';
    final isOffline = _isOffline || (_interlocutor != null && !_interlocutor!.isOnline);
    final profileImage = _getProfileImage(_interlocutor?.avatarUrl);
    final initials = displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U';

    return Scaffold(
      backgroundColor: const Color(0xFF14171A),
      body: SafeArea(
        child: Column(
          children: [
            // ─── EN-TÊTE D'APPEL AVEC NOM DU CORRESPONDANT ───
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () {
                      RingtoneService.stop();
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go('/feed');
                      }
                    },
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isOffline
                              ? 'Hors ligne'
                              : _isConnected
                                  ? 'En communication'
                                  : _noAnswer
                                      ? 'Aucune réponse'
                                      : 'Appel vocal sécurisé',
                          style: TextStyle(
                            color: isOffline
                                ? Colors.orangeAccent
                                : _isConnected
                                    ? AppColors.success
                                    : Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_isConnected)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.success.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.success, width: 1),
                      ),
                      child: Text(
                        _formatDuration(_callDurationSeconds),
                        style: const TextStyle(
                          color: AppColors.success,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            const Spacer(flex: 1),

            // ─── PHOTO DE PROFIL & ONDE DE SONNERIE ───
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      // Onde pulsante pendant la sonnerie uniquement si en ligne et sonne
                      if (_isRinging && !isOffline)
                        AnimatedBuilder(
                          animation: _pulseAnimation,
                          builder: (context, child) {
                            return Container(
                              width: 150 * _pulseAnimation.value,
                              height: 150 * _pulseAnimation.value,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.primary.withOpacity(0.18),
                              ),
                            );
                          },
                        ),

                      // Avatar photo de profil
                      Container(
                        width: 124,
                        height: 124,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isOffline
                                ? Colors.orangeAccent
                                : _isConnected
                                    ? AppColors.success
                                    : _noAnswer
                                        ? Colors.grey
                                        : AppColors.primary,
                            width: 3.5,
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 60,
                          backgroundColor: AppColors.primary.withOpacity(0.2),
                          backgroundImage: profileImage,
                          child: profileImage == null
                              ? Text(
                                  initials,
                                  style: const TextStyle(
                                    fontSize: 48,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                )
                              : null,
                        ),
                      ),

                      // Indicateur d'état en bas à droite de l'avatar
                      Positioned(
                        bottom: 4,
                        right: 4,
                        child: Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            color: isOffline
                                ? Colors.orangeAccent
                                : _isConnected
                                    ? const Color(0xFF1EB53A)
                                    : _noAnswer
                                        ? Colors.grey
                                        : AppColors.primary,
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFF14171A), width: 3),
                          ),
                          child: Icon(
                            isOffline
                                ? Icons.wifi_off
                                : _isConnected
                                    ? Icons.check
                                    : _noAnswer
                                        ? Icons.phone_missed
                                        : Icons.phone,
                            size: 11,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Nom affiché sous l'avatar
                  Text(
                    displayName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ─── ÉTATS DE L'APPEL ───
                  if (isOffline) ...[
                    // CAS HORS LIGNE
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 32),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.orangeAccent.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.orangeAccent.withOpacity(0.4)),
                      ),
                      child: Column(
                        children: [
                          const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.wifi_off, color: Colors.orangeAccent, size: 18),
                              SizedBox(width: 8),
                              Text(
                                'Interlocuteur hors ligne',
                                style: TextStyle(
                                  color: Colors.orangeAccent,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '$displayName n\'est pas connecté à Internet pour le moment.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white70, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    ElevatedButton.icon(
                      onPressed: () {
                        RingtoneService.stop();
                        if (_interlocutor != null) {
                          context.go('/chat/${_interlocutor!.id}');
                        } else {
                          context.pop();
                        }
                      },
                      icon: const Icon(Icons.chat_bubble_outline, color: Colors.white),
                      label: const Text('Envoyer un message à la place'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                    ),
                  ] else if (_noAnswer) ...[
                    // CAS AUCUNE RÉPONSE
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 32),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white10,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: Column(
                        children: [
                          const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.phone_missed, color: Colors.white70, size: 18),
                              SizedBox(width: 8),
                              Text(
                                'Aucune réponse',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '$displayName ne répond pas pour l\'instant.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white70, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () => _handleCallFlow(),
                          icon: const Icon(Icons.refresh, color: Colors.white),
                          label: const Text('Rappeler', style: TextStyle(color: Colors.white)),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.white30),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: () {
                            RingtoneService.stop();
                            if (_interlocutor != null) {
                              context.go('/chat/${_interlocutor!.id}');
                            } else {
                              context.pop();
                            }
                          },
                          icon: const Icon(Icons.chat_bubble_outline, color: Colors.white),
                          label: const Text('Message'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          ),
                        ),
                      ],
                    ),
                  ] else if (_isConnected) ...[
                    // CAS CONNECTÉ (si communication acceptée)
                    Text(
                      _formatDuration(_callDurationSeconds),
                      style: const TextStyle(
                        color: AppColors.success,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ] else ...[
                    // CAS SONNERIE EN COURS
                    const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                        ),
                        SizedBox(width: 10),
                        Text(
                          'Sonnerie en cours...',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            const Spacer(flex: 2),

            // ─── COMMANDES DE L'APPEL EN BAS ───
            Padding(
              padding: const EdgeInsets.only(bottom: 40.0, left: 24.0, right: 24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Muet / Activer micro
                  _buildCallButton(
                    icon: _isMuted ? Icons.mic_off : Icons.mic,
                    label: _isMuted ? 'Activé' : 'Muet',
                    isActive: _isMuted,
                    activeColor: Colors.orange,
                    onTap: isOffline ? () {} : () => setState(() => _isMuted = !_isMuted),
                  ),

                  // Bouton Raccrocher / Quitter (Rouge)
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: () {
                          RingtoneService.stop();
                          _ringingTimer?.cancel();
                          _callTimer?.cancel();
                          HapticFeedback.mediumImpact();
                          if (context.canPop()) {
                            context.pop();
                          } else {
                            context.go('/feed');
                          }
                        },
                        child: Container(
                          width: 68,
                          height: 68,
                          decoration: const BoxDecoration(
                            color: AppColors.error,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black45,
                                blurRadius: 10,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(Icons.call_end, color: Colors.white, size: 34),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isOffline || _noAnswer ? 'Fermer' : 'Raccrocher',
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),

                  // Haut-parleur (Bascule uniquement le son du haut-parleur — N'altère JAMAIS l'état de connexion !)
                  _buildCallButton(
                    icon: _isSpeakerOn ? Icons.volume_up : Icons.volume_down,
                    label: 'Haut-parleur',
                    isActive: _isSpeakerOn,
                    activeColor: AppColors.primary,
                    onTap: () => setState(() => _isSpeakerOn = !_isSpeakerOn),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCallButton({
    required IconData icon,
    required String label,
    required bool isActive,
    required Color activeColor,
    required VoidCallback onTap,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: isActive ? activeColor.withOpacity(0.25) : Colors.white12,
              shape: BoxShape.circle,
              border: Border.all(
                color: isActive ? activeColor : Colors.white24,
                width: 1.5,
              ),
            ),
            child: Icon(icon, color: isActive ? activeColor : Colors.white, size: 26),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }
}
