import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Comment } from './entities/comment.entity';
import { Reaction, ReactionType } from './entities/reaction.entity';
import { CreateCommentDto } from './dto/create-comment.dto';
import { ToggleReactionDto } from './dto/reaction.dto';

@Injectable()
export class CommentsService {
  constructor(
    @InjectRepository(Comment)
    private readonly commentsRepository: Repository<Comment>,
    @InjectRepository(Reaction)
    private readonly reactionsRepository: Repository<Reaction>,
  ) {}

  async create(postId: string, authorId: string, dto: CreateCommentDto): Promise<Comment> {
    const comment = this.commentsRepository.create({
      postId,
      authorId,
      ...dto,
    });
    return this.commentsRepository.save(comment);
  }

  async findByPost(postId: string): Promise<Comment[]> {
    return this.commentsRepository.find({
      where: { postId },
      relations: ['author'],
      order: { createdAt: 'ASC' },
    });
  }

  async toggleReaction(userId: string, dto: ToggleReactionDto): Promise<{ reacted: boolean; reactionType?: ReactionType }> {
    const where: any = { userId };
    if (dto.postId) where.postId = dto.postId;
    if (dto.commentId) where.commentId = dto.commentId;

    const existing = await this.reactionsRepository.findOne({ where });
    if (existing) {
      if (existing.reactionType === dto.reactionType) {
        await this.reactionsRepository.remove(existing);
        return { reacted: false };
      } else {
        existing.reactionType = dto.reactionType;
        await this.reactionsRepository.save(existing);
        return { reacted: true, reactionType: dto.reactionType };
      }
    }

    const reaction = this.reactionsRepository.create({
      userId,
      postId: dto.postId,
      commentId: dto.commentId,
      reactionType: dto.reactionType,
    });
    await this.reactionsRepository.save(reaction);
    return { reacted: true, reactionType: dto.reactionType };
  }
}

