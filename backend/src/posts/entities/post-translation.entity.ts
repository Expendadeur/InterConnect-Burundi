import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  ManyToOne,
  JoinColumn,
  Unique,
} from 'typeorm';
import { Post } from './post.entity';

@Entity('post_translations')
@Unique(['postId', 'targetLanguage'])
export class PostTranslation {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'post_id' })
  postId: string;

  @ManyToOne(() => Post, (post) => post.translations, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'post_id' })
  post: Post;

  @Column({ name: 'target_language', length: 10 })
  targetLanguage: string;

  @Column({ name: 'translated_content', type: 'text' })
  translatedContent: string;

  @Column({ length: 50, nullable: true })
  provider: string;

  @CreateDateColumn({ name: 'created_at' })
  createdAt: Date;
}

