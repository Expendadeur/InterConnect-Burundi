import { Controller, Post, Body, Param, UseGuards } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { CallsService } from './calls.service';
import { CreateCallDto } from './dto/create-call.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CurrentUser } from '../common/decorators/current-user.decorator';

@ApiTags('Calls')
@Controller('calls')
@UseGuards(JwtAuthGuard)
@ApiBearerAuth()
export class CallsController {
  constructor(private readonly callsService: CallsService) {}

  @Post()
  @ApiOperation({ summary: 'Initier un appel (génère la room et l’enregistrement)' })
  async createCall(
    @CurrentUser('id') userId: string,
    @Body() dto: CreateCallDto,
  ) {
    const call = await this.callsService.createCall(userId, dto);
    const token = await this.callsService.generateToken(dto.roomName, userId);
    return { call, token };
  }

  @Post('token/:roomName')
  @ApiOperation({ summary: 'Obtenir un token LiveKit pour rejoindre un salon d’appel' })
  async getToken(
    @Param('roomName') roomName: string,
    @CurrentUser('id') userId: string,
    @CurrentUser('username') username: string,
  ) {
    const token = await this.callsService.generateToken(roomName, userId, username);
    return { token, roomName };
  }

  @Post('end/:roomName')
  @ApiOperation({ summary: 'Terminer un appel' })
  async endCall(@Param('roomName') roomName: string) {
    await this.callsService.endCall(roomName);
    return { status: 'call ended' };
  }
}

