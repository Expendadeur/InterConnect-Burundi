import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Conversation } from './entities/conversation.entity';
import { Message } from './entities/message.entity';
import { SendMessageDto } from './dto/send-message.dto';

@Injectable()
export class MessagingService {
  constructor(
    @InjectRepository(Conversation)
    private readonly conversationRepo: Repository<Conversation>,
    @InjectRepository(Message)
    private readonly messageRepo: Repository<Message>,
  ) {}

  async findAllConversations(userId: string): Promise<Conversation[]> {
    return this.conversationRepo.find({
      order: { updatedAt: 'DESC' },
      take: 50,
    });
  }

  async createConversation(name?: string, isGroup = false, createdBy?: string): Promise<Conversation> {
    const conv = this.conversationRepo.create({ name, isGroup, createdBy });
    return this.conversationRepo.save(conv);
  }

  async findConversationById(id: string): Promise<Conversation> {
    const conv = await this.conversationRepo.findOne({ where: { id } });
    if (!conv) throw new NotFoundException('Conversation not found');
    return conv;
  }

  async saveMessage(senderId: string, dto: SendMessageDto): Promise<Message> {
    await this.findConversationById(dto.conversationId);
    const message = this.messageRepo.create({
      ...dto,
      senderId,
    });
    return this.messageRepo.save(message);
  }

  async getMessages(conversationId: string, limit = 50): Promise<Message[]> {
    return this.messageRepo.find({
      where: { conversationId },
      relations: ['sender'],
      order: { createdAt: 'ASC' },
      take: limit,
    });
  }

  async markAsRead(conversationId: string, userId: string): Promise<void> {
    await this.messageRepo
      .createQueryBuilder()
      .update(Message)
      .set({ isRead: true })
      .where('conversation_id = :conversationId AND sender_id != :userId', { conversationId, userId })
      .execute();
  }
}

