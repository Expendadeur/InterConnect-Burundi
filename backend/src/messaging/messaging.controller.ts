import {
  Controller,
  Get,
  Post,
  Body,
  Param,
  UseGuards,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { MessagingService } from './messaging.service';
import { SendMessageDto } from './dto/send-message.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { User } from '../users/entities/user.entity';

@ApiTags('Messaging')
@Controller('messaging')
@UseGuards(JwtAuthGuard)
@ApiBearerAuth()
export class MessagingController {
  constructor(private readonly messagingService: MessagingService) {}

  @Get('conversations')
  @ApiOperation({ summary: 'Lister les conversations de l’utilisateur' })
  async getConversations(@CurrentUser() user: User) {
    return this.messagingService.findAllConversations(user?.id);
  }

  @Post('conversations')
  @ApiOperation({ summary: 'Créer une conversation directe ou de groupe' })
  async createConversation(
    @CurrentUser() user: User,
    @Body() body: { name?: string; isGroup?: boolean },
  ) {
    return this.messagingService.createConversation(body.name, body.isGroup, user?.id);
  }

  @Post('messages')
  @ApiOperation({ summary: 'Envoyer un message via API REST (fallback)' })
  async sendMessage(
    @CurrentUser() user: User,
    @Body() dto: SendMessageDto,
  ) {
    return this.messagingService.saveMessage(user?.id, dto);
  }

  @Get('conversations/:id/messages')
  @ApiOperation({ summary: 'Récupérer l’historique des messages d’une conversation' })
  async getMessages(
    @Param('id') id: string,
    @CurrentUser() user: User,
  ) {
    return this.messagingService.getMessages(id, user?.id);
  }

  @Post('conversations/:id/read')
  @ApiOperation({ summary: 'Marquer les messages comme lus' })
  async markRead(
    @Param('id') id: string,
    @CurrentUser() user: User,
  ) {
    await this.messagingService.markAsRead(id, user?.id);
    return { status: 'success' };
  }
}

