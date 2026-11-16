import { Injectable, Logger } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Conversation } from './entities/conversation.entity';
import { Message } from './entities/message.entity';
import { User } from '../users/entities/user.entity';
import { SendMessageDto } from './dto/send-message.dto';
import * as crypto from 'crypto';

@Injectable()
export class MessagingService {
  private readonly logger = new Logger(MessagingService.name);

  constructor(
    @InjectRepository(Conversation)
    private readonly conversationRepo: Repository<Conversation>,
    @InjectRepository(Message)
    private readonly messageRepo: Repository<Message>,
    @InjectRepository(User)
    private readonly userRepo: Repository<User>,
  ) {}

  /**
   * Génère un UUID déterministe et unique pour une discussion 1-à-1 entre deux utilisateurs.
   * Peu importe qui initie (userA ou userB), l'ID généré est STRICTEMENT IDENTIQUE.
   */
  getDirectConversationId(user1: string, user2: string): string {
    const sorted = [user1.toLowerCase().trim(), user2.toLowerCase().trim()].sort();
    const hash = crypto.createHash('sha256').update(`direct:${sorted.join(':')}`).digest('hex');
    return `${hash.substring(0, 8)}-${hash.substring(8, 12)}-${hash.substring(12, 16)}-${hash.substring(16, 20)}-${hash.substring(20, 32)}`;
  }

  /**
   * Résout l'identifiant réel de conversation :
   * Si rawId est l'ID d'un autre utilisateur, on calcule la conversation directe unique entre les deux.
   */
  async resolveConversation(
    rawId: string,
    currentUserId: string,
  ): Promise<{ conversationId: string; otherUser?: User }> {
    if (!rawId) {
      return { conversationId: rawId };
    }

    // Si rawId est l'ID d'un utilisateur différent
    if (rawId !== currentUserId) {
      const otherUser = await this.userRepo.findOne({ where: { id: rawId } });
      if (otherUser) {
        const directId = this.getDirectConversationId(currentUserId, otherUser.id);
        return { conversationId: directId, otherUser };
      }
    }

    return { conversationId: rawId };
  }

  async findAllConversations(userId: string): Promise<any[]> {
    // 1. Trouver toutes les conversations où l'utilisateur est listé
    const conversations = await this.conversationRepo
      .createQueryBuilder('c')
      .where('c.participantIds LIKE :userPattern OR c.createdBy = :userId', {
        userPattern: `%${userId}%`,
        userId,
      })
      .orderBy('c.updatedAt', 'DESC')
      .take(50)
      .getMany();

    // 2. Trouver aussi les messages orphelins (anciennes conversations)
    const directMessages = await this.messageRepo
      .createQueryBuilder('m')
      .where('m.senderId = :userId OR m.recipientId = :userId', { userId })
      .orderBy('m.createdAt', 'DESC')
      .take(100)
      .getMany();

    const seenConvIds = new Set<string>(conversations.map((c) => c.id));
    for (const msg of directMessages) {
      if (!seenConvIds.has(msg.conversationId)) {
        seenConvIds.add(msg.conversationId);
        const conv = await this.conversationRepo.findOne({ where: { id: msg.conversationId } });
        if (conv) {
          conversations.push(conv);
        }
      }
    }

    // 3. Enrichir chaque conversation avec son dernier message et les infos du correspondant
    const enriched = await Promise.all(
      conversations.map(async (conv) => {
        const lastMsg = await this.messageRepo.findOne({
          where: { conversationId: conv.id },
          order: { createdAt: 'DESC' },
          relations: ['sender'],
        });

        // Déterminer l'autre participant
        let otherUser: User | null = null;
        if (conv.participantIds) {
          const ids = conv.participantIds.split(',').map((id) => id.trim());
          const otherId = ids.find((id) => id !== userId);
          if (otherId) {
            otherUser = await this.userRepo.findOne({ where: { id: otherId } });
          }
        } else if (lastMsg) {
          if (lastMsg.senderId !== userId && lastMsg.sender) {
            otherUser = lastMsg.sender;
          } else if (lastMsg.recipientId && lastMsg.recipientId !== userId) {
            otherUser = await this.userRepo.findOne({ where: { id: lastMsg.recipientId } });
          }
        }

        const otherName = otherUser
          ? (otherUser.firstName || otherUser.lastName
              ? `${otherUser.firstName || ''} ${otherUser.lastName || ''}`.trim()
              : otherUser.username)
          : conv.name || 'Discussion directe';

        return {
          id: otherUser ? otherUser.id : conv.id, // Redirige directement vers l'interlocuteur
          conversationId: conv.id,
          name: otherName,
          avatarUrl: otherUser ? otherUser.avatarUrl : conv.avatarUrl,
          isOnline: otherUser ? otherUser.isOnline : false,
          isGroup: conv.isGroup,
          updatedAt: lastMsg ? lastMsg.createdAt : conv.updatedAt,
          lastMessage: lastMsg
            ? {
                content: lastMsg.content,
                originalLanguage: lastMsg.originalLanguage,
                senderId: lastMsg.senderId,
                createdAt: lastMsg.createdAt,
                isRead: lastMsg.isRead,
              }
            : null,
        };
      }),
    );

    // Filtrer les doublons de contact éventuels et trier par date décroissante
    const uniqueByContact = new Map<string, any>();
    for (const item of enriched) {
      const contactKey = item.id;
      if (!uniqueByContact.has(contactKey)) {
        uniqueByContact.set(contactKey, item);
      }
    }

    return Array.from(uniqueByContact.values()).sort(
      (a, b) => new Date(b.updatedAt).getTime() - new Date(a.updatedAt).getTime(),
    );
  }

