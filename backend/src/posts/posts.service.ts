import {
  Injectable,
  NotFoundException,
  ForbiddenException,
  Inject,
  LoggerService,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { WINSTON_MODULE_NEST_PROVIDER } from 'nest-winston';
import { Post, PostStatus } from './entities/post.entity';
import { CreatePostDto } from './dto/create-post.dto';
import { UpdatePostDto } from './dto/update-post.dto';
import { User, UserRole } from '../users/entities/user.entity';
import { TranslationService } from '../translation/translation.service';

@Injectable()
export class PostsService {
  constructor(
    @InjectRepository(Post)
    private readonly postsRepository: Repository<Post>,
    private readonly translationService: TranslationService,
    @Inject(WINSTON_MODULE_NEST_PROVIDER)
    private readonly logger: LoggerService,
  ) {}

  async create(authorId: string, dto: CreatePostDto): Promise<Post> {
    const post = this.postsRepository.create({
      ...dto,
      authorId,
      status: PostStatus.PUBLISHED,
    });
    return this.postsRepository.save(post);
  }

  async findAll(
    page = 1,
    limit = 20,
    targetLang?: string,
  ): Promise<{ data: Post[]; total: number }> {
    const [data, total] = await this.postsRepository.findAndCount({
      where: { status: PostStatus.PUBLISHED },
      order: { createdAt: 'DESC' },
      skip: (page - 1) * limit,
      take: limit,
    });

    if (targetLang) {
      const translated = await Promise.allSettled(
        data.map(async (post) => {
          if (post.originalLanguage !== targetLang) {
            try {
              const translatedContent = await this.translationService.translate(
                post.content,
                post.originalLanguage,
                targetLang,
              );
              return { ...post, content: translatedContent };
            } catch (err) {
              this.logger.warn(
                `Translation failed for post ${post.id}: ${err.message}`,
                'PostsService',
              );
              return post;
            }
          }
          return post;
        }),
      );

      const translatedData = translated.map((result, index) =>
        result.status === 'fulfilled' ? result.value : data[index],
      ) as Post[];

      return { data: translatedData, total };
    }

    return { data, total };
  }

  async findOne(id: string, targetLang?: string): Promise<Post> {
    const post = await this.postsRepository.findOne({ where: { id } });
    if (!post) throw new NotFoundException(`Post ${id} not found`);

    if (targetLang && post.originalLanguage !== targetLang) {
      try {
        post.content = await this.translationService.translate(
          post.content,
          post.originalLanguage,
          targetLang,
        );
      } catch {
        // Return original content if translation fails
      }
    }

    // Increment view count (non-blocking)
    this.postsRepository.increment({ id }, 'viewsCount', 1).catch(() => null);

    return post;
  }

  async update(id: string, userId: string, role: UserRole, dto: UpdatePostDto): Promise<Post> {
    const post = await this.postsRepository.findOne({ where: { id } });
    if (!post) throw new NotFoundException(`Post ${id} not found`);

    if (post.authorId !== userId && role !== UserRole.ADMIN && role !== UserRole.MODERATOR) {
      throw new ForbiddenException('You can only update your own posts');
    }

    Object.assign(post, dto);
    return this.postsRepository.save(post);
  }

  async remove(id: string, userId: string, role: UserRole): Promise<void> {
    const post = await this.postsRepository.findOne({ where: { id } });
    if (!post) throw new NotFoundException(`Post ${id} not found`);

    if (post.authorId !== userId && role !== UserRole.ADMIN && role !== UserRole.MODERATOR) {
      throw new ForbiddenException('You can only delete your own posts');
    }

    await this.postsRepository.remove(post);
  }

  async likePost(id: string): Promise<void> {
    await this.postsRepository.increment({ id }, 'likesCount', 1);
  }

  async unlikePost(id: string): Promise<void> {
    await this.postsRepository.decrement({ id }, 'likesCount', 1);
  }

  async findByAuthor(authorId: string, page = 1, limit = 20): Promise<{ data: Post[]; total: number }> {
    const [data, total] = await this.postsRepository.findAndCount({
      where: { authorId, status: PostStatus.PUBLISHED },
      order: { createdAt: 'DESC' },
      skip: (page - 1) * limit,
      take: limit,
    });
    return { data, total };
  }
}
