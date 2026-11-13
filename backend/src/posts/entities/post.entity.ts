import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
  ManyToOne,
  OneToMany,
  JoinColumn,
} from 'typeorm';
import { ApiProperty } from '@nestjs/swagger';
import { User } from '../../users/entities/user.entity';
import { Comment } from '../../comments/entities/comment.entity';
// CORRECTION TS2339 : import de l'entité PostTranslation pour la relation inverse
import { PostTranslation } from './post-translation.entity';

export enum PostType {
  TEXT = 'text',
  IMAGE = 'image',
  VIDEO = 'video',
  AUDIO = 'audio',
  LINK = 'link',
}

export enum PostStatus {
  PUBLISHED = 'published',
  DRAFT = 'draft',
  ARCHIVED = 'archived',
}

@Entity('posts')
export class Post {
  @ApiProperty({ example: 'uuid-v4' })
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @ApiProperty({ enum: PostType, example: PostType.TEXT })
  @Column({ type: 'enum', enum: PostType, default: PostType.TEXT })
  type: PostType;

  @ApiProperty({ example: 'Bonjour Burundi! 🇧🇮' })
  @Column({ type: 'text' })
  content: string;

  @ApiProperty({ example: 'https://cdn.example.com/media/post.jpg', required: false })
  @Column({ name: 'media_url', nullable: true })
  mediaUrl: string;

  @ApiProperty({ example: 'https://example.com', required: false })
  @Column({ name: 'link_url', nullable: true })
  linkUrl: string;

  @ApiProperty({ example: ['technology', 'burundi'] })
  @Column({ type: 'text', array: true, default: [] })
  tags: string[];

  @ApiProperty({ example: 'fr' })
  @Column({ name: 'original_language', length: 10, default: 'fr' })
  originalLanguage: string;

  @ApiProperty({ enum: PostStatus, example: PostStatus.PUBLISHED })
  @Column({ type: 'enum', enum: PostStatus, default: PostStatus.PUBLISHED })
  status: PostStatus;

  @ApiProperty({ example: 142 })
  @Column({ name: 'likes_count', default: 0 })
  likesCount: number;

  @ApiProperty({ example: 7 })
  @Column({ name: 'comments_count', default: 0 })
  commentsCount: number;

  @ApiProperty({ example: 320 })
  @Column({ name: 'views_count', default: 0 })
  viewsCount: number;

  @ApiProperty()
  @CreateDateColumn({ name: 'created_at', type: 'timestamptz' })
  createdAt: Date;

  @ApiProperty()
  @UpdateDateColumn({ name: 'updated_at', type: 'timestamptz' })
  updatedAt: Date;

  @Column({ name: 'author_id' })
  authorId: string;

  @ManyToOne(() => User, (user) => user.posts, { eager: true, onDelete: 'CASCADE' })
  @JoinColumn({ name: 'author_id' })
  author: User;

  @OneToMany(() => Comment, (comment) => comment.post)
  comments: Comment[];

  // CORRECTION TS2339 : relation inverse de PostTranslation.post
  // (requise par `(post) => post.translations` dans post-translation.entity.ts)
  @OneToMany(() => PostTranslation, (translation) => translation.post)
  translations: PostTranslation[];
}