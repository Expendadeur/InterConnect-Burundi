import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import * as admin from 'firebase-admin';
import { Notification } from './entities/notification.entity';
import { User } from '../users/entities/user.entity';

@Injectable()
export class NotificationsService {
  private readonly logger = new Logger(NotificationsService.name);
  private firebaseInitialized = false;

  constructor(
    @InjectRepository(Notification)
    private readonly notificationRepo: Repository<Notification>,
    @InjectRepository(User)
    private readonly userRepo: Repository<User>,
    private readonly configService: ConfigService,
  ) {
    this.initFirebase();
  }

  private initFirebase() {
    const projectId = this.configService.get<string>('firebase.projectId');
    const clientEmail = this.configService.get<string>('firebase.clientEmail');
    const privateKey = this.configService.get<string>('firebase.privateKey');

    if (projectId && clientEmail && privateKey) {
      try {
        admin.initializeApp({
          credential: admin.credential.cert({
            projectId,
            clientEmail,
            privateKey: privateKey.replace(/\\n/g, '\n'),
          }),
        });
        this.firebaseInitialized = true;
        this.logger.log('Firebase Admin initialisé avec succès pour les notifications push');
      } catch (err) {
        this.logger.warn(`Erreur lors de l'initialisation de Firebase: ${err.message}`);
      }
    } else {
      this.logger.warn('Identifiants Firebase non définis dans .env — push désactivé en dev');
    }
  }

  async createNotification(
    userId: string,
    notificationType: string,
    content: string,
    actorId?: string,
    entityType?: string,
    entityId?: string,
  ): Promise<Notification> {
    const notif = this.notificationRepo.create({
      userId,
      actorId,
      notificationType,
      content,
      entityType,
      entityId,
    });
    const saved = await this.notificationRepo.save(notif);

    // Envoi push si token FCM disponible
    if (this.firebaseInitialized) {
      const recipient = await this.userRepo.findOne({ where: { id: userId } });
      if (recipient?.fcmToken) {
        try {
          await admin.messaging().send({
            token: recipient.fcmToken,
            notification: {
              title: 'InterConnect Burundi',
              body: content,
            },
            data: {
              type: notificationType,
              entityId: entityId || '',
            },
          });
        } catch (e) {
          this.logger.warn(`Échec envoi FCM: ${e.message}`);
        }
      }
    }

    return saved;
  }

  async getUserNotifications(userId: string): Promise<Notification[]> {
    return this.notificationRepo.find({
      where: { userId },
      relations: ['actor'],
      order: { createdAt: 'DESC' },
      take: 50,
    });
  }

  async markAllAsRead(userId: string): Promise<void> {
    await this.notificationRepo.update({ userId, isRead: false }, { isRead: true });
  }
}

