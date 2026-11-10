import {
  Controller,
  Get,
  Post,
  Body,
  Param,
  UseGuards,
  ParseUUIDPipe,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { MessagingService } from './messaging.service';
import { SendMessageDto } from './dto/send-message.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CurrentUser } from '../common/decorators/current-user.decorator';

@ApiTags('Messaging')
@Controller('messaging')
@UseGuards(JwtAuthGuard)
@ApiBearerAuth()
export class MessagingController {
  constructor(private readonly messagingService: MessagingService) {}

  @Post('conversations')
  @ApiOperation({ summary: 'Créer une conversation directe ou de groupe' })
  async createConversation(
    @CurrentUser('id') userId: string,
    @Body() body: { name?: string; isGroup?: boolean },
  ) {
    return this.messagingService.createConversation(body.name, body.isGroup, userId);
  }

  @Post('messages')
  @ApiOperation({ summary: 'Envoyer un message via API REST (fallback)' })
  async sendMessage(
    @CurrentUser('id') userId: string,
    @Body() dto: SendMessageDto,
  ) {
    return this.messagingService.saveMessage(userId, dto);
  }

  @Get('conversations/:id/messages')
  @ApiOperation({ summary: 'Récupérer l’historique des messages d’une conversation' })
  async getMessages(@Param('id', ParseUUIDPipe) id: string) {
    return this.messagingService.getMessages(id);
  }

  @Post('conversations/:id/read')
  @ApiOperation({ summary: 'Marquer les messages comme lus' })
  async markRead(
    @Param('id', ParseUUIDPipe) id: string,
    @CurrentUser('id') userId: string,
  ) {
    await this.messagingService.markAsRead(id, userId);
    return { status: 'success' };
  }
}

