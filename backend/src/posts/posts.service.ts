import {
  Injectable,
  NotFoundException,
  ForbiddenException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Post } from './entities/post.entity';
import { PostTranslation } from './entities/post-translation.entity';
import { CreatePostDto } from './dto/create-post.dto';
import { UpdatePostDto } from './dto/update-post.dto';

@Injectable()
export class PostsService {
  constructor(
    @InjectRepository(Post)
    private readonly postsRepository: Repository<Post>,
    @InjectRepository(PostTranslation)
    private readonly translationsRepository: Repository<PostTranslation>,
  ) {}

  async create(authorId: string, dto: CreatePostDto): Promise<Post> {
    const post = this.postsRepository.create({
      ...dto,
      authorId,
    });
    return this.postsRepository.save(post);
  }

  async findAll(page = 1, limit = 20): Promise<{ data: Post[]; total: number; page: number; totalPages: number }> {
    const skip = (page - 1) * limit;
    const [data, total] = await this.postsRepository.findAndCount({
      relations: ['author', 'translations'],
      order: { createdAt: 'DESC' },
      skip,
      take: limit,
    });

    return {
      data,
      total,
      page,
      totalPages: Math.ceil(total / limit),
    };
  }

  async findById(id: string): Promise<Post> {
    const post = await this.postsRepository.findOne({
      where: { id },
      relations: ['author', 'translations', 'comments', 'comments.author'],
    });
    if (!post) throw new NotFoundException(`Post with ID ${id} not found`);
    return post;
  }

  async update(id: string, userId: string, dto: UpdatePostDto): Promise<Post> {
    const post = await this.findById(id);
    if (post.authorId !== userId) {
      throw new ForbiddenException('You can only update your own posts');
    }
    Object.assign(post, dto);
    return this.postsRepository.save(post);
  }

  async delete(id: string, userId: string): Promise<void> {
    const post = await this.findById(id);
    if (post.authorId !== userId) {
      throw new ForbiddenException('You can only delete your own posts');
    }
    await this.postsRepository.remove(post);
  }

  async getTranslation(postId: string, targetLanguage: string): Promise<PostTranslation | null> {
    return this.translationsRepository.findOne({
      where: { postId, targetLanguage },
    });
  }

  async saveTranslation(postId: string, targetLanguage: string, translatedContent: string, provider: string): Promise<PostTranslation> {
    let translation = await this.getTranslation(postId, targetLanguage);
    if (translation) {
      translation.translatedContent = translatedContent;
      translation.provider = provider;
    } else {
      translation = this.translationsRepository.create({
        postId,
        targetLanguage,
        translatedContent,
        provider,
      });
    }
    return this.translationsRepository.save(translation);
  }
}

