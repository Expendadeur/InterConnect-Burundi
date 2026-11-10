import { Module } from '@nestjs/common';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { TypeOrmModule } from '@nestjs/typeorm';
import { ThrottlerModule } from '@nestjs/throttler';
import { WinstonModule } from 'nest-winston';
import * as winston from 'winston';
import configuration from './config/configuration';
import { AuthModule } from './auth/auth.module';
import { UsersModule } from './users/users.module';
import { PostsModule } from './posts/posts.module';
import { CommentsModule } from './comments/comments.module';
import { MessagingModule } from './messaging/messaging.module';
import { TranslationModule } from './translation/translation.module';
import { CallsModule } from './calls/calls.module';
import { NotificationsModule } from './notifications/notifications.module';
import { User } from './users/entities/user.entity';
import { Post } from './posts/entities/post.entity';
import { PostTranslation } from './posts/entities/post-translation.entity';
import { Comment } from './comments/entities/comment.entity';
import { Reaction } from './comments/entities/reaction.entity';
import { Conversation } from './messaging/entities/conversation.entity';
import { Message } from './messaging/entities/message.entity';
import { Call } from './calls/entities/call.entity';
import { Notification } from './notifications/entities/notification.entity';
import { HealthController } from './health.controller';

@Module({
  imports: [
    // ─── Configuration ───────────────────────────────────────────────────────
    ConfigModule.forRoot({
      isGlobal: true,
      load: [configuration],
      envFilePath: ['.env.local', '.env', '../.env'],
      cache: true,
    }),

    // ─── Winston Logger ───────────────────────────────────────────────────────
    WinstonModule.forRootAsync({
      useFactory: (configService: ConfigService) => ({
        transports: [
          new winston.transports.Console({
            format: winston.format.combine(
              winston.format.timestamp(),
              winston.format.ms(),
              configService.get('nodeEnv') === 'production'
                ? winston.format.json()
                : winston.format.combine(
                    winston.format.colorize({ all: true }),
                    winston.format.printf(({ timestamp, level, message, context, ms }) => {
                      return `${timestamp} [${context ?? 'App'}] ${level}: ${message} ${ms}`;
                    }),
                  ),
            ),
          }),
          ...(configService.get('nodeEnv') === 'production'
            ? [
                new winston.transports.File({
                  filename: 'logs/error.log',
                  level: 'error',
                  format: winston.format.combine(winston.format.timestamp(), winston.format.json()),
                }),
                new winston.transports.File({
                  filename: 'logs/combined.log',
                  format: winston.format.combine(winston.format.timestamp(), winston.format.json()),
                }),
              ]
            : []),
        ],
      }),
      inject: [ConfigService],
    }),

    // ─── Database (TypeORM + PostgreSQL via Supabase) ─────────────────────────
    TypeOrmModule.forRootAsync({
      useFactory: (configService: ConfigService) => ({
        type: 'postgres',
        host: configService.get<string>('database.host'),
        port: configService.get<number>('database.port'),
        username: configService.get<string>('database.user'),
        password: configService.get<string>('database.password'),
        database: configService.get<string>('database.name'),
        entities: [
          User,
          Post,
          PostTranslation,
          Comment,
          Reaction,
          Conversation,
          Message,
          Call,
          Notification,
        ],
        synchronize: configService.get<string>('nodeEnv') !== 'production',
        logging: configService.get<string>('nodeEnv') === 'development',
        ssl: configService.get<boolean>('database.ssl')
          ? { rejectUnauthorized: false }
          : false,
        extra: {
          connectionTimeoutMillis: 10000,
          idleTimeoutMillis: 30000,
          max: 20,
        },
      }),
      inject: [ConfigService],
    }),

    // ─── Rate Limiting ────────────────────────────────────────────────────────
    ThrottlerModule.forRootAsync({
      useFactory: (configService: ConfigService) => [
        {
          ttl: configService.get<number>('throttle.ttl') * 1000,
          limit: configService.get<number>('throttle.limit'),
        },
      ],
      inject: [ConfigService],
    }),

    // ─── Feature Modules ──────────────────────────────────────────────────────
    AuthModule,
    UsersModule,
    PostsModule,
    CommentsModule,
    MessagingModule,
    TranslationModule,
    CallsModule,
    NotificationsModule,
  ],
  controllers: [HealthController],
})
export class AppModule {}
