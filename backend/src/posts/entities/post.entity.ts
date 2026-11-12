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
import { PostTranslation } from './post-translation.entity';

export enum PostType {
  TEXT = 'text',
  PHOTO = 'photo',
  VIDEO = 'video',
  AUDIO = 'audio',
}

export enum PostVisibility {
  PUBLIC = 'public',
  FRIENDS = 'friends',
  PRIVATE = 'private',
}

@Entity('posts')
export class Post {
  @ApiProperty({ example: 'uuid-v4' })
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @ApiProperty({ example: 'author-uuid' })
  @Column({ name: 'author_id' })
  authorId: string;

  @ManyToOne(() => User, (user) => user.posts, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'author_id' })
  author: User;

  @ApiProperty({ example: 'Muraho Burundi! Une belle journée commence.' })
  @Column({ type: 'text', nullable: true })
  content: string;

  @ApiProperty({ example: 'rn' })
  @Column({ name: 'original_language', length: 10, default: 'fr' })
  originalLanguage: string;

  @ApiProperty({ example: ['https://storage.interconnect.bi/posts/img1.jpg'] })
  @Column({ name: 'media_urls', type: 'jsonb', default: () => "'[]'" })
  mediaUrls: string[];

  @ApiProperty({ enum: PostType, default: PostType.TEXT })
  @Column({ name: 'post_type', length: 20, default: PostType.TEXT })
  postType: PostType;

  @ApiProperty({ enum: PostVisibility, default: PostVisibility.PUBLIC })
  @Column({ length: 20, default: PostVisibility.PUBLIC })
  visibility: PostVisibility;

  @ApiProperty({ example: 42 })
  @Column({ name: 'likes_count', default: 0 })
  likesCount: number;

  @ApiProperty({ example: 150 })
  @Column({ name: 'views_count', default: 0 })
  viewsCount: number;

  @ApiProperty({ example: 5 })
  @Column({ name: 'comments_count', default: 0 })
  commentsCount: number;

  @ApiProperty({ example: 2 })
  @Column({ name: 'shares_count', default: 0 })
  sharesCount: number;

  @OneToMany(() => Comment, (comment) => comment.post)
  comments: Comment[];

  @OneToMany(() => PostTranslation, (translation) => translation.post)
  translations: PostTranslation[];

  @CreateDateColumn({ name: 'created_at' })
  createdAt: Date;

  @UpdateDateColumn({ name: 'updated_at' })
  updatedAt: Date;
}