  async createConversation(name?: string, isGroup = false, createdBy?: string): Promise<Conversation> {
    const conv = this.conversationRepo.create({ name, isGroup, createdBy });
    return this.conversationRepo.save(conv);
  }

  async findConversationById(id: string): Promise<Conversation> {
    let conv = await this.conversationRepo.findOne({ where: { id } });
    if (!conv) {
      conv = this.conversationRepo.create({ id, name: 'Discussion directe' });
      await this.conversationRepo.save(conv);
    }
    return conv;
  }

  async saveMessage(senderId: string, dto: SendMessageDto): Promise<Message> {
    const { conversationId, otherUser } = await this.resolveConversation(
      dto.conversationId,
      senderId,
    );

    let conv = await this.conversationRepo.findOne({ where: { id: conversationId } });
    if (!conv) {
      conv = this.conversationRepo.create({
        id: conversationId,
        name: otherUser
          ? (otherUser.firstName || otherUser.lastName
              ? `${otherUser.firstName || ''} ${otherUser.lastName || ''}`.trim()
              : otherUser.username)
          : 'Discussion directe',
        avatarUrl: otherUser ? otherUser.avatarUrl : undefined,
        participantIds: otherUser ? `${senderId},${otherUser.id}` : senderId,
        createdBy: senderId,
        isGroup: false,
      });
      await this.conversationRepo.save(conv);
    } else {
      if (otherUser && (!conv.participantIds || !conv.participantIds.includes(otherUser.id))) {
        conv.participantIds = `${senderId},${otherUser.id}`;
      }
      conv.updatedAt = new Date();
      await this.conversationRepo.save(conv);
    }

    const message = this.messageRepo.create({
      ...dto,
      conversationId,
      senderId,
      recipientId: otherUser ? otherUser.id : undefined,
    });

    return this.messageRepo.save(message);
  }

  async getMessages(rawId: string, currentUserId?: string, limit = 100): Promise<Message[]> {
    let resolvedId = rawId;
    if (currentUserId) {
      const resolved = await this.resolveConversation(rawId, currentUserId);
      resolvedId = resolved.conversationId;
    }

    // Récupérer tous les messages de la conversation unifiée (avec fallback sur rawId pour ancien historique)
    const messages = await this.messageRepo
      .createQueryBuilder('m')
      .leftJoinAndSelect('m.sender', 'sender')
      .where('m.conversationId = :resolvedId OR m.conversationId = :rawId', {
        resolvedId,
        rawId,
      })
      .orderBy('m.createdAt', 'ASC')
      .take(limit)
      .getMany();

    return messages;
  }

  async markAsRead(rawId: string, userId: string): Promise<void> {
    const resolved = await this.resolveConversation(rawId, userId);
    await this.messageRepo
      .createQueryBuilder()
      .update(Message)
      .set({ isRead: true })
      .where(
        '(conversation_id = :convId OR conversation_id = :rawId) AND sender_id != :userId',
        { convId: resolved.conversationId, rawId, userId },
      )
      .execute();
  }
}
