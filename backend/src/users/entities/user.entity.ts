import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
  OneToMany,
  BeforeInsert,
  BeforeUpdate,
} from 'typeorm';
import * as bcrypt from 'bcrypt';
import { Exclude } from 'class-transformer';
import { ApiProperty, ApiHideProperty } from '@nestjs/swagger';
import { Post } from '../../posts/entities/post.entity';
import { Comment } from '../../comments/entities/comment.entity';

export enum UserRole {
  USER = 'user',
  ADMIN = 'admin',
  MODERATOR = 'moderator',
}

export enum UserStatus {
  ACTIVE = 'active',
  SUSPENDED = 'suspended',
  PENDING = 'pending',
}

@Entity('users')
export class User {
  @ApiProperty({ example: 'uuid-v4', description: 'Identifiant unique UUID' })
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @ApiProperty({ example: 'john.doe@example.com' })
  @Column({ unique: true, length: 255 })
  email: string;

  @ApiProperty({ example: 'johndoe' })
  @Column({ unique: true, length: 50 })
  username: string;

  @ApiHideProperty()
  @Exclude()
  @Column({ name: 'password_hash', length: 255 })
  passwordHash: string;

  @ApiProperty({ example: 'John' })
  @Column({ name: 'first_name', length: 100, nullable: true })
  firstName: string;

  @ApiProperty({ example: 'Doe' })
  @Column({ name: 'last_name', length: 100, nullable: true })
  lastName: string;

  @ApiProperty({ example: 'https://cdn.example.com/avatar.jpg' })
  @Column({ name: 'avatar_url', nullable: true })
  avatarUrl: string;

  @ApiProperty({ example: 'Développeur passionné basé à Bujumbura.' })
  @Column({ type: 'text', nullable: true })
  bio: string;

  @ApiProperty({ example: '+25761234567', required: false })
  @Column({ nullable: true, length: 20 })
  phone: string;

  @ApiProperty({ example: 'CNI-BI-123456789', required: false })
  @Column({ name: 'national_id', nullable: true, length: 50 })
  nationalId: string;

  @ApiProperty({ example: 'Burundi', required: false })
  @Column({ nullable: true, length: 100 })
  country: string;

  @ApiProperty({ enum: UserRole, example: UserRole.USER })
  @Column({ type: 'enum', enum: UserRole, default: UserRole.USER })
  role: UserRole;

  @ApiProperty({ enum: UserStatus, example: UserStatus.ACTIVE })
  @Column({ type: 'enum', enum: UserStatus, default: UserStatus.PENDING })
  status: UserStatus;

  @ApiProperty({ example: 'fr' })
  @Column({ name: 'preferred_language', length: 10, default: 'fr' })
  preferredLanguage: string;

  @ApiHideProperty()
  @Exclude()
  @Column({ name: 'refresh_token_hash', nullable: true })
  refreshTokenHash: string;

  @ApiHideProperty()
  @Exclude()
  @Column({ name: 'fcm_token', nullable: true })
  fcmToken: string;

  @ApiProperty()
  @Column({ name: 'is_online', default: false })
  isOnline: boolean;

  @ApiProperty()
  @Column({ name: 'last_seen_at', type: 'timestamptz', nullable: true })
  lastSeenAt: Date;

  @ApiProperty()
  @CreateDateColumn({ name: 'created_at', type: 'timestamptz' })
  createdAt: Date;

  @ApiProperty()
  @UpdateDateColumn({ name: 'updated_at', type: 'timestamptz' })
  updatedAt: Date;

  // ─── Relations ──────────────────────────────────────────────────────────────
  @OneToMany(() => Post, (post) => post.author)
  posts: Post[];

  @OneToMany(() => Comment, (comment) => comment.author)
  comments: Comment[];

  // ─── Hooks ──────────────────────────────────────────────────────────────────
  @BeforeInsert()
  @BeforeUpdate()
  async hashPassword() {
    if (this.passwordHash && !this.passwordHash.startsWith('$2b$')) {
      this.passwordHash = await bcrypt.hash(this.passwordHash, 12);
    }
  }

  async validatePassword(plainPassword: string): Promise<boolean> {
    return bcrypt.compare(plainPassword, this.passwordHash);
  }

  get fullName(): string {
    return [this.firstName, this.lastName].filter(Boolean).join(' ');
  }
}
